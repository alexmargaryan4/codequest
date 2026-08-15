import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/progress_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/leaderboard_entry.dart';
import '../../../models/user_progress.dart';

/// Two leaderboards — XP/Level and Streak — per the product spec. Backed
/// today by [LeaderboardRepository], which is purely local/simulated
/// since there is no backend; the repository's interface is already
/// shaped like a real API call so swapping in a backend later doesn't
/// touch this screen (see LeaderboardRepository doc comment).
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лидерборд'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'XP'),
            Tab(text: '🔥 Streak'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          _LeaderboardList(type: LeaderboardType.xp),
          _LeaderboardList(type: LeaderboardType.streak),
        ],
      ),
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  const _LeaderboardList({required this.type});
  final LeaderboardType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProgress> progressAsync = ref.watch(userProgressProvider);
    final AsyncValue<String> usernameAsync = ref.watch(usernameProvider);

    return progressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
      data: (UserProgress progress) {
        final String username = usernameAsync.valueOrNull ?? 'Student';
        return FutureBuilder<List<LeaderboardEntry>>(
          future: ref.watch(leaderboardRepositoryProvider).topEntries(
                type: type,
                currentUser: progress,
                currentUsername: username,
              ),
          builder: (BuildContext context, AsyncSnapshot<List<LeaderboardEntry>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<LeaderboardEntry> entries = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                return _LeaderboardTile(
                  rank: index + 1,
                  entry: entries[index],
                  type: type,
                ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.04, end: 0);
              },
            );
          },
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.rank, required this.entry, required this.type});

  final int rank;
  final LeaderboardEntry entry;
  final LeaderboardType type;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final TextTheme text = Theme.of(context).textTheme;
    final bool isTop3 = rank <= 3;

    final Color rankColor = switch (rank) {
      1 => const Color(0xFFE8B339),
      2 => const Color(0xFFB7BDC7),
      3 => const Color(0xFFCB8A5E),
      _ => semantic.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? AppColors.accentIndigo.withValues(alpha: 0.10) : semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: entry.isCurrentUser ? AppColors.accentIndigo.withValues(alpha: 0.4) : semantic.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: (isTop3 ? text.titleMedium : text.bodyMedium)?.copyWith(
                color: rankColor,
                fontWeight: isTop3 ? FontWeight.w800 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accentIndigo.withValues(alpha: 0.15),
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: text.labelLarge?.copyWith(color: AppColors.accentIndigo),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.isCurrentUser ? '${entry.username} (ты)' : entry.username,
                  style: text.titleSmall,
                ),
                Text('Level ${entry.level}', style: text.labelSmall?.copyWith(color: semantic.textMuted)),
              ],
            ),
          ),
          if (type == LeaderboardType.xp)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accentIndigo),
                const SizedBox(width: 4),
                Text(_formatXp(entry.totalXp), style: text.labelLarge),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.local_fire_department_rounded, size: 16, color: semantic.streak),
                const SizedBox(width: 4),
                Text('${entry.streak}', style: text.labelLarge),
              ],
            ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      final double thousands = xp / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}k';
    }
    return '$xp';
  }
}
