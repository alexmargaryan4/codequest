import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Full-screen celebratory overlay shown when the user levels up.
/// Lightweight confetti burst + scale-in badge; dismissible by tapping
/// anywhere, so it never blocks the user's flow for long.
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({required this.newLevel, required this.onDismiss, super.key});

  final int newLevel;
  final VoidCallback onDismiss;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Positioned(
              top: 0,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const <Color>[
                  AppColors.accentIndigo,
                  AppColors.success,
                  AppColors.streakAmber,
                ],
                numberOfParticles: 24,
                gravity: 0.3,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: <Color>[AppColors.accentIndigoMuted, AppColors.accentIndigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.accentIndigo.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.military_tech_rounded, color: Colors.white, size: 56),
                ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.3, 0.3),
                    ),
                const SizedBox(height: 24),
                Text(
                  'Новый уровень!',
                  style: text.headlineMedium?.copyWith(color: Colors.white),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 4),
                Text(
                  'Level ${widget.newLevel}',
                  style: text.displayLarge?.copyWith(color: AppColors.accentIndigo),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 32),
                Text(
                  'Нажми, чтобы продолжить',
                  style: text.bodyMedium?.copyWith(color: Colors.white70),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
