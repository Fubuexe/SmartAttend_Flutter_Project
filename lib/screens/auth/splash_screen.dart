import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    await auth.tryRestore();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    if (auth.isLoggedIn) {
      Navigator.pushReplacementNamed(
        context,
        auth.user!.role == UserRole.teacher
            ? Routes.teacherHome
            : Routes.studentHome,
      );
    } else {
      Navigator.pushReplacementNamed(context, Routes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.visibility,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            const Text('SmartAttend',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('AI-Powered Attendance & Focus Detection',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 40),
            const SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
