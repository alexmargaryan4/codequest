import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/settings_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// First-run welcome flow: a short pitch for the app plus a username
/// prompt, ending by marking onboarding complete (which flips the
/// router's redirect to the main app shell).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _page = 0;

  static const List<_OnboardingSlide> _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.terminal_rounded,
      title: 'Учись программировать как в игре',
      body: 'Уровни, XP и streak превращают изучение кода в понятный '
          'путь с явным прогрессом на каждом шаге.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'Programming и AI в одном месте',
      body: 'Начни с Python, JavaScript, Dart или C++, а затем переходи '
          'к работе с большими языковыми моделями и prompt engineering.',
    ),
    _OnboardingSlide(
      icon: Icons.rocket_launch_rounded,
      title: 'Практика через мини-проекты',
      body: 'После каждой группы уроков — небольшой реальный проект, '
          'а не просто ещё один тест.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final String name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await SettingsStore.instance.setUsername(name);
    }
    await SettingsStore.instance.setOnboardingComplete(true);
    ref.invalidate(onboardingCompleteProvider);
    ref.invalidate(usernameProvider);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final bool isLastPage = _page == _slides.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: List<Widget>.generate(_slides.length + 1, (int i) {
                  final bool active = i == _page;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active || i < _page
                            ? AppColors.accentIndigo
                            : semantic.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int i) => setState(() => _page = i),
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  ..._slides.map((_OnboardingSlide s) => _SlideView(slide: s)),
                  _NamePromptView(controller: _nameController),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      _finish();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Text(isLastPage ? 'Начать обучение' : 'Далее'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 44, color: AppColors.accentIndigo),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 32),
          Text(slide.title, style: text.headlineMedium, textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: text.bodyLarge?.copyWith(color: semantic.textMuted),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }
}

class _NamePromptView extends StatelessWidget {
  const _NamePromptView({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Icon(Icons.badge_rounded, size: 44, color: AppColors.accentIndigo),
          const SizedBox(height: 24),
          Text('Как тебя зовут?', style: text.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Это имя будет видно в профиле и leaderboard',
            style: text.bodyMedium?.copyWith(color: semantic.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: text.titleMedium,
            decoration: const InputDecoration(
              hintText: 'Например, Alex',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
