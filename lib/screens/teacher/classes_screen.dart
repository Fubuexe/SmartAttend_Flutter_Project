import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import '../../widgets/common.dart';

/// Reusable class list tile (used on dashboard + classes screen).
class ClassTile extends StatelessWidget {
  final ClassModel model;
  /// When true a delete (trash) icon is shown on the trailing end.
  final bool showDelete;
  const ClassTile({super.key, required this.model, this.showDelete = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () =>
          Navigator.pushNamed(context, Routes.classDetail, arguments: model),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
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
                Text(model.code,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(model.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${model.schedule} • ${model.studentCount} students',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (showDelete)
            _DeleteClassButton(model: model)
          else
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _DeleteClassButton extends StatelessWidget {
  final ClassModel model;
  const _DeleteClassButton({required this.model});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
      tooltip: 'Delete class',
      onPressed: () => _confirmDelete(context),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Class',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${model.name}"?\n\n'
          'This will also remove all enrolled students and sessions for this class.',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().deleteClass(model.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${model.name}" deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }
}

class ClassesScreen extends StatefulWidget {
  final bool embedded;
  const ClassesScreen({super.key, this.embedded = false});
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String _filter = 'All';
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final fs = FirestoreService();
    final body = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Text('My Classes',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.addClass),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search classes...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ['All', 'Active', 'Archived']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color: _filter == f
                                  ? Colors.white
                                  : AppColors.textDark),
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ClassModel>>(
              stream: fs.teacherClasses(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var classes = snap.data ?? [];
                if (_filter == 'Active') {
                  classes = classes.where((c) => !c.archived).toList();
                } else if (_filter == 'Archived') {
                  classes = classes.where((c) => c.archived).toList();
                }
                final q = _search.text.toLowerCase();
                if (q.isNotEmpty) {
                  classes = classes
                      .where((c) =>
                          c.name.toLowerCase().contains(q) ||
                          c.code.toLowerCase().contains(q))
                      .toList();
                }
                if (classes.isEmpty) {
                  return const Center(child: Text('No classes found'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  // showDelete: true so the delete icon appears in the classes tab
                  itemBuilder: (_, i) =>
                      ClassTile(model: classes[i], showDelete: true),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(appBar: AppBar(leading: const BackButton()), body: body);
  }
}