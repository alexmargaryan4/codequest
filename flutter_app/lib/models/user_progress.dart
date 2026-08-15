import '../core/constants/xp_constants.dart';

/// Per-topic mastery tracking used by the adaptive difficulty engine.
/// One row per topicId, updated after every exercise attempt.
class TopicMastery {
  const TopicMastery({
    required this.topicId,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.totalAttempts = 0,
    this.hintsUsed = 0,
    this.totalTimeSeconds = 0,
    this.lastPracticedAt,
  });

  final String topicId;
  final int correctCount;
  final int incorrectCount;
  final int totalAttempts;
  final int hintsUsed;
  final int totalTimeSeconds;
  final DateTime? lastPracticedAt;

  /// Accuracy in [0, 1]. Returns 1.0 for untouched topics so they don't
  /// look artificially "weak" before any attempt has been made.
  double get accuracy {
    if (totalAttempts == 0) return 1.0;
    return correctCount / totalAttempts;
  }

  /// Heuristic used by the adaptive engine to flag a topic as "struggling":
  /// low accuracy AND a meaningful number of attempts (avoids overreacting
  /// to a single unlucky guess).
  bool get isStruggling => totalAttempts >= 3 && accuracy < 0.6;

  /// Heuristic for "already mastered" — used to avoid serving trivially
  /// easy questions on topics the user has clearly internalized.
  bool get isMastered => totalAttempts >= 5 && accuracy >= 0.85;

  TopicMastery recordAttempt({
    required bool wasCorrect,
    required bool usedHint,
    required int timeSeconds,
  }) {
    return TopicMastery(
      topicId: topicId,
      correctCount: correctCount + (wasCorrect ? 1 : 0),
      incorrectCount: incorrectCount + (wasCorrect ? 0 : 1),
      totalAttempts: totalAttempts + 1,
      hintsUsed: hintsUsed + (usedHint ? 1 : 0),
      totalTimeSeconds: totalTimeSeconds + timeSeconds,
      lastPracticedAt: DateTime.now(),
    );
  }

  factory TopicMastery.fromJson(Map<String, dynamic> json) {
    return TopicMastery(
      topicId: json['topicId'] as String? ?? '',
      correctCount: json['correctCount'] as int? ?? 0,
      incorrectCount: json['incorrectCount'] as int? ?? 0,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
      lastPracticedAt: json['lastPracticedAt'] != null
          ? DateTime.tryParse(json['lastPracticedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'topicId': topicId,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'totalAttempts': totalAttempts,
        'hintsUsed': hintsUsed,
        'totalTimeSeconds': totalTimeSeconds,
        'lastPracticedAt': lastPracticedAt?.toIso8601String(),
      };
}

/// The single source of truth for a user's overall progress. Persisted in
/// SQLite (see core/storage) and updated by ProgressRepository.
class UserProgress {
  const UserProgress({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.lessonsCompleted = 0,
    this.projectsCompleted = 0,
    this.completedLessonIds = const <String>{},
    this.completedTopicIds = const <String>{},
    this.completedProjectIds = const <String>{},
    this.unlockedAchievementIds = const <String>{},
    this.topicMastery = const <String, TopicMastery>{},
    this.activeCourseId = 'python',
  });

  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int lessonsCompleted;
  final int projectsCompleted;
  final Set<String> completedLessonIds;
  final Set<String> completedTopicIds;
  final Set<String> completedProjectIds;
  final Set<String> unlockedAchievementIds;
  final Map<String, TopicMastery> topicMastery;
  final String activeCourseId;

  int get level => LevelThresholds.levelForXp(totalXp);

  (int current, int needed) get levelProgress =>
      LevelThresholds.progressWithinLevel(totalXp);

  List<String> get strugglingTopics => topicMastery.values
      .where((TopicMastery m) => m.isStruggling)
      .map((TopicMastery m) => m.topicId)
      .toList();

  List<String> get masteredTopics => topicMastery.values
      .where((TopicMastery m) => m.isMastered)
      .map((TopicMastery m) => m.topicId)
      .toList();

  UserProgress copyWith({
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? lessonsCompleted,
    int? projectsCompleted,
    Set<String>? completedLessonIds,
    Set<String>? completedTopicIds,
    Set<String>? completedProjectIds,
    Set<String>? unlockedAchievementIds,
    Map<String, TopicMastery>? topicMastery,
    String? activeCourseId,
  }) {
    return UserProgress(
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      projectsCompleted: projectsCompleted ?? this.projectsCompleted,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      completedTopicIds: completedTopicIds ?? this.completedTopicIds,
      completedProjectIds: completedProjectIds ?? this.completedProjectIds,
      unlockedAchievementIds: unlockedAchievementIds ?? this.unlockedAchievementIds,
      topicMastery: topicMastery ?? this.topicMastery,
      activeCourseId: activeCourseId ?? this.activeCourseId,
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalXp: json['totalXp'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.tryParse(json['lastActivityDate'] as String)
          : null,
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      projectsCompleted: json['projectsCompleted'] as int? ?? 0,
      completedLessonIds: ((json['completedLessonIds'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toSet(),
      completedTopicIds: ((json['completedTopicIds'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toSet(),
      completedProjectIds: ((json['completedProjectIds'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toSet(),
      unlockedAchievementIds:
          ((json['unlockedAchievementIds'] as List<dynamic>?) ?? const <dynamic>[])
              .map((dynamic e) => e.toString())
              .toSet(),
      topicMastery: (json['topicMastery'] as Map<String, dynamic>? ?? const <String, dynamic>{})
          .map((String k, dynamic v) =>
              MapEntry<String, TopicMastery>(k, TopicMastery.fromJson(v as Map<String, dynamic>))),
      activeCourseId: json['activeCourseId'] as String? ?? 'python',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': lastActivityDate?.toIso8601String(),
        'lessonsCompleted': lessonsCompleted,
        'projectsCompleted': projectsCompleted,
        'completedLessonIds': completedLessonIds.toList(),
        'completedTopicIds': completedTopicIds.toList(),
        'completedProjectIds': completedProjectIds.toList(),
        'unlockedAchievementIds': unlockedAchievementIds.toList(),
        'topicMastery': topicMastery.map(
          (String k, TopicMastery v) => MapEntry<String, dynamic>(k, v.toJson()),
        ),
        'activeCourseId': activeCourseId,
      };
}
