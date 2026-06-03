import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Wraps Firebase Authentication + the matching Firestore `users/{uid}` doc.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  /// Sign up, then store profile (name, role, reg number) in Firestore.
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? registrationNumber,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = AppUser(
      uid: cred.user!.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      role: role,
      registrationNumber: registrationNumber?.trim(),
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    await cred.user!.updateDisplayName(fullName.trim());
    return user;
  }

  Future<AppUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return fetchProfile(cred.user!.uid);
  }

  Future<AppUser> fetchProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw FirebaseAuthException(
          code: 'no-profile', message: 'No profile found for this account.');
    }
    return AppUser.fromDoc(doc);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();
}
