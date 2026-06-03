import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import '../../models/attendance.dart';
import '../../widgets/common.dart';
import 'classes_screen.dart';
import 'reports_screen.dart';
import '../shared/profile_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _tab = 0;
  late final List<Widget> _pages = [
    const _HomeTab(),
    const ClassesScreen(embedded: true),
    const ReportsScreen(),
    const ProfileScreen(),
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
          NavigationDestination(icon: Icon(Icons.class_outlined), label: 'Classes'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final fs = FirestoreService();
    return SafeArea(
      child: StreamBuilder<List<ClassModel>>(
        stream: fs.teacherClasses(user.uid),
        builder: (context, snap) {
          final classes = snap.data ?? [];
          final totalStudents =
              classes.fold<int>(0, (s, c) => s + c.studentCount);
          final classIds = classes.map((c) => c.id).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${user.fullName.split(" ").first}! 👋',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700)),
                        Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                            style: const TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(_initials(user.fullName),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Today's Overview card — avg focus is live from Firestore
              StreamBuilder<List<AttendanceSession>>(
                stream: classIds.isEmpty
                    ? Stream.value([])
                    : fs.allSessionsForClasses(classIds),
                builder: (context, sessSnap) {
                  final now = DateTime.now();
                  final todaySessions = (sessSnap.data ?? [])
                      .where((s) =>
                          s.date.year == now.year &&
                          s.date.month == now.month &&
                          s.date.day == now.day)
                      .toList();
                  final avgFocusStr = _computeAvgFocus(todaySessions);

                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's Overview",
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            StatChip(
                                value: '${classes.length}',
                                label: 'Classes',
                                color: AppColors.primary),
                            StatChip(
                                value: '$totalStudents',
                                label: 'Students',
                                color: AppColors.accent),
                            StatChip(
                                value: avgFocusStr,
                                label: 'Avg Focus',
                                color: AppColors.warning),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              AppCard(
                onTap: () =>
                    Navigator.pushNamed(context, Routes.classes),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Take Attendance',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('Scan classroom with AI camera',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Your Classes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator())),
              if (classes.isEmpty &&
                  snap.connectionState != ConnectionState.waiting)
                const _EmptyHint(),
              ...classes.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClassTile(model: c),
                  )),
            ],
          );
        },
      ),
    );
  }

  /// Returns "—" when no sessions today, otherwise "XX%" average.
  static String _computeAvgFocus(List<AttendanceSession> sessions) {
    if (sessions.isEmpty) return '—';
    final avg = sessions.fold<double>(0, (s, e) => s + e.avgFocus) /
        sessions.length;
    return '${(avg * 100).round()}%';
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: [
            const Icon(Icons.class_outlined,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 8),
            const Text('No classes yet'),
            const SizedBox(height: 4),
            const Text('Tap Classes → + to add your first class',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
}