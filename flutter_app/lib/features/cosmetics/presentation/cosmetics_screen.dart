import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/rewards_constants.dart';
import '../../../core/providers/cosmetics_provider.dart';
import '../../../core/providers/gems_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/cosmetics_state.dart';
import '../../../models/gems_wallet.dart';

class CosmeticsScreen extends ConsumerWidget {
  const CosmeticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CosmeticsState> stateAsync = ref.watch(cosmeticsProvider);
    final AsyncValue<GemsWallet> gemsAsync = ref.watch(gemsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Витрина скинов'),
        actions: <Widget>[
          if (gemsAsync.valueOrNull != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.diamond_rounded, size: 18, color: AppColors.accentIndigo),
                    const SizedBox(width: 4),
                    Text('${gemsAsync.value!.balance}', style: text.titleSmall),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: stateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (CosmeticsState cosmetics) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text('Рамки аватара', style: text.titleLarge),
                const SizedBox(height: 12),
                _CosmeticsGrid(
                  category: CosmeticCategory.avatarFrame,
                  cosmetics: cosmetics,
                ),
                const SizedBox(height: 28),
                Text('Темы иконок', style: text.titleLarge),
                const SizedBox(height: 12),
                _CosmeticsGrid(
                  category: CosmeticCategory.iconTheme,
                  cosmetics: cosmetics,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CosmeticsGrid extends ConsumerWidget {
  const _CosmeticsGrid({required this.category, required this.cosmetics});

  final CosmeticCategory category;
  final CosmeticsState cosmetics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CosmeticItem> items = CosmeticsCatalog.byCategory(category);
    final String? equippedId = category == CosmeticCategory.avatarFrame
        ? cosmetics.equippedAvatarFrameId
        : cosmetics.equippedIconThemeId;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) {
        final CosmeticItem item = items[i];
        final bool owned = cosmetics.owns(item.id);
        final bool equipped = equippedId == item.id;
        return _CosmeticTile(item: item, owned: owned, equipped: equipped);
      },
    );
  }
}

class _CosmeticTile extends ConsumerWidget {
  const _CosmeticTile({required this.item, required this.owned, required this.equipped});

  final CosmeticItem item;
  final bool owned;
  final bool equipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final Color accent = AppColors.fromHex(item.colorHex);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _handleTap(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: semantic.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: equipped ? accent : semantic.border,
            width: equipped ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
                border: Border.all(color: accent, width: 3),
              ),
            ),
            const SizedBox(height: 10),
            Text(item.name, style: text.labelMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            if (equipped)
              Text('Надето', style: text.labelSmall?.copyWith(color: accent))
            else if (owned)
              Text('Куплено', style: text.labelSmall?.copyWith(color: semantic.textMuted))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.diamond_rounded, size: 14, color: AppColors.accentIndigo),
                  const SizedBox(width: 3),
                  Text('${item.priceGems}', style: text.labelSmall),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final CosmeticsNotifier notifier = ref.read(cosmeticsProvider.notifier);

    if (equipped) {
      await notifier.unequip(item.category);
      return;
    }
    if (owned) {
      await notifier.equip(item.id);
      return;
    }

    final CosmeticPurchaseResult result = await notifier.purchase(item.id);
    if (!context.mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Не удалось купить')),
      );
      return;
    }
    await notifier.equip(item.id);
  }
}
