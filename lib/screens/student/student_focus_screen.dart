import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class StudentFocusScreen extends StatelessWidget {
  const StudentFocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weekly = [0.72, 0.80, 0.68, 0.88, 0.85, 0.91, 0.83];
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('My Focus',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Week’s Focus',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: 1,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(labels[v.toInt()],
                                  style: const TextStyle(fontSize: 11)),
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (int i = 0; i < weekly.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: weekly[i],
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              color: weekly[i] >= 0.6
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
          AppCard(
            child: Row(
              children: const [
                Icon(Icons.tips_and_updates_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Your focus peaks on Saturday. Try scheduling tougher topics earlier in the week.',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
