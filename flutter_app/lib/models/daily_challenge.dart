import 'exercise.dart';

/// A single daily challenge: one exercise the user is nudged to complete
/// each day for bonus XP. Reuses [Exercise] for the actual task shape so
/// the lesson-screen exercise widgets can render it without any special
/// casing — only the surrounding screen (streak framing, daily XP badge)
/// is unique to Daily Challenge.
///
/// Resolution order mirrors [Lesson]: cached-for-today > AI-generated
/// (via the same [AIService] fallback chain) > bundled fallback pool. A
/// challenge is pinned to a single calendar date so the same task is
/// shown all day and never regenerated until tomorrow.
class DailyChallenge {
  const DailyChallenge({
    required this.dateKey,
    required this.exercise,
    required this.topicId,
    required this.topicLabel,
    this.xpReward = 50,
    this.isAiGenerated = false,
    this.completed = false,
  });

  /// 'yyyy-MM-dd', used as both the cache key and the display anchor —
  /// one challenge per calendar day.
  final String dateKey;

  final Exercise exercise;

  /// Which topic this challenge draws from (e.g. 'python_loops'), shown
  /// as light context above the exercise ("Сегодня: Loops").
  final String topicId;
  final String topicLabel;

  final int xpReward;
  final bool isAiGenerated;
  final bool completed;

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      dateKey: json['dateKey'] as String? ?? '',
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      topicId: json['topicId'] as String? ?? '',
      topicLabel: json['topicLabel'] as String? ?? '',
      xpReward: json['xpReward'] as int? ?? 50,
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dateKey': dateKey,
        'exercise': exercise.toJson(),
        'topicId': topicId,
        'topicLabel': topicLabel,
        'xpReward': xpReward,
        'isAiGenerated': isAiGenerated,
        'completed': completed,
      };

  DailyChallenge copyWith({bool? completed}) {
    return DailyChallenge(
      dateKey: dateKey,
      exercise: exercise,
      topicId: topicId,
      topicLabel: topicLabel,
      xpReward: xpReward,
      isAiGenerated: isAiGenerated,
      completed: completed ?? this.completed,
    );
  }

  List<String> validate() {
    final List<String> errors = <String>[];
    if (dateKey.isEmpty) errors.add('DailyChallenge missing dateKey');
    if (topicId.isEmpty) errors.add('DailyChallenge missing topicId');
    final String? exError = exercise.validate();
    if (exError != null) errors.add('exercise: $exError');
    return errors;
  }

  bool get isValid => validate().isEmpty;
}
