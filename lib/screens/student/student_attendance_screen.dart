import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/attendance.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final regNumber = user.registrationNumber ?? '';

    return SafeArea(
      child: regNumber.isEmpty
          ? const Center(child: Text('No registration number on file.'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: FirestoreService().studentAttendanceHistory(regNumber),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final history = snap.data ?? [];
                return RefreshIndicator(
                  onRefresh: () async => (context as Element).markNeedsBuild(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('My Attendance',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('${history.length} session(s) recorded',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 16),
                      if (history.isEmpty)
                        const AppCard(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No attendance sessions yet.\nYour teacher will take attendance using the camera.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ...history.map((h) {
                          final session = h['session'] as AttendanceSession;
                          final record = h['record'] as AttendanceRecord?;
                          final className = h['className'] as String;
                          final classCode = h['classCode'] as String;

                          final present = record?.present ?? false;
                          final focusScore = record?.focusScore ?? 0.0;
                          final statusLabel =
                              record == null ? 'No record' : (present ? 'Present' : 'Absent');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: (present
                                            ? AppColors.focused
                                            : AppColors.absent)
                                        .withValues(alpha: 0.15),
                                    child: Icon(
                                      present ? Icons.check : Icons.close,
                                      color: present
                                          ? AppColors.focused
                                          : AppColors.absent,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(className,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                          '${classCode.isNotEmpty ? "$classCode • " : ""}${DateFormat('EEE, MMM d').format(session.date)}',
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: present
                                              ? AppColors.focused
                                              : AppColors.absent,
                                        ),
                                      ),
                                      if (present)
                                        Text(
                                          'Focus ${(focusScore * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
