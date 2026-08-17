import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/weekly_report.dart';

final FutureProvider<WeeklyReport> weeklyReportProvider = FutureProvider<WeeklyReport>((ref) {
  return ref.watch(weeklyReportServiceProvider).buildCurrentWeekReport();
});

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WeeklyReport> reportAsync = ref.watch(weeklyReportProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Отчёт за неделю')),
      body: SafeArea(
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (WeeklyReport report) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.bolt_rounded,
                        value: '${report.xpEarned}',
                        label: 'XP за неделю',
                        color: AppColors.accentIndigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.calendar_today_rounded,
                        value: '${report.activeDays}/7',
                        label: 'Активных дней',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.menu_book_rounded,
                        value: '${report.lessonsCompleted}',
                        label: 'Уроков пройдено',
                        color: AppColors.streakAmber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.star_rounded,
                        value: '${report.perfectLessons}',
                        label: 'Идеальных уроков',
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Инсайты', style: text.titleLarge),
                const SizedBox(height: 12),
                ...report.buildInsights().asMap().entries.map((MapEntry<int, String> e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: semantic.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: semantic.border),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.lightbulb_outline_rounded,
                              size: 18, color: AppColors.streakAmber),
                          const SizedBox(width: 10),
                          Expanded(child: Text(e.value, style: text.bodyMedium)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 350.ms, delay: (80 * e.key).ms).slideX(begin: 0.05, end: 0);
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: text.titleLarge),
          Text(label, style: text.labelSmall?.copyWith(color: semantic.textMuted)),
        ],
      ),
    );
  }
}
