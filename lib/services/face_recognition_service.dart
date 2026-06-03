import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Rect;
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/student_model.dart';

/// Pixel-based face recognition using Normalized Cross-Correlation (NCC).
///
/// Each embedding is a 48×48 = 2304-value normalised grayscale face crop.
/// NCC handles uniform brightness / contrast shifts between an enrollment
/// selfie and a classroom photo.
///
/// Matching strategy (two-pass):
///   1. Compare the probe against the stored embedding array (fast).
///   2. If score < threshold, also compare against the stored 150×150
///      base64 photo thumbnail (catches students enrolled before the
///      embedding code was in place, or re-enrolled with a different crop).
class FaceRecognitionService {
  static const int faceSize = 48;
  static const int embeddingSize = faceSize * faceSize; // 2304
  /// NCC threshold — lowered to 0.28 to handle lighting / distance variation
  /// between a close-up enrollment selfie and a classroom attendance photo.
  /// Using 0.28 instead of 0.40 because pixel NCC degrades significantly when
  /// the same face appears at very different scales/distances between enrollment
  /// and attendance capture.
  static const double matchThreshold = 0.28;

  bool get isReady => true;
  Future<void> load() async {}
  void dispose() {}

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Extract a normalised pixel vector from [box] in [source].
  /// [source] MUST have EXIF orientation already baked in.
  List<double> embedding(img.Image source, Rect box) {
    final padded = _paddedBox(box, source.width, source.height);
    final crop = img.copyCrop(
      source,
      x: padded.left.toInt(),
      y: padded.top.toInt(),
      width: padded.width.toInt().clamp(1, source.width),
      height: padded.height.toInt().clamp(1, source.height),
    );
    return _toVector(crop);
  }

  /// Return the enrolled student whose face best matches [probe],
  /// or null if nothing exceeds [matchThreshold].
  ///
  /// Three-pass: NCC on stored embedding → cosine on stored embedding →
  /// NCC on stored photo thumbnail. Using both NCC and cosine covers the
  /// brightness-shift vs. direction-shift cases that neither metric alone handles.
  StudentModel? identify(List<double> probe, List<StudentModel> enrolled) {
    if (probe.isEmpty) return null;

    double best = matchThreshold;
    StudentModel? match;

    for (final s in enrolled) {
      double score = 0;

      // Pass 1 — NCC on stored embedding.
      if (s.embedding.length == embeddingSize) {
        score = _ncc(probe, s.embedding);
      }

      // Pass 2 — cosine on stored embedding (catches direction-shift cases
      // that NCC misses when mean-centering removes the useful signal).
      if (score < matchThreshold && s.embedding.length == embeddingSize) {
        score = max(score, cosine(probe, s.embedding));
      }

      // Pass 3 — decode stored photo thumbnail as fallback.
      if (score < matchThreshold &&
          s.photoUrl != null &&
          s.photoUrl!.isNotEmpty) {
        try {
          final decoded = img.decodeImage(base64Decode(s.photoUrl!));
          if (decoded != null) {
            final thumbVec = _toVector(decoded);
            score = max(score, _ncc(probe, thumbVec));
            score = max(score, cosine(probe, thumbVec));
          }
        } catch (_) {}
      }

      if (score > best) {
        best = score;
        match = s;
      }
    }
    return match;
  }

  /// Detect face in [file], extract its pixel embedding, return it.
  /// Returns null if no face is detected.
  Future<List<double>?> embeddingFromFile(File file) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final oriented = img.bakeOrientation(decoded);

      List<Face> faces =
          await detector.processImage(InputImage.fromFile(file));

      if (faces.isEmpty) {
        final reencoded = img.encodeJpg(oriented, quality: 90);
        final tmpPath = '${file.parent.path}/_embed_oriented.jpg';
        final tmpFile = File(tmpPath);
        await tmpFile.writeAsBytes(reencoded);
        try {
          faces =
              await detector.processImage(InputImage.fromFile(tmpFile));
        } finally {
          await tmpFile.delete().catchError((e) => tmpFile);
        }
      }

      if (faces.isEmpty) return null;
      return embedding(oriented, faces.first.boundingBox);
    } finally {
      await detector.close();
    }
  }

  static double cosine(List<double> a, List<double> b) {
    double dot = 0, nA = 0, nB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      nA += a[i] * a[i];
      nB += b[i] * b[i];
    }
    if (nA == 0 || nB == 0) return 0;
    return dot / sqrt(nA * nB);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Rect _paddedBox(Rect box, int imgW, int imgH) {
    final px = box.width * 0.25;
    final py = box.height * 0.25;
    final l = (box.left - px).clamp(0.0, imgW.toDouble() - 1);
    final t = (box.top - py).clamp(0.0, imgH.toDouble() - 1);
    final r = (box.right + px).clamp(l + 1, imgW.toDouble());
    final b = (box.bottom + py).clamp(t + 1, imgH.toDouble());
    return Rect.fromLTRB(l, t, r, b);
  }

  static List<double> _toVector(img.Image source) {
    final gray = img.grayscale(source);
    final resized = img.copyResize(gray, width: faceSize, height: faceSize);
    final out = List<double>.filled(embeddingSize, 0);
    for (int y = 0; y < faceSize; y++) {
      for (int x = 0; x < faceSize; x++) {
        out[y * faceSize + x] = resized.getPixel(x, y).r / 255.0;
      }
    }
    return out;
  }

  /// Normalized Cross-Correlation — robust to uniform brightness/contrast shifts.
  static double _ncc(List<double> a, List<double> b) {
    final n = a.length;
    if (n == 0 || n != b.length) return 0;
    double sA = 0, sB = 0;
    for (int i = 0; i < n; i++) {
      sA += a[i];
      sB += b[i];
    }
    final mA = sA / n;
    final mB = sB / n;
    double num = 0, dA = 0, dB = 0;
    for (int i = 0; i < n; i++) {
      final da = a[i] - mA;
      final db = b[i] - mB;
      num += da * db;
      dA += da * da;
      dB += db * db;
    }
    if (dA < 1e-10 || dB < 1e-10) return 0;
    return num / sqrt(dA * dB);
  }
}
