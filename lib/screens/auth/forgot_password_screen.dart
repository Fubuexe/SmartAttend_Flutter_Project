import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(_email.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Reset link sent! Check your email.'
          : (auth.error ?? 'Could not send reset link')),
    ));
    if (ok) Navigator.pop(context);
  }

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
              children: [
                const SizedBox(height: 20),
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.key_rounded,
                      size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text('Forgot Password?',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                    "Don't worry! Enter your email below and we'll send you a reset link.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 28),
                AppField(
                  label: 'Email Address',
                  hint: 'you@university.edu',
                  icon: Icons.mail_outline,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                PrimaryButton(
                  label: 'Send Reset Link',
                  loading: auth.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Remember your password? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
