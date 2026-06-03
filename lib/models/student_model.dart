import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

/// An enrolled student belonging to a class.
/// [embedding] is the 192-d MobileFaceNet face vector used for recognition.
class StudentModel {
  final String id;
  final String classId;
  final String name;
  final String registrationNumber;
  final String? photoUrl;
  final List<double> embedding;

  StudentModel({
    required this.id,
    required this.classId,
    required this.name,
    required this.registrationNumber,
    this.photoUrl,
    this.embedding = const [],
  });

  factory StudentModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      classId: m['classId'] ?? '',
      name: m['name'] ?? '',
      registrationNumber: m['registrationNumber'] ?? '',
      photoUrl: m['photoUrl'],
      embedding: (m['embedding'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
  }

  /// Returns an [ImageProvider] for the student photo, or null if none stored.
  /// Handles both legacy Firebase Storage URLs and base64-encoded thumbnails.
  ImageProvider? get photoImage {
    if (photoUrl == null || photoUrl!.isEmpty) return null;
    if (photoUrl!.startsWith('http')) {
      return NetworkImage(photoUrl!);
    }
    return MemoryImage(base64Decode(photoUrl!));
  }

  Map<String, dynamic> toMap() => {
        'classId': classId,
        'name': name,
        'registrationNumber': registrationNumber,
        'photoUrl': photoUrl,
        'embedding': embedding,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
