import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance.dart';
import '../../services/face_detection_service.dart';
import '../../services/face_recognition_service.dart';
import '../../services/focus_service.dart';
import '../../services/firestore_service.dart';

/// Live classroom scan:
///   • ML Kit detects all faces every frame -> live focus overlay
///   • "Capture & Mark" recognises enrolled students (MobileFaceNet) and
///     records each one's present/focus state, then saves the session.
class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});
  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  CameraController? _controller;
  CameraDescription? _camera;
  final _detector = FaceDetectionService();
  final _recognizer = FaceRecognitionService();
  final _fs = FirestoreService();

  bool _busy = false;
  bool _capturing = false;
  bool _ready = false;
  FrameStats _stats =
      FrameStats(detected: 0, focused: 0, distracted: 0, avgFocus: 0);
  List<StudentModel> _enrolled = [];
  ClassModel? _class;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ClassModel && _class != args) {
      _class = args;
      if (!_initialized) {
        _initialized = true;
        _init();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Don't call _init() here - wait for didChangeDependencies to get _class
  }

  Future<void> _init() async {
    if (_class == null) return;
    
    try {
      await _recognizer.load();
    } catch (_) {}
    
    _enrolled = await _fs.classStudentsOnce(_class!.id);
    
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
        return;
      }

      // Use the rear camera — teacher points it at the students.
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        _camera!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;
      
      setState(() => _ready = true);
      _controller!.startImageStream(_onFrame);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera init failed: $e')),
        );
      }
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _capturing) return;
    _busy = true;
    try {
      final input = FaceDetectionService.inputImageFromCamera(
          image, _controller!, _camera!);
      if (input != null) {
        final faces = await _detector.detectFromInputImage(input);
        final stats = FocusService.analyzeFrame(faces);
        if (mounted) {
          setState(() => _stats = stats);
        }
      }
    } catch (e) {
      // Silently skip frames with errors
    } finally {
      _busy = false;
    }
  }

  /// Take a still, recognise enrolled students, save the session.
  Future<void> _captureAndMark() async {
    if (_controller == null || _capturing || !_ready) return;

    setState(() => _capturing = true);
    bool navigated = false;
    try {
      await _controller!.stopImageStream();
      final shot = await _controller!.takePicture();
      final file = File(shot.path);

      final detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.05,
        ),
      );

      final rawBytes = await file.readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      // Always work in display orientation — ML Kit bounding boxes are
      // in oriented space, so the image we crop from must match.
      final oriented = decoded != null ? img.bakeOrientation(decoded) : null;

      // First attempt: direct file (ML Kit handles EXIF internally).
      List<Face> faces = await detector.processImage(InputImage.fromFile(file));

      // Second attempt: write physically-rotated pixels for stubborn cases.
      if (faces.isEmpty && oriented != null) {
        final reencoded = img.encodeJpg(oriented, quality: 90);
        final tmpPath = '${file.parent.path}/_attend_oriented.jpg';
        final tmpFile = File(tmpPath);
        await tmpFile.writeAsBytes(reencoded);
        try {
          faces = await detector.processImage(InputImage.fromFile(tmpFile));
        } finally {
          await tmpFile.delete().catchError((e) => tmpFile);
        }
      }

      await detector.close();

      final records = <AttendanceRecord>[];
      final matched = <String, AttendanceRecord>{};
      double focusTotal = 0;
      int n = 0;

      for (final face in faces) {
        final focus = FocusService.scoreForFace(face);
        focusTotal += focus;
        n++;

        // Only match against enrolled students — never create "Student N" entries.
        if (_recognizer.isReady && oriented != null && _enrolled.isNotEmpty) {
          final emb = _recognizer.embedding(oriented, face.boundingBox);
          final match = _recognizer.identify(emb, _enrolled);
          if (match != null && !matched.containsKey(match.id)) {
            final rec = AttendanceRecord(
              studentId: match.id,
              studentName: match.name,
              present: true,
              focusScore: focus,
              state: FocusService.stateFromScore(focus),
            );
            records.add(rec);
            matched[match.id] = rec;
          }
        }
        // Unknown faces: counted in stats but not listed.
      }

      // Mark every enrolled student who wasn't matched as absent.
      if (_enrolled.isNotEmpty) {
        for (final s in _enrolled) {
          if (!matched.containsKey(s.id)) {
            records.add(AttendanceRecord(
              studentId: s.id,
              studentName: s.name,
              present: false,
              focusScore: 0,
              state: FocusState.absent,
            ));
          }
        }
      }

      final avgFocus = faces.isEmpty ? 0.0 : focusTotal / faces.length;
      final presentCount = records.where((r) => r.present).length;
      final session = AttendanceSession(
        id: '',
        classId: _class!.id,
        date: DateTime.now(),
        totalStudents: _enrolled.isEmpty ? n : _enrolled.length,
        presentCount: _enrolled.isEmpty ? n : presentCount,
        avgFocus: avgFocus,
        records: records,
      );
      await _fs.saveSession(session);

      if (!mounted) return;
      navigated = true;
      Navigator.pushReplacementNamed(context, Routes.attendanceResult,
          arguments: session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
        setState(() => _capturing = false);
      }
    } finally {
      // Only restart the stream if we didn't navigate away (error path / retry).
      if (!navigated && mounted && _controller != null) {
        try {
          _controller!.startImageStream(_onFrame);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.dispose();
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview with proper aspect ratio scaling
          if (_ready &&
              _controller != null &&
              _controller!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Top navigation bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const BackButton(color: Colors.white),
                  Expanded(
                    child: Text(
                      _class?.name ?? 'Class',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live focus statistics banner
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: _StatsBar(stats: _stats),
          ),

          // Capture button
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, // Fixed: use primaryColor from AppTheme
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: !_ready || _capturing ? null : _captureAndMark,
              child: _capturing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Tap to Capture & Mark Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Statistics Monitoring Horizontal UI component layout banner 
class _StatsBar extends StatelessWidget {
  final FrameStats stats;
  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Detected', value: stats.detected.toString()),
          _StatItem(label: 'Focused', value: stats.focused.toString()),
          _StatItem(label: 'Distracted', value: stats.distracted.toString()),
          _StatItem(label: 'Avg Focus', value: stats.avgFocus.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}