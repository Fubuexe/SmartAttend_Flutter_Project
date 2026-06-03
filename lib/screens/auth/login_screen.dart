import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../utils/validators.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        auth.user!.role == UserRole.teacher
            ? Routes.teacherHome
            : Routes.studentHome,
        (_) => false,
      );
    } else {
      _snack(auth.error ?? 'Login failed');
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                Center(
                  child: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.visibility, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('Welcome Back!',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Sign in to continue to SmartAttend',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(height: 32),
                AppField(
                  label: 'Email Address',
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
                  obscure: _obscure,
                  validator: Validators.password,
                  suffix: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.forgot),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Sign In',
                  loading: auth.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () {
                        final role = ModalRoute.of(context)?.settings.arguments;
                        Navigator.pushNamed(context, Routes.signup,
                            arguments: role);
                      },
                      child: const Text('Sign Up',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
