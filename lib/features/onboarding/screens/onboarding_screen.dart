import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_Slide> _slides = const [
    _Slide(
      icon: Icons.dashboard_customize_outlined,
      title: 'Manage Your Kameti Easily',
      description: 'Create and manage your committee groups in one place.',
    ),
    _Slide(
      icon: Icons.fact_check_outlined,
      title: 'Track Members & Payments',
      description:
          'Keep clear records of members, monthly amounts, and payment status.',
    ),
    _Slide(
      icon: Icons.verified_user_outlined,
      title: 'Transparent & Simple',
      description:
          'Reduce confusion with organized kameti records and history.',
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  void _finish() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child:
                    TextButton(onPressed: _finish, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon,
                              size: 72, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 38),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.black54, height: 1.45),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (dot) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: dot == _index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: dot == _index
                          ? theme.colorScheme.primary
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _isLast ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide(
      {required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;
}
