import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/attendance.dart';

/// Turns ML Kit face geometry into a real engagement / focus score.
///
/// A student is considered FOCUSED when they are facing the camera
/// (small head yaw/pitch) with eyes open. Looking away or closed eyes
/// lowers the score toward DISTRACTED.
class FocusService {
  /// Returns a 0..1 focus score for a single detected face.
  static double scoreForFace(Face face) {
    // 1. Head orientation — how far from facing forward (degrees).
    final yaw = (face.headEulerAngleY ?? 0).abs();   // turning left/right
    final pitch = (face.headEulerAngleX ?? 0).abs(); // looking up/down

    // Map 0deg -> 1.0, 35deg+ -> 0.0
    double yawScore = (1 - (yaw / 35.0)).clamp(0.0, 1.0);
    double pitchScore = (1 - (pitch / 30.0)).clamp(0.0, 1.0);

    // 2. Eyes open (sleeping / looking down detection).
    final left = face.leftEyeOpenProbability ?? 1.0;
    final right = face.rightEyeOpenProbability ?? 1.0;
    final eyeScore = ((left + right) / 2).clamp(0.0, 1.0);

    // Weighted blend — orientation matters most for "paying attention".
    final score = (yawScore * 0.45) + (pitchScore * 0.25) + (eyeScore * 0.30);
    return score.clamp(0.0, 1.0);
  }

  static FocusState stateFromScore(double score) {
    if (score >= 0.6) return FocusState.focused;
    return FocusState.distracted;
  }

  /// Aggregate live stats for the whole frame.
  static FrameStats analyzeFrame(List<Face> faces) {
    if (faces.isEmpty) {
      return FrameStats(detected: 0, focused: 0, distracted: 0, avgFocus: 0);
    }
    int focused = 0;
    double total = 0;
    for (final f in faces) {
      final s = scoreForFace(f);
      total += s;
      if (stateFromScore(s) == FocusState.focused) focused++;
    }
    return FrameStats(
      detected: faces.length,
      focused: focused,
      distracted: faces.length - focused,
      avgFocus: total / faces.length,
    );
  }
}

class FrameStats {
  final int detected;
  final int focused;
  final int distracted;
  final double avgFocus;
  FrameStats({
    required this.detected,
    required this.focused,
    required this.distracted,
    required this.avgFocus,
  });
}
