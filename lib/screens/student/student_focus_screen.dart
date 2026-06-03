import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/attendance.dart';

class StudentFocusScreen extends StatelessWidget {
  const StudentFocusScreen({super.key});

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

                // Only sessions where student was present and has a focus score.
                final focusEntries = history
                    .where((h) =>
                        h['record'] != null &&
                        (h['record'] as AttendanceRecord).present)
                    .toList();

                // Take up to the 7 most recent present sessions for the chart.
                final chartData = focusEntries.take(7).toList().reversed.toList();

                final avgFocus = focusEntries.isEmpty
                    ? 0.0
                    : focusEntries
                            .map((h) =>
                                (h['record'] as AttendanceRecord).focusScore)
                            .reduce((a, b) => a + b) /
                        focusEntries.length;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('My Focus',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // Summary card.
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatChip(
                            value: '${(avgFocus * 100).toStringAsFixed(0)}%',
                            label: 'Avg Focus',
                            color: AppColors.primary,
                          ),
                          StatChip(
                            value: '${focusEntries.length}',
                            label: 'Sessions',
                            color: AppColors.focused,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Focus chart.
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recent Focus Trend',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 20),
                          if (chartData.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No focus data yet.\nAttend a class to see your trend.',
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 200,
                              child: BarChart(
                                BarChartData(
                                  maxY: 1,
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (v, _) {
                                          final idx = v.toInt();
                                          if (idx < 0 ||
                                              idx >= chartData.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final date = (chartData[idx]['session']
                                                  as AttendanceSession)
                                              .date;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 6),
                                            child: Text(
                                              DateFormat('d/M').format(date),
                                              style: const TextStyle(
                                                  fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: [
                                    for (int i = 0; i < chartData.length; i++)
                                      BarChartGroupData(x: i, barRods: [
                                        BarChartRodData(
                                          toY: (chartData[i]['record']
                                                  as AttendanceRecord)
                                              .focusScore,
                                          width: 22,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: (chartData[i]['record']
                                                          as AttendanceRecord)
                                                      .focusScore >=
                                                  0.6
                                              ? AppColors.primary
                                              : AppColors.warning,
                                        ),
                                      ]),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tip card.
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.tips_and_updates_outlined,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _focusTip(avgFocus),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _focusTip(double avg) {
    if (avg == 0) return 'Attend a class to start tracking your focus score.';
    if (avg >= 0.8) {
      return 'Excellent focus! Keep up the great work and maintain your concentration habits.';
    } else if (avg >= 0.6) {
      return 'Good focus overall. Try to minimise distractions — put your phone away during class.';
    } else {
      return 'Your focus could improve. Try sitting closer to the front and getting more sleep.';
    }
  }
}
