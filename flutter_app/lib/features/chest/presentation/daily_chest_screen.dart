import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/rewards_constants.dart';
import '../../../core/providers/chest_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/daily_chest.dart';

class DailyChestScreen extends ConsumerStatefulWidget {
  const DailyChestScreen({super.key});

  @override
  ConsumerState<DailyChestScreen> createState() => _DailyChestScreenState();
}

class _DailyChestScreenState extends ConsumerState<DailyChestScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  ChestRewardResult? _reward;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);

    await _shakeController.forward(from: 0);
    final ChestRewardResult? reward = await ref.read(chestProvider.notifier).open();

    if (!mounted) return;
    setState(() {
      _reward = reward;
      _opening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DailyChestState> chestAsync = ref.watch(chestProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Ежедневный сундук')),
      body: SafeArea(
        child: chestAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (DailyChestState chest) {
            final bool available = chest.isAvailableToday;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  const Spacer(),
                  if (_reward == null) ...<Widget>[
                    _ChestVisual(shakeController: _shakeController, opened: false)
                        .animate(target: _opening ? 1 : 0),
                    const SizedBox(height: 28),
                    Text(
                      available ? 'Сундук ждёт открытия!' : 'Уже открыт сегодня',
                      style: text.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      available
                          ? 'Открывай сундук каждый день, чтобы получать гемы, опыт и бонусы.'
                          : 'Возвращайся завтра за новой наградой.',
                      style: text.bodyMedium?.copyWith(color: semantic.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _StreakPill(streak: chest.openStreak),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: available && !_opening ? _open : null,
                        child: Text(_opening ? 'Открываем…' : 'Открыть сундук'),
                      ),
                    ),
                  ] else ...<Widget>[
                    _ChestVisual(shakeController: _shakeController, opened: true),
                    const SizedBox(height: 28),
                    _RewardCard(reward: _reward!),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Отлично!'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChestVisual extends StatelessWidget {
  const _ChestVisual({required this.shakeController, required this.opened});

  final AnimationController shakeController;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(
      opened ? Icons.inventory_2_rounded : Icons.card_giftcard_rounded,
      size: 120,
      color: AppColors.streakAmber,
    );

    if (opened) {
      return icon.animate().scale(duration: 450.ms, curve: Curves.easeOutBack).fadeIn();
    }

    return AnimatedBuilder(
      animation: shakeController,
      builder: (BuildContext context, Widget? child) {
        final double t = shakeController.value;
        final double angle = t == 0 ? 0 : (0.12 * (1 - t)) * ((t * 12).floor().isEven ? 1 : -1);
        return Transform.rotate(angle: angle, child: child);
      },
      child: icon,
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.streakAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.streakAmber.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.streakAmber),
          const SizedBox(width: 6),
          Text(
            '$streak ${_dayWord(streak)} подряд',
            style: text.labelMedium?.copyWith(color: AppColors.streakAmber),
          ),
        ],
      ),
    );
  }

  static String _dayWord(int n) {
    final int mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    switch (n % 10) {
      case 1:
        return 'день';
      case 2:
      case 3:
      case 4:
        return 'дня';
      default:
        return 'дней';
    }
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward});
  final ChestRewardResult reward;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.streakAmber.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: <Widget>[
          Icon(_iconFor(reward.type), size: 40, color: AppColors.streakAmber),
          const SizedBox(height: 12),
          Text(reward.title, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            reward.description,
            style: text.bodyMedium?.copyWith(color: semantic.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  IconData _iconFor(ChestRewardType type) => switch (type) {
        ChestRewardType.gems => Icons.diamond_rounded,
        ChestRewardType.xp => Icons.bolt_rounded,
        ChestRewardType.streakFreeze => Icons.ac_unit_rounded,
        ChestRewardType.xpBoost => Icons.rocket_launch_rounded,
      };
}
