import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String teacherId;
  final String code;        // e.g. CS 301
  final String name;        // e.g. Algorithms & Data Structures
  final String schedule;    // e.g. Mon, Wed • 10:00 AM
  final int studentCount;
  final bool archived;

  ClassModel({
    required this.id,
    required this.teacherId,
    required this.code,
    required this.name,
    required this.schedule,
    this.studentCount = 0,
    this.archived = false,
  });

  factory ClassModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      teacherId: m['teacherId'] ?? '',
      code: m['code'] ?? '',
      name: m['name'] ?? '',
      schedule: m['schedule'] ?? '',
      studentCount: (m['studentCount'] ?? 0) as int,
      archived: m['archived'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'teacherId': teacherId,
        'code': code,
        'name': name,
        'schedule': schedule,
        'studentCount': studentCount,
        'archived': archived,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
