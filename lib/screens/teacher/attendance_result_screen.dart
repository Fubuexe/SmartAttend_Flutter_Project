import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/attendance.dart';
import '../../widgets/common.dart';

class AttendanceResultScreen extends StatelessWidget {
  const AttendanceResultScreen({super.key});

  Color _stateColor(FocusState s) {
    switch (s) {
      case FocusState.focused:
        return AppColors.focused;
      case FocusState.distracted:
        return AppColors.warning;
      case FocusState.absent:
        return AppColors.absent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ModalRoute.of(context)!.settings.arguments as AttendanceSession;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        title: const Text('Session Summary'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                        color: AppColors.focused.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle,
                        color: AppColors.focused, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text('Attendance Recorded',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StatChip(
                          value: '${session.presentCount}',
                          label: 'Present',
                          color: AppColors.focused),
                      StatChip(
                          value: '${session.totalStudents - session.presentCount}',
                          label: 'Absent',
                          color: AppColors.absent),
                      StatChip(
                          value: '${(session.avgFocus * 100).round()}%',
                          label: 'Avg Focus',
                          color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Students',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (session.records.isEmpty)
              const AppCard(
                  child: Text('No enrolled students. Faces detected were counted only.')),
            ...session.records.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _stateColor(r.state).withOpacity(0.15),
                          child: Icon(
                              r.present ? Icons.person : Icons.person_off_outlined,
                              color: _stateColor(r.state)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(r.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: _stateColor(r.state).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            r.present
                                ? '${r.state.name[0].toUpperCase()}${r.state.name.substring(1)} • ${(r.focusScore * 100).round()}%'
                                : 'Absent',
                            style: TextStyle(
                                color: _stateColor(r.state),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
