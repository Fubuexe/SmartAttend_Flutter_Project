import 'dart:async';
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

enum _AttendanceMode { photo, video }

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
  bool _initialized = false;

  _AttendanceMode _mode = _AttendanceMode.photo;

  FrameStats _stats =
      FrameStats(detected: 0, focused: 0, distracted: 0, avgFocus: 0);
  List<StudentModel> _enrolled = [];
  ClassModel? _class;

  // ── Video mode state ────────────────────────────────────────────────────────
  /// Students confirmed detected during this video session.
  final Map<String, AttendanceRecord> _videoMatched = {};
  Timer? _recognitionTimer;
  bool _videoRunning = false;
  int _framesSinceLastRecognition = 0;
  static const int _recognitionFrameInterval = 90; // ~3 s at 30 fps

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
              const SnackBar(content: Text('No cameras available')));
        }
        return;
      }
      _camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);

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
            SnackBar(content: Text('Camera init failed: $e')));
      }
    }
  }

  // ── Frame handler ───────────────────────────────────────────────────────────

  Future<void> _onFrame(CameraImage image) async {
    if (_busy) return;
    _busy = true;
    try {
      final input = FaceDetectionService.inputImageFromCamera(
          image, _controller!, _camera!);
      if (input == null) return;

      final faces = await _detector.detectFromInputImage(input);
      final stats = FocusService.analyzeFrame(faces);
      if (mounted) setState(() => _stats = stats);

      // Video mode: run recognition every N frames.
      if (_mode == _AttendanceMode.video && _videoRunning && !_capturing) {
        _framesSinceLastRecognition++;
        if (_framesSinceLastRecognition >= _recognitionFrameInterval) {
          _framesSinceLastRecognition = 0;
          await _recognizeFromFrame(image, faces);
        }
      }
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  /// Run face recognition on a live frame and update the matched-student map.
  Future<void> _recognizeFromFrame(
      CameraImage image, List<Face> faces) async {
    if (faces.isEmpty || _enrolled.isEmpty) return;
    try {
      // Build an img.Image from the camera frame bytes.
      final plane = image.planes.first;
      final rawBytes = plane.bytes;
      img.Image? decoded;
      if (Platform.isAndroid) {
        decoded = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: rawBytes.buffer,
          format: img.Format.uint8,
          numChannels: 1,
        );
      } else {
        decoded = img.decodeImage(rawBytes);
      }
      if (decoded == null) return;
      final oriented = img.bakeOrientation(decoded);

      for (final face in faces) {
        final focus = FocusService.scoreForFace(face);
        final emb = _recognizer.embedding(oriented, face.boundingBox);
        final match = _recognizer.identify(emb, _enrolled);
        if (match != null && !_videoMatched.containsKey(match.id)) {
          final rec = AttendanceRecord(
            studentId: match.id,
            studentName: match.name,
            present: true,
            focusScore: focus,
            state: FocusService.stateFromScore(focus),
          );
          if (mounted) {
            setState(() => _videoMatched[match.id] = rec);
          }
        }
      }
    } catch (_) {}
  }

  // ── Photo mode ──────────────────────────────────────────────────────────────

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
      final oriented = decoded != null ? img.bakeOrientation(decoded) : null;

      List<Face> faces =
          await detector.processImage(InputImage.fromFile(file));
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

      final session = _buildSession(faces, oriented);
      await _fs.saveSession(session);
      if (!mounted) return;
      navigated = true;
      Navigator.pushReplacementNamed(context, Routes.attendanceResult,
          arguments: session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Capture failed: $e')));
        setState(() => _capturing = false);
      }
    } finally {
      if (!navigated && mounted && _controller != null) {
        try {
          _controller!.startImageStream(_onFrame);
        } catch (_) {}
      }
    }
  }

  // ── Video mode ──────────────────────────────────────────────────────────────

  void _startVideoSession() {
    setState(() {
      _videoMatched.clear();
      _videoRunning = true;
      _framesSinceLastRecognition = 0;
    });
  }

  Future<void> _endVideoSession() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final session = _buildSessionFromVideoMatched();
      await _fs.saveSession(session);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.attendanceResult,
          arguments: session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: $e')));
        setState(() => _capturing = false);
      }
    }
  }

  // ── Session builders ────────────────────────────────────────────────────────

  AttendanceSession _buildSession(List<Face> faces, img.Image? oriented) {
    final records = <AttendanceRecord>[];
    final matched = <String, AttendanceRecord>{};
    double focusTotal = 0;

    for (final face in faces) {
      final focus = FocusService.scoreForFace(face);
      focusTotal += focus;
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
    }
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
    final avgFocus = faces.isEmpty ? 0.0 : focusTotal / faces.length;
    return AttendanceSession(
      id: '',
      classId: _class!.id,
      date: DateTime.now(),
      totalStudents: _enrolled.isEmpty ? faces.length : _enrolled.length,
      presentCount: _enrolled.isEmpty ? faces.length : matched.length,
      avgFocus: avgFocus,
      records: records,
    );
  }

  AttendanceSession _buildSessionFromVideoMatched() {
    final records = <AttendanceRecord>[..._videoMatched.values];
    final matchedIds = _videoMatched.keys.toSet();
    for (final s in _enrolled) {
      if (!matchedIds.contains(s.id)) {
        records.add(AttendanceRecord(
          studentId: s.id,
          studentName: s.name,
          present: false,
          focusScore: 0,
          state: FocusState.absent,
        ));
      }
    }
    final focusValues =
        _videoMatched.values.map((r) => r.focusScore).toList();
    final avgFocus = focusValues.isEmpty
        ? 0.0
        : focusValues.reduce((a, b) => a + b) / focusValues.length;
    return AttendanceSession(
      id: '',
      classId: _class!.id,
      date: DateTime.now(),
      totalStudents: _enrolled.isEmpty ? _videoMatched.length : _enrolled.length,
      presentCount: _videoMatched.length,
      avgFocus: avgFocus,
      records: records,
    );
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _recognitionTimer?.cancel();
    _controller?.dispose();
    _detector.dispose();
    _recognizer.dispose();
    super.dispose();
  }

  void _switchMode(_AttendanceMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _videoRunning = false;
      _videoMatched.clear();
      _capturing = false;
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_ready && _controller != null && _controller!.value.isInitialized)
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
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Initializing camera…',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

          // Top bar: back + class name + mode toggle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const BackButton(color: Colors.white),
                      Expanded(
                        child: Text(
                          _class?.name ?? 'Class',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Mode toggle
                  Center(child: _ModeToggle(mode: _mode, onChanged: _switchMode)),
                ],
              ),
            ),
          ),

          // Live stats banner
          Positioned(
            top: 130,
            left: 16,
            right: 16,
            child: _StatsBar(stats: _stats),
          ),

          // ── Bottom controls ────────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: _mode == _AttendanceMode.photo
                ? _PhotoControls(
                    ready: _ready,
                    capturing: _capturing,
                    onCapture: _captureAndMark,
                  )
                : _VideoControls(
                    ready: _ready,
                    capturing: _capturing,
                    running: _videoRunning,
                    matched: _videoMatched,
                    enrolled: _enrolled,
                    onStart: _startVideoSession,
                    onEnd: _endVideoSession,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Mode toggle ────────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final _AttendanceMode mode;
  final ValueChanged<_AttendanceMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.photo_camera_outlined,
            label: 'Photo',
            selected: mode == _AttendanceMode.photo,
            onTap: () => onChanged(_AttendanceMode.photo),
          ),
          const SizedBox(width: 4),
          _ToggleBtn(
            icon: Icons.videocam_outlined,
            label: 'Video',
            selected: mode == _AttendanceMode.video,
            onTap: () => onChanged(_AttendanceMode.video),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Photo mode controls ────────────────────────────────────────────────────────

class _PhotoControls extends StatelessWidget {
  final bool ready;
  final bool capturing;
  final VoidCallback onCapture;
  const _PhotoControls(
      {required this.ready, required this.capturing, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: !ready || capturing ? null : onCapture,
      child: capturing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera, color: Colors.white),
                SizedBox(width: 8),
                Text('Capture & Mark Attendance',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
    );
  }
}

// ── Video mode controls ────────────────────────────────────────────────────────

class _VideoControls extends StatelessWidget {
  final bool ready;
  final bool capturing;
  final bool running;
  final Map<String, AttendanceRecord> matched;
  final List<StudentModel> enrolled;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const _VideoControls({
    required this.ready,
    required this.capturing,
    required this.running,
    required this.matched,
    required this.enrolled,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live detected student list
        if (running && matched.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${matched.length} / ${enrolled.length} detected',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...matched.values.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(r.studentName,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                          Text(
                              'Focus ${(r.focusScore * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    )),
              ],
            ),
          ),

        // Start / End button
        if (!running)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: !ready ? null : onStart,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, color: Colors.white),
                SizedBox(width: 8),
                Text('Start Video Attendance',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: capturing ? Colors.grey : Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: capturing ? null : onEnd,
            child: capturing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop_circle_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text('End & Save Session',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
          ),
      ],
    );
  }
}

// ── Stats bar ──────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final FrameStats stats;
  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Detected', value: stats.detected.toString()),
          _StatItem(label: 'Focused', value: stats.focused.toString()),
          _StatItem(label: 'Distracted', value: stats.distracted.toString()),
          _StatItem(
              label: 'Avg Focus',
              value: stats.avgFocus.toStringAsFixed(2)),
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
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
