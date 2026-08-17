import '../core/constants/xp_constants.dart';
import '../models/user_progress.dart';
import '../models/weekly_report.dart';
import '../repositories/progress_repository.dart';
import '../repositories/weekly_report_repository.dart';

/// Builds a [WeeklyReport] purely by reading existing rows — no new
/// tracking is added. XP-per-week is estimated from completed-lesson
/// counts in each window (using the same [XpRewards] constants awarded
/// at completion time) since per-day XP deltas aren't stored separately
/// from the single cumulative `total_xp` counter.
class WeeklyReportService {
  WeeklyReportService({
    required WeeklyReportRepository repository,
    required ProgressRepository progressRepository,
  })  : _repository = repository,
        _progressRepository = progressRepository;

  final WeeklyReportRepository _repository;
  final ProgressRepository _progressRepository;

  Future<WeeklyReport> buildCurrentWeekReport() async {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = todayStart.subtract(const Duration(days: 6));
    final DateTime weekEnd = todayStart.add(const Duration(days: 1));
    final DateTime prevWeekStart = weekStart.subtract(const Duration(days: 7));

    final List<(bool, DateTime)> thisWeek =
        await _repository.lessonsCompletedBetween(weekStart, weekEnd);
    final List<(bool, DateTime)> prevWeek =
        await _repository.lessonsCompletedBetween(prevWeekStart, weekStart);

    final int thisWeekXp = _estimateXp(thisWeek);
    final int prevWeekXp = _estimateXp(prevWeek);
    final int perfectCount = thisWeek.where((r) => r.$1).length;
    final Set<String> activeDayKeys = thisWeek.map((r) => _dayKey(r.$2)).toSet();

    final List<(String, int, int)> mastery = await _repository.topicMasterySummary();
    final List<(String, int, int)> withAttempts =
        mastery.where((m) => m.$3 >= 3).toList(); // ignore near-empty samples

    String? strongestId;
    double strongestAcc = 0;
    String? weakestId;
    double weakestAcc = 1;

    for (final (String topicId, int correct, int total) in withAttempts) {
      final double acc = total == 0 ? 1.0 : correct / total;
      if (acc >= strongestAcc) {
        strongestAcc = acc;
        strongestId = topicId;
      }
      if (acc <= weakestAcc) {
        weakestAcc = acc;
        weakestId = topicId;
      }
    }

    final UserProgress progress = await _progressRepository.load();

    return WeeklyReport(
      xpEarned: thisWeekXp,
      lessonsCompleted: thisWeek.length,
      perfectLessons: perfectCount,
      activeDays: activeDayKeys.length,
      strongestTopicId: strongestId,
      strongestTopicAccuracy: strongestAcc,
      weakestTopicId: weakestId,
      weakestTopicAccuracy: weakestAcc,
      currentStreak: progress.currentStreak,
      comparisonToPreviousWeek: thisWeekXp - prevWeekXp,
    );
  }

  int _estimateXp(List<(bool, DateTime)> lessons) {
    int xp = 0;
    for (final (bool wasPerfect, DateTime _) in lessons) {
      xp += XpRewards.lessonComplete;
      if (wasPerfect) xp += XpRewards.perfectLessonBonus;
    }
    return xp;
  }

  String _dayKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
