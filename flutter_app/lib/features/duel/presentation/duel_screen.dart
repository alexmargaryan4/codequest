import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/duel_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/duel.dart';

class DuelScreen extends ConsumerWidget {
  const DuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Duel> duelAsync = ref.watch(duelProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дуэль дня'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _showHistory(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: duelAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (Duel duel) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: semantic.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: semantic.border),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const _CombatantAvatar(icon: Icons.person_rounded, label: 'Ты'),
                          Text('VS', style: text.titleMedium?.copyWith(color: semantic.textMuted)),
                          _CombatantAvatar(icon: Icons.smart_toy_rounded, label: duel.opponentName),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${duel.playerScore} / ${duel.targetScore}',
                        style: text.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'очков',
                        style: text.bodySmall?.copyWith(color: semantic.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: duel.progressRatio,
                          minHeight: 10,
                          backgroundColor: semantic.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            duel.won == true ? AppColors.success : AppColors.accentIndigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _StatusCard(duel: duel),
                if (duel.won == true && !duel.isClaimed) ...<Widget>[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(duelProvider.notifier).claimReward(),
                      icon: const Icon(Icons.diamond_rounded),
                      label: Text('Забрать +${duel.gemsReward} гемов'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _DuelHistorySheet(ref: ref),
    );
  }
}

class _CombatantAvatar extends StatelessWidget {
  const _CombatantAvatar({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accentIndigo.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accentIndigo, size: 28),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: text.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.duel});
  final Duel duel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    final (IconData icon, Color color, String message) = switch (duel.won) {
      true => (
          Icons.emoji_events_rounded,
          AppColors.success,
          duel.isClaimed ? 'Победа! Награда уже забрана.' : 'Ты выиграл дуэль сегодня!',
        ),
      false => (Icons.sentiment_neutral_rounded, semantic.textMuted, 'В этот раз не получилось — новая дуэль уже завтра.'),
      null => (
          Icons.bolt_rounded,
          AppColors.streakAmber,
          'Решай упражнения и проходи уроки, чтобы набрать очки.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: text.bodyMedium)),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _DuelHistorySheet extends StatelessWidget {
  const _DuelHistorySheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('История дуэлей', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: FutureBuilder<List<Duel>>(
                future: ref.read(duelProvider.notifier).loadHistory(),
                builder: (BuildContext context, AsyncSnapshot<List<Duel>> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<Duel> history = snapshot.data!;
                  if (history.isEmpty) {
                    return Center(
                      child: Text(
                        'Пока нет истории дуэлей',
                        style: TextStyle(color: semantic.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int i) {
                      final Duel d = history[i];
                      final Color color = d.won == true
                          ? AppColors.success
                          : (d.won == false ? semantic.textMuted : AppColors.streakAmber);
                      return ListTile(
                        leading: Icon(
                          d.won == true ? Icons.emoji_events_rounded : Icons.circle_outlined,
                          color: color,
                        ),
                        title: Text(d.dateKey),
                        subtitle: Text('${d.playerScore} / ${d.targetScore} против ${d.opponentName}'),
                        trailing: d.won == true ? Text('+${d.gemsReward}💎') : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
