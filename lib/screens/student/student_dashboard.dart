import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Performance',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    StatChip(value: '92%', label: 'Attendance', color: AppColors.focused),
                    StatChip(value: '85%', label: 'Avg Focus', color: AppColors.primary),
                    StatChip(value: '5', label: 'Courses', color: AppColors.warning),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('My Courses',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ..._demoCourses.map((c) => Padding(
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
                            Text(c['name']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(c['schedule']!,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(c['focus']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.focused)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

const _demoCourses = [
  {'name': 'Algorithms & Data Structures', 'schedule': 'Mon, Wed • 10:00 AM', 'focus': '89%'},
  {'name': 'Deep Learning Fundamentals', 'schedule': 'Tue, Thu • 1:00 PM', 'focus': '82%'},
  {'name': 'Computer Vision', 'schedule': 'Wed, Fri • 2:00 PM', 'focus': '91%'},
];
