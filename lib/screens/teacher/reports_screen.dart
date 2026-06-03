import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import '../../models/attendance.dart';
import '../../widgets/common.dart';

/// Reports: if opened from a class -> that class; if from the Reports tab ->
/// aggregates the teacher's classes.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final fs = FirestoreService();

    if (arg is ClassModel) {
      return Scaffold(
        appBar: AppBar(
            leading: const BackButton(), title: Text('${arg.code} Reports')),
        body: _ClassReport(classId: arg.id, fs: fs),
      );
    }

    // Tab mode: pick first class for the chart, list all classes' rates.
    final user = context.watch<AuthProvider>().user!;
    return SafeArea(
      child: StreamBuilder<List<ClassModel>>(
        stream: fs.teacherClasses(user.uid),
        builder: (context, snap) {
          final classes = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Reports & Insights',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (classes.isEmpty)
                const AppCard(child: Text('No data yet. Add a class and take attendance.')),
              ...classes.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.code} — ${c.name}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _ClassReport(classId: c.id, fs: fs, compact: true),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _ClassReport extends StatelessWidget {
  final String classId;
  final FirestoreService fs;
  final bool compact;
  const _ClassReport(
      {required this.classId, required this.fs, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceSession>>(
      stream: fs.classSessions(classId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ));
        }
        final sessions = (snap.data ?? []).reversed.toList();
        if (sessions.isEmpty) {
          return const AppCard(child: Text('No sessions recorded yet.'));
        }
        final avgAttendance = sessions
                .map((s) => s.attendanceRate)
                .fold<double>(0, (a, b) => a + b) /
            sessions.length;
        final avgFocus = sessions
                .map((s) => s.avgFocus)
                .fold<double>(0, (a, b) => a + b) /
            sessions.length;

        final content = Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attendance Rate',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        Text('${(avgAttendance * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.focused)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Avg Focus Score',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        Text('${(avgFocus * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Focus Trend',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 1,
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= sessions.length) {
                                  return const SizedBox();
                                }
                                return Text(
                                    DateFormat('M/d')
                                        .format(sessions[i].date),
                                    style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (v, _) => Text(
                                  '${(v * 100).round()}',
                                  style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withOpacity(0.12)),
                            spots: [
                              for (int i = 0; i < sessions.length; i++)
                                FlSpot(i.toDouble(), sessions[i].avgFocus),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (compact) return content;
        return ListView(padding: const EdgeInsets.all(20), children: [content]);
      },
    );
  }
}
