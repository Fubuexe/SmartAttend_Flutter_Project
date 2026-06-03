import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../utils/validators.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _reg = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _agree = false;
  UserRole _role = UserRole.teacher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is UserRole) _role = arg;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      _snack('Please accept the Terms & Privacy Policy');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      fullName: _name.text,
      email: _email.text,
      password: _password.text,
      role: _role,
      registrationNumber: _role == UserRole.student ? _reg.text : null,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        _role == UserRole.teacher ? Routes.teacherHome : Routes.studentHome,
        (_) => false,
      );
    } else {
      _snack(auth.error ?? 'Sign up failed');
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStudent = _role == UserRole.student;
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create ${isStudent ? "Student" : "Teacher"} Account',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Join SmartAttend to get started',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 28),
                AppField(
                  label: 'Full Name',
                  hint: 'Ahmed Mohamed',
                  icon: Icons.person_outline,
                  controller: _name,
                  validator: (v) => Validators.notEmpty(v, 'Name'),
                ),
                if (isStudent)
                  AppField(
                    label: 'Registration Number',
                    hint: '21-12345',
                    icon: Icons.badge_outlined,
                    controller: _reg,
                    validator: (v) =>
                        Validators.notEmpty(v, 'Registration number'),
                  ),
                AppField(
                  label: 'Email',
                  hint: 'you@university.edu',
                  icon: Icons.mail_outline,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                AppField(
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  controller: _password,
                  obscure: true,
                  validator: Validators.password,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _agree,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                    ),
                    const Expanded(
                      child: Text('I agree to the Terms & Privacy Policy',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Create Account',
                  loading: auth.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: AppColors.textMuted),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
