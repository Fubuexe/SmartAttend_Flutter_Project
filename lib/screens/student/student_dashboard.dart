import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../services/firestore_service.dart';
import '../../models/student_model.dart';
import '../../models/class_model.dart';
import 'student_attendance_screen.dart';
import 'student_focus_screen.dart';
import '../shared/profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _tab = 0;
  final _pages = const [
    _StudentHome(),
    StudentAttendanceScreen(),
    StudentFocusScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_available_outlined), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Focus'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StudentHome extends StatelessWidget {
  const _StudentHome();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final regNumber = user.registrationNumber ?? '';
    final fs = FirestoreService();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, ${user.fullName.split(" ").first}! 👋',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Performance stats ────────────────────────────────────────────────
          if (regNumber.isEmpty)
            const AppCard(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No registration number linked to your account.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            FutureBuilder<Map<String, dynamic>>(
              future: fs.studentStats(regNumber),
              builder: (context, snap) {
                final loading = snap.connectionState == ConnectionState.waiting;
                final stats = snap.data;
                final attendancePct = loading
                    ? '…'
                    : stats == null
                        ? '—'
                        : '${((stats['attendancePct'] as double) * 100).toStringAsFixed(0)}%';
                final avgFocus = loading
                    ? '…'
                    : stats == null
                        ? '—'
                        : '${((stats['avgFocus'] as double) * 100).toStringAsFixed(0)}%';
                final courseCount = loading
                    ? '…'
                    : stats == null
                        ? '—'
                        : '${stats['courseCount']}';

                return AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Performance',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatChip(
                              value: attendancePct,
                              label: 'Attendance',
                              color: AppColors.focused),
                          StatChip(
                              value: avgFocus,
                              label: 'Avg Focus',
                              color: AppColors.primary),
                          StatChip(
                              value: courseCount,
                              label: 'Courses',
                              color: AppColors.warning),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),
          const Text('My Courses',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          // ── Enrolled courses (live stream) ───────────────────────────────────
          if (regNumber.isEmpty)
            const AppCard(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('No registration number found.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            StreamBuilder<List<StudentModel>>(
              stream: fs.enrollmentsByRegNumber(regNumber),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final enrollments = snap.data ?? [];
                if (enrollments.isEmpty) {
                  return const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'You are not enrolled in any classes yet.\n'
                        'Ask your teacher to enroll you using your registration number.',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Column(
                  children: enrollments
                      .map((e) => _CourseCard(enrollment: e, fs: fs))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Card showing a single enrolled course with its class details.
class _CourseCard extends StatelessWidget {
  final StudentModel enrollment;
  final FirestoreService fs;
  const _CourseCard({required this.enrollment, required this.fs});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClassModel?>(
      future: fs.classById(enrollment.classId),
      builder: (context, snap) {
        final cls = snap.data;
        final name = cls?.name ?? (snap.connectionState == ConnectionState.waiting ? 'Loading…' : 'Unknown class');
        final schedule = cls?.schedule ?? '';
        final code = cls?.code ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.menu_book_outlined,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (schedule.isNotEmpty)
                        Text(
                          code.isNotEmpty ? '$code • $schedule' : schedule,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
