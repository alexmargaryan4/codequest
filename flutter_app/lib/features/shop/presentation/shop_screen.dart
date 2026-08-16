import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/game_economy_constants.dart';
import '../../../core/providers/gems_provider.dart';
import '../../../core/providers/hearts_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/gems_wallet.dart';
import '../../../models/hearts_state.dart';
import '../../../services/gems_service.dart';
import '../../../services/hearts_service.dart';
import '../../../shared/widgets/gems_badge.dart';
import '../../../shared/widgets/hearts_badge.dart';

/// Spend gems on hearts refills, a streak freeze, or a temporary XP
/// boost. Every purchase goes through [HeartsService]/[GemsService] (via
/// their notifiers) so balance changes stay consistent with whatever
/// else in the app might be reading them concurrently.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HeartsState> heartsAsync = ref.watch(heartsProvider);
    final AsyncValue<GemsWallet> gemsAsync = ref.watch(gemsProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Магазин')),
      body: SafeArea(
        child: gemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (GemsWallet wallet) {
            final HeartsState? hearts = heartsAsync.valueOrNull;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: <Widget>[
                Center(child: GemsBadge(balance: wallet.balance)),
                const SizedBox(height: 24),
                Text('Жизни', style: text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Теряешь жизнь за неверный ответ. Полное восстановление раз в ${HeartsConfig.regenDuration.inMinutes ~/ 60 == 0 ? '${HeartsConfig.regenDuration.inMinutes} мин' : '${HeartsConfig.regenDuration.inMinutes} мин'} за жизнь.',
                  style: text.bodySmall?.copyWith(color: semantic.textMuted),
                ),
                const SizedBox(height: 12),
                if (hearts != null) ...<Widget>[
                  Row(
                    children: <Widget>[
                      HeartsBadge(hearts: hearts),
                      const SizedBox(width: 10),
                      Expanded(child: HeartsCountdownLabel(hearts: hearts)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ShopItemCard(
                    icon: Icons.favorite_rounded,
                    iconColor: AppColors.error,
                    title: 'Заполнить все жизни',
                    subtitle: 'Мгновенно до ${HeartsConfig.maxHearts} жизней',
                    costGems: HeartsConfig.refillCostGems,
                    disabled: hearts.isFull,
                    disabledReason: hearts.isFull ? 'Жизни уже полные' : null,
                    onBuy: () => _buyRefill(context, ref),
                  ),
                  const SizedBox(height: 10),
                  _ShopItemCard(
                    icon: Icons.add_circle_rounded,
                    iconColor: AppColors.error,
                    title: 'Одна жизнь',
                    subtitle: '+1 жизнь сразу',
                    costGems: HeartsConfig.singleHeartCostGems,
                    disabled: hearts.isFull,
                    disabledReason: hearts.isFull ? 'Жизни уже полные' : null,
                    onBuy: () => _buySingleHeart(context, ref),
                  ),
                ],
                const SizedBox(height: 28),
                Text('Бонусы', style: text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Разовые усиления, которые помогают прогрессировать быстрее.',
                  style: text.bodySmall?.copyWith(color: semantic.textMuted),
                ),
                const SizedBox(height: 12),
                _ShopItemCard(
                  icon: Icons.ac_unit_rounded,
                  iconColor: AppColors.accentIndigo,
                  title: 'Заморозка стрика',
                  subtitle: 'Сохранит серию, если пропустишь день',
                  costGems: GemsConfig.streakFreezeCost,
                  disabled: wallet.streakFreezeAvailable,
                  disabledReason: wallet.streakFreezeAvailable ? 'Уже активна' : null,
                  onBuy: () => _buyStreakFreeze(context, ref),
                ),
                const SizedBox(height: 10),
                _ShopItemCard(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.streakAmber,
                  title: 'Ускорение x${GemsConfig.xpBoostMultiplier.toStringAsFixed(0)}',
                  subtitle:
                      'Двойной XP на ${GemsConfig.xpBoostDuration.inMinutes} минут'
                      '${wallet.hasActiveXpBoost ? ' (уже активно, добавит время)' : ''}',
                  costGems: GemsConfig.xpBoostCost,
                  disabled: false,
                  onBuy: () => _buyXpBoost(context, ref),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _buyRefill(BuildContext context, WidgetRef ref) async {
    final HeartsPurchaseResult result = await ref.read(heartsProvider.notifier).refillWithGems();
    _showResult(context, success: result.success, message: result.message ?? 'Жизни восстановлены!');
  }

  Future<void> _buySingleHeart(BuildContext context, WidgetRef ref) async {
    final HeartsPurchaseResult result = await ref.read(heartsProvider.notifier).buySingleHeart();
    _showResult(context, success: result.success, message: result.message ?? 'Жизнь добавлена!');
  }

  Future<void> _buyStreakFreeze(BuildContext context, WidgetRef ref) async {
    final GemsPurchaseResult result = await ref.read(gemsProvider.notifier).buyStreakFreeze();
    _showResult(context, success: result.success, message: result.message ?? 'Заморозка куплена!');
  }

  Future<void> _buyXpBoost(BuildContext context, WidgetRef ref) async {
    final GemsPurchaseResult result = await ref.read(gemsProvider.notifier).buyXpBoost();
    _showResult(context, success: result.success, message: result.message ?? 'Ускорение активировано!');
  }

  void _showResult(BuildContext context, {required bool success, required String message}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.costGems,
    required this.onBuy,
    this.disabled = false,
    this.disabledReason,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int costGems;
  final bool disabled;
  final String? disabledReason;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: semantic.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.titleSmall),
                Text(
                  disabled && disabledReason != null ? disabledReason! : subtitle,
                  style: text.bodySmall?.copyWith(color: semantic.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: disabled ? null : onBuy,
            icon: const Icon(Icons.diamond_rounded, size: 16),
            label: Text('$costGems'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03, end: 0);
  }
}
