import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../services/firestore_service.dart';
import '../../services/face_recognition_service.dart';
import '../../widgets/common.dart';

/// Enroll a student: capture a face photo -> MobileFaceNet embedding ->
/// store name + reg number + embedding in Firestore for later recognition.
class EnrollStudentScreen extends StatefulWidget {
  const EnrollStudentScreen({super.key});
  @override
  State<EnrollStudentScreen> createState() => _EnrollStudentScreenState();
}

class _EnrollStudentScreenState extends State<EnrollStudentScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _reg = TextEditingController();
  File? _photo;
  bool _saving = false;

  Future<void> _pick(ImageSource src) async {
    final picked = await ImagePicker()
        .pickImage(source: src, maxWidth: 720, imageQuality: 90);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save(ClassModel cls) async {
    if (!_form.currentState!.validate()) return;
    if (_photo == null) {
      _snack('Please capture a face photo for recognition');
      return;
    }
    setState(() => _saving = true);
    try {
      // ── Step 1: read & decode the photo ──────────────────────────────
      final rawBytes = await _photo!.readAsBytes();
      final decoded = img.decodeImage(rawBytes);

      // ── Step 2: bake EXIF orientation once (used by all remaining steps) ─
      final oriented = decoded != null ? img.bakeOrientation(decoded) : null;

      // ── Step 3: detect face (ML Kit + EXIF fallback) ──────────────────
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
      );
      List<Face> detectedFaces = [];
      try {
        detectedFaces =
            await faceDetector.processImage(InputImage.fromFile(_photo!));

        if (detectedFaces.isEmpty && oriented != null) {
          final reencoded = img.encodeJpg(oriented, quality: 90);
          final tmpPath = '${_photo!.parent.path}/_enroll_oriented.jpg';
          final tmpFile = File(tmpPath);
          await tmpFile.writeAsBytes(reencoded);
          try {
            detectedFaces =
                await faceDetector.processImage(InputImage.fromFile(tmpFile));
          } finally {
            await tmpFile.delete().catchError((e) => tmpFile);
          }
        }
      } finally {
        await faceDetector.close();
      }

      if (detectedFaces.isEmpty) {
        _snack('No face detected — retake the photo in good lighting');
        setState(() => _saving = false);
        return;
      }

      // ── Step 4: generate pixel embedding for recognition ──────────────
      List<double> embeddingVec = const [];
      if (oriented != null) {
        try {
          embeddingVec = FaceRecognitionService()
              .embedding(oriented, detectedFaces.first.boundingBox);
        } catch (e) {
          debugPrint('Embedding generation failed: $e');
        }
      }

      // ── Step 5: encode face thumbnail as base64 (display photo) ───────
      String? photoData;
      try {
        if (oriented != null) {
          final box = detectedFaces.first.boundingBox;
          final pad = box.width * 0.3;
          final faceImg = img.copyCrop(
            oriented,
            x: (box.left - pad).clamp(0, oriented.width - 1).toInt(),
            y: (box.top - pad).clamp(0, oriented.height - 1).toInt(),
            width: (box.width + pad * 2)
                .clamp(1, oriented.width.toDouble())
                .toInt(),
            height: (box.height + pad * 2)
                .clamp(1, oriented.height.toDouble())
                .toInt(),
          );
          final thumb = img.copyResize(faceImg, width: 150, height: 150);
          photoData = base64Encode(img.encodeJpg(thumb, quality: 85));
        }
      } catch (e) {
        debugPrint('Thumbnail encoding failed: $e');
      }

      await FirestoreService().addStudent(StudentModel(
        id: '',
        classId: cls.id,
        name: _name.text.trim(),
        registrationNumber: _reg.text.trim(),
        photoUrl: photoData,
        embedding: embeddingVec,
      ));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _snack('Failed: $e');
      setState(() => _saving = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cls = ModalRoute.of(context)!.settings.arguments as ClassModel;
    return Scaffold(
      appBar:
          AppBar(leading: const BackButton(), title: const Text('Enroll Student')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _pick(ImageSource.camera),
                    child: Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        image: _photo != null
                            ? DecorationImage(
                                image: FileImage(_photo!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _photo == null
                          ? const Icon(Icons.add_a_photo_outlined,
                              size: 40, color: AppColors.primary)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Choose from gallery'),
                ),
                const SizedBox(height: 16),
                AppField(
                  label: 'Student Name',
                  hint: 'Sara Ali',
                  icon: Icons.person_outline,
                  controller: _name,
                  validator: (v) => Validators.notEmpty(v, 'Name'),
                ),
                AppField(
                  label: 'Registration Number',
                  hint: '21-12345',
                  icon: Icons.badge_outlined,
                  controller: _reg,
                  validator: (v) => Validators.notEmpty(v, 'Reg number'),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Enroll Student',
                  loading: _saving,
                  onPressed: () => _save(cls),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
