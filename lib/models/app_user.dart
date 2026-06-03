import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { teacher, student }

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final String? registrationNumber; // students
  final String? photoUrl;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.registrationNumber,
    this.photoUrl,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        fullName: m['fullName'] ?? '',
        email: m['email'] ?? '',
        role: (m['role'] == 'teacher') ? UserRole.teacher : UserRole.student,
        registrationNumber: m['registrationNumber'],
        photoUrl: m['photoUrl'],
      );

  factory AppUser.fromDoc(DocumentSnapshot doc) =>
      AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'email': email,
        'role': role == UserRole.teacher ? 'teacher' : 'student',
        'registrationNumber': registrationNumber,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

  bool get isTeacher => role == UserRole.teacher;
}
