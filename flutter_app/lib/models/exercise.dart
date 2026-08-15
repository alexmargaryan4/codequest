/// The 10 exercise interaction types supported by the lesson engine.
/// Adding a new type: add an enum value here, a matching widget in
/// features/exercises/presentation/widgets, and a case in
/// ExerciseWidgetFactory. Nothing else needs to change.
enum ExerciseType {
  multipleChoice,
  codeCompletion,
  findTheBug,
  reorderLines,
  predictOutput,
  writeCode,
  fixTheCode,
  matchPairs,
  practicalTask,
  miniChallenge;

  static ExerciseType fromJson(String value) {
    return ExerciseType.values.firstWhere(
      (ExerciseType e) => e.name == value,
      orElse: () => ExerciseType.multipleChoice,
    );
  }

  String toJson() => name;
}

enum ExerciseDifficulty {
  easy,
  medium,
  hard;

  static ExerciseDifficulty fromJson(String value) {
    return ExerciseDifficulty.values.firstWhere(
      (ExerciseDifficulty e) => e.name == value,
      orElse: () => ExerciseDifficulty.easy,
    );
  }

  String toJson() => name;
}

/// A single pair for matchPairs-type exercises (concept <-> explanation).
class MatchPair {
  const MatchPair({required this.left, required this.right});

  final String left;
  final String right;

  factory MatchPair.fromJson(Map<String, dynamic> json) {
    return MatchPair(
      left: json['left'] as String? ?? '',
      right: json['right'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'left': left, 'right': right};
}

/// A single exercise/question within a lesson.
///
/// Not every field is used by every [ExerciseType]:
/// - multipleChoice / codeCompletion: options + correctAnswer
/// - findTheBug / fixTheCode / writeCode: codeSnippet + correctAnswer (or
///   an acceptable-answer pattern) + explanation
/// - reorderLines: options holds the shuffled lines, correctAnswer holds
///   them in the correct order (joined by '\n' or as an ordered list re-join)
/// - predictOutput: codeSnippet + correctAnswer (the printed output)
/// - matchPairs: matchPairs holds the pairs to connect
/// - practicalTask / miniChallenge: prompt-driven, no single correctAnswer;
///   graded qualitatively (see MiniProject for the full-project version)
class Exercise {
  const Exercise({
    required this.id,
    required this.type,
    required this.question,
    required this.difficulty,
    this.codeSnippet,
    this.options = const <String>[],
    this.matchPairs = const <MatchPair>[],
    this.correctAnswer,
    this.explanation = '',
    this.hints = const <String>[],
  });

  final String id;
  final ExerciseType type;
  final String question;
  final ExerciseDifficulty difficulty;

  /// Code shown to the user, if any (findTheBug, predictOutput, etc).
  final String? codeSnippet;

  /// Answer choices (multipleChoice, codeCompletion) or shuffled lines
  /// (reorderLines).
  final List<String> options;

  /// Pairs to connect, only for [ExerciseType.matchPairs].
  final List<MatchPair> matchPairs;

  /// The correct answer. Interpretation depends on [type]:
  /// - multipleChoice/codeCompletion: must equal one of [options]
  /// - reorderLines: the lines in correct order, '\n'-joined
  /// - predictOutput: exact expected stdout
  /// - findTheBug: the line or token containing the bug
  /// - writeCode/fixTheCode: a reference solution (used for AI-assisted
  ///   soft grading, not strict string equality)
  final String? correctAnswer;

  final String explanation;

  /// Progressive hints — index 0 shown first, then increasingly specific.
  /// Never reveals the full solution outright (see hint escalation logic
  /// in HintService).
  final List<String> hints;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      type: ExerciseType.fromJson(json['type'] as String? ?? 'multipleChoice'),
      question: json['question'] as String? ?? '',
      difficulty: ExerciseDifficulty.fromJson(json['difficulty'] as String? ?? 'easy'),
      codeSnippet: json['codeSnippet'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      matchPairs: (json['matchPairs'] as List<dynamic>?)
              ?.map((dynamic e) => MatchPair.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MatchPair>[],
      correctAnswer: json['correctAnswer'] as String?,
      explanation: json['explanation'] as String? ?? '',
      hints: (json['hints'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.toJson(),
        'question': question,
        'difficulty': difficulty.toJson(),
        'codeSnippet': codeSnippet,
        'options': options,
        'matchPairs': matchPairs.map((MatchPair p) => p.toJson()).toList(),
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'hints': hints,
      };

  /// Basic structural validation used before an AI-generated exercise is
  /// ever shown to the user. Returns a human-readable error, or null if
  /// valid.
  String? validate() {
    if (id.isEmpty) return 'Exercise missing id';
    if (question.isEmpty) return 'Exercise missing question';

    switch (type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.codeCompletion:
        if (options.length < 2) return 'Needs at least 2 options';
        if (correctAnswer == null || !options.contains(correctAnswer)) {
          return 'correctAnswer must be one of options';
        }
      case ExerciseType.reorderLines:
        if (options.length < 2) return 'Needs at least 2 lines to reorder';
        if (correctAnswer == null || correctAnswer!.isEmpty) {
          return 'Missing correct order';
        }
      case ExerciseType.matchPairs:
        if (matchPairs.length < 2) return 'Needs at least 2 pairs';
      case ExerciseType.findTheBug:
      case ExerciseType.predictOutput:
      case ExerciseType.fixTheCode:
        if (codeSnippet == null || codeSnippet!.isEmpty) {
          return 'Missing codeSnippet';
        }
        if (correctAnswer == null || correctAnswer!.isEmpty) {
          return 'Missing correctAnswer';
        }
      case ExerciseType.writeCode:
      case ExerciseType.practicalTask:
      case ExerciseType.miniChallenge:
        // Open-ended: only question is strictly required.
        break;
    }
    return null;
  }

  bool get isValid => validate() == null;
}
