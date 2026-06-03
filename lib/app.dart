import 'package:flutter/material.dart';
import 'package:smart_attend/theme/app_theme.dart';
import 'package:smart_attend/utils/routes.dart';

import 'package:smart_attend/screens/auth/splash_screen.dart';
import 'package:smart_attend/screens/auth/onboarding_screen.dart';
import 'package:smart_attend/screens/auth/role_select_screen.dart';
import 'package:smart_attend/screens/auth/login_screen.dart';
import 'package:smart_attend/screens/auth/signup_screen.dart';
import 'package:smart_attend/screens/auth/forgot_password_screen.dart';
import 'package:smart_attend/screens/teacher/teacher_dashboard.dart';
import 'package:smart_attend/screens/teacher/classes_screen.dart';
import 'package:smart_attend/screens/teacher/class_detail_screen.dart';
import 'package:smart_attend/screens/teacher/add_class_screen.dart';
import 'package:smart_attend/screens/teacher/take_attendance_screen.dart';
import 'package:smart_attend/screens/teacher/attendance_result_screen.dart';
import 'package:smart_attend/screens/teacher/enroll_student_screen.dart';
import 'package:smart_attend/screens/teacher/reports_screen.dart';
import 'package:smart_attend/screens/student/student_dashboard.dart';
import 'package:smart_attend/screens/student/student_attendance_screen.dart';
import 'package:smart_attend/screens/student/student_focus_screen.dart';
import 'package:smart_attend/screens/shared/profile_screen.dart';

class SmartAttendApp extends StatelessWidget {
  const SmartAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAttend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: Routes.initial,
      routes: {
        Routes.splash: (_) => const SplashScreen(),
        Routes.onboarding: (_) => const OnboardingScreen(),
        Routes.roleSelect: (_) => const RoleSelectScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.signup: (_) => const SignUpScreen(),
        Routes.forgot: (_) => const ForgotPasswordScreen(),
        Routes.teacherHome: (_) => const TeacherDashboard(),
        Routes.classes: (_) => const ClassesScreen(),
        Routes.classDetail: (_) => const ClassDetailScreen(),
        Routes.addClass: (_) => const AddClassScreen(),
        Routes.takeAttendance: (_) => const TakeAttendanceScreen(),
        Routes.attendanceResult: (_) => const AttendanceResultScreen(),
        Routes.enrollStudent: (_) => const EnrollStudentScreen(),
        Routes.reports: (_) => const ReportsScreen(),
        Routes.studentHome: (_) => const StudentDashboard(),
        Routes.studentAttendance: (_) => const StudentAttendanceScreen(),
        Routes.studentFocus: (_) => const StudentFocusScreen(),
        Routes.profile: (_) => const ProfileScreen(),
      },
    );
  }
}