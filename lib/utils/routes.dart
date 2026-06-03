/// Named routes for navigation across all screens.
class Routes {
  static const initial = splash;
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const roleSelect = '/role';
  static const login = '/login';
  static const signup = '/signup';
  static const forgot = '/forgot';

  // teacher
  static const teacherHome = '/teacher/home';
  static const classes = '/teacher/classes';
  static const classDetail = '/teacher/class-detail';
  static const addClass = '/teacher/add-class';
  static const takeAttendance = '/teacher/take-attendance';
  static const attendanceResult = '/teacher/attendance-result';
  static const enrollStudent = '/teacher/enroll';
  static const reports = '/teacher/reports';

  // student
  static const studentHome = '/student/home';
  static const studentAttendance = '/student/attendance';
  static const studentFocus = '/student/focus';

  // shared
  static const profile = '/profile';
}
