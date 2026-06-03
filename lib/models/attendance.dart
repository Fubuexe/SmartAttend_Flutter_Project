import 'package:cloud_firestore/cloud_firestore.dart';

enum FocusState { focused, distracted, absent }

/// One student's result within a session.
class AttendanceRecord {
  final String studentId;
  final String studentName;
  final bool present;
  final double focusScore;   // 0..1
  final FocusState state;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.present,
    required this.focusScore,
    required this.state,
  });

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'present': present,
        'focusScore': focusScore,
        'state': state.name,
      };

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
        studentId: m['studentId'] ?? '',
        studentName: m['studentName'] ?? '',
        present: m['present'] ?? false,
        focusScore: (m['focusScore'] ?? 0).toDouble(),
        state: FocusState.values.firstWhere(
          (e) => e.name == m['state'],
          orElse: () => FocusState.absent,
        ),
      );
}

/// A single attendance-taking session for a class.
class AttendanceSession {
  final String id;
  final String classId;
  final DateTime date;
  final int totalStudents;
  final int presentCount;
  final double avgFocus;     // 0..1
  final List<AttendanceRecord> records;

  AttendanceSession({
    required this.id,
    required this.classId,
    required this.date,
    required this.totalStudents,
    required this.presentCount,
    required this.avgFocus,
    this.records = const [],
  });

  double get attendanceRate =>
      totalStudents == 0 ? 0 : presentCount / totalStudents;

  factory AttendanceSession.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return AttendanceSession(
      id: doc.id,
      classId: m['classId'] ?? '',
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalStudents: (m['totalStudents'] ?? 0) as int,
      presentCount: (m['presentCount'] ?? 0) as int,
      avgFocus: (m['avgFocus'] ?? 0).toDouble(),
      records: (m['records'] as List?)
              ?.map((e) => AttendanceRecord.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'classId': classId,
        'date': Timestamp.fromDate(date),
        'totalStudents': totalStudents,
        'presentCount': presentCount,
        'avgFocus': avgFocus,
        'records': records.map((r) => r.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };
}
