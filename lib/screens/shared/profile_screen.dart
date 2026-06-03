import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/app_user.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 34,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                Text(user.email,
                    style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    user.role == UserRole.teacher ? 'Teacher' : 'Student',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (user.registrationNumber != null)
            _tile(Icons.badge_outlined, 'Registration', user.registrationNumber!),
          _tile(Icons.notifications_outlined, 'Notifications', 'On'),
          _tile(Icons.lock_outline, 'Privacy & Security', ''),
          _tile(Icons.help_outline, 'Help & Support', ''),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Sign Out',
            icon: Icons.logout,
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, Routes.roleSelect, (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String trailing) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(trailing,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      );
}
