/// The countable metric a [WeeklyQuest] tracks. Each maps to a counter
/// the app already increments elsewhere (exercise attempts, lessons,
/// perfect lessons, XP, mini-projects) so quest progress can be derived
/// from existing events with no new instrumentation.
enum QuestMetric {
  exercisesSolved,
  lessonsCompleted,
  perfectLessons,
  xpEarned,
  projectsCompleted;

  static QuestMetric fromJson(String value) {
    return QuestMetric.values.firstWhere(
      (QuestMetric e) => e.name == value,
      orElse: () => QuestMetric.exercisesSolved,
    );
  }

  String toJson() => name;

  String get label => switch (this) {
        QuestMetric.exercisesSolved => 'реши упражнений',
        QuestMetric.lessonsCompleted => 'заверши уроков',
        QuestMetric.perfectLessons => 'заверши уроков без ошибок',
        QuestMetric.xpEarned => 'набери XP',
        QuestMetric.projectsCompleted => 'заверши мини-проектов',
      };
}

/// One goal within the current week's quest set (e.g. "Reshi 20 exercises
/// this week"). A fixed pool of quest templates is rotated weekly by
/// [WeeklyQuestRepository] — no AI/network dependency, since these are
/// meant to be always available, including fully offline.
class WeeklyQuest {
  const WeeklyQuest({
    required this.id,
    required this.weekKey,
    required this.metric,
    required this.target,
    required this.progress,
    required this.gemsReward,
    required this.xpReward,
    this.completed = false,
    this.claimedAt,
  });

  /// Stable id for this quest template (e.g. 'solve_20_exercises'),
  /// combined with [weekKey] to form the storage primary key.
  final String id;

  /// ISO week anchor, 'yyyy-Www' (e.g. '2026-W33') — identifies which
  /// week this quest instance belongs to, so a fresh set is generated
  /// once the week rolls over.
  final String weekKey;

  final QuestMetric metric;
  final int target;
  final int progress;
  final int gemsReward;
  final int xpReward;
  final bool completed;

  /// Set once the reward has been claimed, to avoid double-awarding if
  /// the quest screen is reopened.
  final DateTime? claimedAt;

  bool get isClaimed => claimedAt != null;
  double get progressRatio => target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  String get title => '${metric.label} ($target)';

  WeeklyQuest copyWith({
    int? progress,
    bool? completed,
    DateTime? claimedAt,
  }) {
    return WeeklyQuest(
      id: id,
      weekKey: weekKey,
      metric: metric,
      target: target,
      progress: progress ?? this.progress,
      gemsReward: gemsReward,
      xpReward: xpReward,
      completed: completed ?? this.completed,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  factory WeeklyQuest.fromJson(Map<String, dynamic> json) {
    return WeeklyQuest(
      id: json['id'] as String? ?? '',
      weekKey: json['weekKey'] as String? ?? '',
      metric: QuestMetric.fromJson(json['metric'] as String? ?? 'exercisesSolved'),
      target: json['target'] as int? ?? 1,
      progress: json['progress'] as int? ?? 0,
      gemsReward: json['gemsReward'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      claimedAt:
          json['claimedAt'] != null ? DateTime.tryParse(json['claimedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'weekKey': weekKey,
        'metric': metric.toJson(),
        'target': target,
        'progress': progress,
        'gemsReward': gemsReward,
        'xpReward': xpReward,
        'completed': completed,
        'claimedAt': claimedAt?.toIso8601String(),
      };
}
