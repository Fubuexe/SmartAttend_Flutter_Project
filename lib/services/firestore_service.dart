import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/attendance.dart';

/// All Cloud Firestore reads/writes for classes, students and sessions.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Classes ----------
  Stream<List<ClassModel>> teacherClasses(String teacherId) => _db
      .collection('classes')
      .where('teacherId', isEqualTo: teacherId)
      .snapshots()
      .map((s) => s.docs.map(ClassModel.fromDoc).toList());

  Future<String> addClass(ClassModel c) async {
    final ref = await _db.collection('classes').add(c.toMap());
    return ref.id;
  }

  Future<void> archiveClass(String id, bool archived) =>
      _db.collection('classes').doc(id).update({'archived': archived});

  /// Permanently deletes a class and all its students + sessions.
  Future<void> deleteClass(String classId) async {
    final batch = _db.batch();

    // Delete all students in this class
    final students = await _db
        .collection('students')
        .where('classId', isEqualTo: classId)
        .get();
    for (final doc in students.docs) {
      batch.delete(doc.reference);
    }

    // Delete all sessions for this class
    final sessions = await _db
        .collection('sessions')
        .where('classId', isEqualTo: classId)
        .get();
    for (final doc in sessions.docs) {
      batch.delete(doc.reference);
    }

    // Delete the class itself
    batch.delete(_db.collection('classes').doc(classId));

    await batch.commit();
  }

  // ---------- Students ----------
  Stream<List<StudentModel>> classStudents(String classId) => _db
      .collection('students')
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((s) => s.docs.map(StudentModel.fromDoc).toList());

  Future<List<StudentModel>> classStudentsOnce(String classId) async {
    final s = await _db
        .collection('students')
        .where('classId', isEqualTo: classId)
        .get();
    return s.docs.map(StudentModel.fromDoc).toList();
  }

  Future<void> addStudent(StudentModel s) async {
    await _db.collection('students').add(s.toMap());
    final classRef = _db.collection('classes').doc(s.classId);
    await classRef.update({'studentCount': FieldValue.increment(1)});
  }

  /// Deletes a student and decrements the class studentCount.
  Future<void> deleteStudent(String studentId, String classId) async {
    await _db.collection('students').doc(studentId).delete();
    await _db
        .collection('classes')
        .doc(classId)
        .update({'studentCount': FieldValue.increment(-1)});
  }

  // ---------- Sessions ----------
  Stream<List<AttendanceSession>> classSessions(String classId) => _db
      .collection('sessions')
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((s) {
        final list = s.docs.map(AttendanceSession.fromDoc).toList();
        list.sort((a, b) => b.date.compareTo(a.date)); // newest first
        return list;
      });

  Future<void> saveSession(AttendanceSession session) =>
      _db.collection('sessions').add(session.toMap());

  /// Today's sessions across multiple classIds — used for the dashboard avg focus.
  Stream<List<AttendanceSession>> todaySessionsForClasses(
      List<String> classIds) {
    if (classIds.isEmpty) return Stream.value([]);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('sessions')
        .where('classId', whereIn: classIds.take(10).toList())
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((s) => s.docs.map(AttendanceSession.fromDoc).toList());
  }

  /// Sessions for a given student (used in the student app).
  Stream<List<AttendanceSession>> allSessionsForClasses(List<String> classIds) {
    if (classIds.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('sessions')
        .where('classId', whereIn: classIds.take(10).toList())
        .snapshots()
        .map((s) {
          final list = s.docs.map(AttendanceSession.fromDoc).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }
}