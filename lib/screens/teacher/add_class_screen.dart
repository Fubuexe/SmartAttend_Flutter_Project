import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import '../../widgets/common.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});
  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _schedule = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user!;
    await FirestoreService().addClass(ClassModel(
      id: '',
      teacherId: user.uid,
      code: _code.text.trim(),
      name: _name.text.trim(),
      schedule: _schedule.text.trim(),
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Add Class')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              children: [
                AppField(
                  label: 'Course Code',
                  hint: 'CS 301',
                  icon: Icons.tag,
                  controller: _code,
                  validator: (v) => Validators.notEmpty(v, 'Code'),
                ),
                AppField(
                  label: 'Course Name',
                  hint: 'Algorithms & Data Structures',
                  icon: Icons.menu_book_outlined,
                  controller: _name,
                  validator: (v) => Validators.notEmpty(v, 'Name'),
                ),
                AppField(
                  label: 'Schedule',
                  hint: 'Mon, Wed • 10:00 AM',
                  icon: Icons.schedule,
                  controller: _schedule,
                  validator: (v) => Validators.notEmpty(v, 'Schedule'),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                    label: 'Create Class', loading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
