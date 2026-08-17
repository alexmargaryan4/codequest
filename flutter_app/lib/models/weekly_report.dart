/// A computed (not persisted) summary of the last 7 days of activity,
/// derived from existing `completed_lessons` / `topic_mastery` /
/// `user_progress` rows. Nothing new is tracked to build this — it's a
/// read-only rollup, regenerated fresh each time the report is opened.
class WeeklyReport {
  const WeeklyReport({
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.perfectLessons,
    required this.activeDays,
    required this.strongestTopicId,
    required this.strongestTopicAccuracy,
    required this.weakestTopicId,
    required this.weakestTopicAccuracy,
    required this.currentStreak,
    required this.comparisonToPreviousWeek,
  });

  final int xpEarned;
  final int lessonsCompleted;
  final int perfectLessons;

  /// Distinct calendar days with at least one completed lesson, 0-7.
  final int activeDays;

  final String? strongestTopicId;
  final double strongestTopicAccuracy;
  final String? weakestTopicId;
  final double weakestTopicAccuracy;
  final int currentStreak;

  /// XP this week minus XP the week before — positive means improving.
  final int comparisonToPreviousWeek;

  bool get hasAnyActivity => lessonsCompleted > 0 || xpEarned > 0;

  /// Short, varied "insight" lines the report screen renders as a list.
  /// Kept here (rather than inline in the widget) so the logic that
  /// decides which insights are worth showing stays testable and
  /// independent of layout.
  List<String> buildInsights() {
    final List<String> insights = <String>[];

    if (!hasAnyActivity) {
      insights.add('На этой неделе пока не было активности — самое время начать!');
      return insights;
    }

    if (activeDays >= 6) {
      insights.add('Ты занимался $activeDays из 7 дней — отличная стабильность!');
    } else if (activeDays >= 3) {
      insights.add('Ты занимался $activeDays из 7 дней на этой неделе.');
    } else {
      insights.add('Всего $activeDays ${_daysWord(activeDays)} активности — попробуй заходить почаще.');
    }

    if (comparisonToPreviousWeek > 0) {
      insights.add('На $comparisonToPreviousWeek XP больше, чем на прошлой неделе — рост!');
    } else if (comparisonToPreviousWeek < 0) {
      insights.add('На ${-comparisonToPreviousWeek} XP меньше, чем на прошлой неделе.');
    }

    if (perfectLessons > 0) {
      insights.add('$perfectLessons ${_lessonsWord(perfectLessons)} пройдено без единой ошибки.');
    }

    if (weakestTopicId != null && weakestTopicAccuracy < 0.7) {
      insights.add('Стоит повторить тему «$weakestTopicId» — точность там пока ${(weakestTopicAccuracy * 100).round()}%.');
    }

    if (strongestTopicId != null && strongestTopicAccuracy >= 0.85) {
      insights.add('Тема «$strongestTopicId» даётся легко — точность ${(strongestTopicAccuracy * 100).round()}%.');
    }

    return insights;
  }

  static String _daysWord(int n) {
    if (n == 1) return 'день';
    if (n >= 2 && n <= 4) return 'дня';
    return 'дней';
  }

  static String _lessonsWord(int n) {
    if (n == 1) return 'урок';
    if (n >= 2 && n <= 4) return 'урока';
    return 'уроков';
  }
}
