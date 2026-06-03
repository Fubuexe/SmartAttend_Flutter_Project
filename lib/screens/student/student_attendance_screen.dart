import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Student attendance history (demo data — wired to read from sessions
/// where the student's records appear; shown as a clean history list).
class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = const [
      {'course': 'Algorithms', 'date': 'Mon, May 13', 'status': 'Present', 'focus': '89%'},
      {'course': 'Deep Learning', 'date': 'Tue, May 12', 'status': 'Present', 'focus': '78%'},
      {'course': 'Computer Vision', 'date': 'Mon, May 11', 'status': 'Present', 'focus': '92%'},
      {'course': 'Algorithms', 'date': 'Wed, May 8', 'status': 'Absent', 'focus': '—'},
      {'course': 'Database Systems', 'date': 'Mon, May 6', 'status': 'Present', 'focus': '84%'},
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('My Attendance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...records.map((r) {
            final present = r['status'] == 'Present';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: (present
                              ? AppColors.focused
                              : AppColors.absent)
                          .withOpacity(0.15),
                      child: Icon(
                          present ? Icons.check : Icons.close,
                          color:
                              present ? AppColors.focused : AppColors.absent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['course']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(r['date']!,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('Focus ${r['focus']}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
