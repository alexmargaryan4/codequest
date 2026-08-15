import '../models/lesson.dart';
import '../models/user_progress.dart';

/// Decides what difficulty (and which reinforcement topics) the next
/// generated lesson should target, based on the user's tracked mastery.
///
/// This is intentionally a small, pure, easily-testable class: given a
/// [UserProgress] and a target topic, it returns a [AdaptivePlan] that
/// [LessonGenerator]'s prompt builder consumes. All the "smart" behavior
/// described in the product spec (extra practice on weak topics, skip
/// trivial questions on mastered ones) flows through here.
class AdaptivePlan {
  const AdaptivePlan({
    required this.difficulty,
    required this.reinforceTopics,
    required this.skipBasicsFor,
  });

  /// 'beginner' | 'intermediate' | 'advanced'
  final String difficulty;

  /// Topic ids the generated lesson should weave in extra practice for.
  final List<String> reinforceTopics;

  /// Topic ids the learner has already mastered — the prompt builder uses
  /// this to avoid serving trivially easy questions on them.
  final List<String> skipBasicsFor;
}

class AdaptiveEngine {
  const AdaptiveEngine();

  AdaptivePlan planFor({
    required UserProgress progress,
    required String topicId,
    required LessonDifficulty baseDifficulty,
  }) {
    final List<String> struggling = progress.strugglingTopics;
    final List<String> mastered = progress.masteredTopics;

    // If the learner is actively struggling with THIS topic specifically,
    // don't escalate difficulty — hold steady or step back one notch.
    final bool strugglingHere = struggling.contains(topicId);
    final String difficulty = strugglingHere
        ? 'beginner'
        : baseDifficulty.name;

    return AdaptivePlan(
      difficulty: difficulty,
      reinforceTopics: struggling.take(3).toList(),
      skipBasicsFor: mastered.take(5).toList(),
    );
  }

  /// Suggests extra "reinforcement" topic ids that deserve a follow-up
  /// lesson even though the learner has technically moved past them on
  /// the course map — used by the Daily Challenge selector and by the
  /// "Practice weak topics" home-screen prompt.
  List<String> suggestReinforcementTopics(UserProgress progress, {int limit = 3}) {
    final List<String> struggling = List<String>.from(progress.strugglingTopics);
    struggling.sort((String a, String b) {
      final double accA = progress.topicMastery[a]?.accuracy ?? 1.0;
      final double accB = progress.topicMastery[b]?.accuracy ?? 1.0;
      return accA.compareTo(accB); // weakest first
    });
    return struggling.take(limit).toList();
  }
}
