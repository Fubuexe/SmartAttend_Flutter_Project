import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance.dart';
import '../../widgets/common.dart';

class ClassDetailScreen extends StatelessWidget {
  const ClassDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = ModalRoute.of(context)!.settings.arguments as ClassModel;
    final fs = FirestoreService();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackButton(color: Colors.white),
                  const SizedBox(height: 8),
                  Text(model.code,
                      style: const TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w600)),
                  Text(model.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('${model.studentCount} students • ${model.schedule}',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            // ── Action buttons ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _Action(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take\nAttendance',
                    onTap: () => Navigator.pushNamed(
                        context, Routes.takeAttendance,
                        arguments: model),
                  ),
                  _Action(
                    icon: Icons.person_add_alt,
                    label: 'Enroll\nStudent',
                    onTap: () => Navigator.pushNamed(
                        context, Routes.enrollStudent,
                        arguments: model),
                  ),
                  // ── NEW: See Students ─────────────────────────────────
                  _Action(
                    icon: Icons.people_outline,
                    label: 'See\nStudents',
                    onTap: () => ClassDetailScreen._showStudentsSheet(context, model, fs),
                  ),
                  _Action(
                    icon: Icons.bar_chart,
                    label: 'View\nReports',
                    onTap: () => Navigator.pushNamed(context, Routes.reports,
                        arguments: model),
                  ),
                ],
              ),
            ),

            // ── Recent Sessions ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Sessions',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  StreamBuilder<List<AttendanceSession>>(
                    stream: fs.classSessions(model.id),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final sessions = snap.data ?? [];
                      if (sessions.isEmpty) {
                        return const AppCard(
                            child: Text(
                                'No sessions yet. Take attendance to begin.'));
                      }
                      return Column(
                        children: sessions
                            .map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AppCard(
                                    child: Row(
                                      children: [
                                        Column(
                                          children: [
                                            Text(DateFormat('d').format(s.date),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    color: AppColors.primary)),
                                            Text(
                                                DateFormat('MMM')
                                                    .format(s.date),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.textMuted)),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  DateFormat('h:mm a')
                                                      .format(s.date),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  'Attendance: ${s.presentCount}/${s.totalStudents}',
                                                  style: const TextStyle(
                                                      color:
                                                          AppColors.textMuted,
                                                      fontSize: 12.5)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                            '${(s.avgFocus * 100).round()}%',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: s.avgFocus >= 0.6
                                                    ? AppColors.focused
                                                    : AppColors.warning)),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a bottom sheet listing all enrolled students with delete buttons.
  static void _showStudentsSheet(
      BuildContext context, ClassModel model, FirestoreService fs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentsSheet(model: model, fs: fs),
    );
  }
}

// ── Students bottom sheet ────────────────────────────────────────────────────

class _StudentsSheet extends StatelessWidget {
  final ClassModel model;
  final FirestoreService fs;
  const _StudentsSheet({required this.model, required this.fs});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle + header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(model.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 17)),
                            Text('Enrolled Students',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Quick-add shortcut
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            Routes.enrollStudent,
                            arguments: model,
                          );
                        },
                        icon: const Icon(Icons.person_add_alt, size: 20),
                        tooltip: 'Enroll new student',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                ],
              ),
            ),

            // ── Student list ─────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<StudentModel>>(
                stream: fs.classStudents(model.id),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final students = snap.data ?? [];
                  if (students.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text('No students enrolled yet',
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) =>
                        _StudentTile(student: students[i], classId: model.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Student tile with delete ─────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  final StudentModel student;
  final String classId;
  const _StudentTile({required this.student, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
              ? MemoryImage(base64Decode(student.photoUrl!))
              : null,
          child: student.photoUrl == null || student.photoUrl!.isEmpty
              ? Text(
                  student.name.isNotEmpty
                      ? student.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                )
              : null,
        ),
        title: Text(student.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(student.registrationNumber,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: AppColors.danger, size: 20),
          tooltip: 'Remove student',
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove Student',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Remove "${student.name}" from this class? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().deleteStudent(student.id, classId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${student.name}" removed')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e')),
          );
        }
      }
    }
  }
}

// ── Action button widget ─────────────────────────────────────────────────────

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}