import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/routes.dart';
import '../../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  final _slides = const [
    _Slide(Icons.center_focus_strong, 'Smart Attendance\nwith Computer Vision',
        'Take attendance instantly using AI face recognition. No more roll calls — just scan the classroom.'),
    _Slide(Icons.insights, 'Real-time Focus\nDetection',
        'Detect who is focused and who is distracted live, using on-device head-pose and eye analysis.'),
    _Slide(Icons.bar_chart, 'Reports &\nInsights',
        'Track attendance rates and average focus per class, per session, over time.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _slides[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  height: 8,
                  width: _page == i ? 22 : 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, Routes.roleSelect),
                    child: const Text('Skip',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 140,
                    child: PrimaryButton(
                      label: _page == _slides.length - 1 ? 'Get Started' : 'Next',
                      onPressed: () {
                        if (_page == _slides.length - 1) {
                          Navigator.pushReplacementNamed(
                              context, Routes.roleSelect);
                        } else {
                          _pc.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Slide(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(icon, size: 84, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 16),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
