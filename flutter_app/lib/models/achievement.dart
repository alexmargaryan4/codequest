/// The condition type that unlocks an achievement. Kept as a small closed
/// set evaluated by AchievementService against UserProgress; adding a new
/// achievement is a data-only change (see assets/data/achievements.json)
/// as long as its condition fits one of these existing evaluators.
enum AchievementTrigger {
  streakDays, // reach N-day streak
  lessonsCompleted, // complete N lessons total
  projectsCompleted, // complete N mini projects
  levelReached, // reach level N
  perfectLessons, // complete N lessons with no mistakes
  topicMastered, // master a specific topic
  coursesStarted, // start N different courses/languages
  custom; // reserved for future one-off logic

  static AchievementTrigger fromJson(String value) {
    return AchievementTrigger.values.firstWhere(
      (AchievementTrigger e) => e.name == value,
      orElse: () => AchievementTrigger.custom,
    );
  }

  String toJson() => name;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.trigger,
    required this.threshold,
    this.xpReward = 25,
  });

  final String id;
  final String title;
  final String description;

  /// Name of a Material icon or emoji glyph, resolved in the UI layer.
  final String iconName;

  final AchievementTrigger trigger;

  /// The numeric target for [trigger] (e.g. 7 for a 7-day streak).
  final int threshold;

  final int xpReward;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'emoji_events',
      trigger: AchievementTrigger.fromJson(json['trigger'] as String? ?? 'custom'),
      threshold: json['threshold'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 25,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'iconName': iconName,
        'trigger': trigger.toJson(),
        'threshold': threshold,
        'xpReward': xpReward,
      };
}
