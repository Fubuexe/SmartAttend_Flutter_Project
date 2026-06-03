import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Holds the signed-in user + role across the app.
class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  AuthService get service => _auth;

  void _set(bool l, [String? e]) {
    _loading = l;
    _error = e;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _set(true);
    try {
      _user = await _auth.signIn(email, password);
      _set(false);
      return true;
    } catch (e) {
      _set(false, _readable(e));
      return false;
    }
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? registrationNumber,
  }) async {
    _set(true);
    try {
      _user = await _auth.signUp(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        registrationNumber: registrationNumber,
      );
      _set(false);
      return true;
    } catch (e) {
      _set(false, _readable(e));
      return false;
    }
  }

  Future<void> tryRestore() async {
    final current = _auth.currentUser;
    if (current != null) {
      try {
        _user = await _auth.fetchProfile(current.uid);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<bool> resetPassword(String email) async {
    _set(true);
    try {
      await _auth.sendPasswordReset(email);
      _set(false);
      return true;
    } catch (e) {
      _set(false, _readable(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  String _readable(Object e) {
    final s = e.toString();
    if (s.contains('user-not-found')) return 'No account found for that email.';
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (s.contains('email-already-in-use')) return 'That email is already registered.';
    if (s.contains('weak-password')) return 'Password should be at least 6 characters.';
    if (s.contains('network')) return 'Network error — check your connection.';
    return 'Something went wrong. Please try again.';
  }
}
