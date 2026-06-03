import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../models/app_user.dart';
import '../../widgets/common.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome 👋',
                  style:
                      TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Choose your role to get started',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 32),
              _RoleCard(
                icon: Icons.school_outlined,
                title: "I'm a Teacher",
                subtitle:
                    'Take attendance, monitor student engagement, and view detailed reports.',
                onTap: () => Navigator.pushNamed(context, Routes.login,
                    arguments: UserRole.teacher),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.person_outline,
                title: "I'm a Student",
                subtitle:
                    'View your attendance, track focus scores, and check your progress.',
                onTap: () => Navigator.pushNamed(context, Routes.login,
                    arguments: UserRole.student),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}
