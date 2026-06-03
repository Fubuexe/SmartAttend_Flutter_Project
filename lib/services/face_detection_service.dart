import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// On-device face detection (Google ML Kit). Produces faces with head pose
/// and eye-open probabilities, which FocusService turns into a focus score.
class FaceDetectionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // eyes open / smiling
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.08,
    ),
  );

  Future<List<Face>> detectFromInputImage(InputImage image) =>
      _detector.processImage(image);

  Future<void> dispose() => _detector.close();

  /// Maps device orientation to a rotation compensation (Android).
  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Converts a live [CameraImage] into an ML Kit [InputImage].
  /// Camera controller must be created with:
  ///   imageFormatGroup: ImageFormatGroup.nv21 (Android) / bgra8888 (iOS)
  static InputImage? inputImageFromCamera(
    CameraImage image,
    CameraController controller,
    CameraDescription camera,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      var compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensation = (sensorOrientation + compensation) % 360;
      } else {
        compensation = (sensorOrientation - compensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
