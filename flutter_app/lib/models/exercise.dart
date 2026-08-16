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
  ///
  /// Beyond presence checks, this also verifies that [correctAnswer] is
  /// actually *reachable* by the interaction the exercise offers — e.g.
  /// for [ExerciseType.reorderLines] the correct order must be some
  /// permutation of [options], and for [ExerciseType.findTheBug] the
  /// flagged line must literally appear in [codeSnippet]. Without these
  /// checks, an AI response can look structurally fine (every field
  /// present, right shape) while still being unsolvable: the model
  /// paraphrases `correctAnswer` slightly differently than the line/
  /// option text it was derived from, so no tap or drag the user makes
  /// can ever match it. That previously slipped through as a "valid"
  /// exercise and always graded as wrong no matter what the user did.
  String? validate() {
    if (id.isEmpty) return 'Exercise missing id';
    if (question.isEmpty) return 'Exercise missing question';

    switch (type) {
      case ExerciseType.multipleChoice:
      case ExerciseType.codeCompletion:
        if (options.length < 2) return 'Needs at least 2 options';
        final String normalizedCorrect = (correctAnswer ?? '').trim();
        final bool matches =
            options.any((String o) => o.trim() == normalizedCorrect);
        if (normalizedCorrect.isEmpty || !matches) {
          return 'correctAnswer must be exactly equal to one of options';
        }
      case ExerciseType.reorderLines:
        if (options.length < 2) return 'Needs at least 2 lines to reorder';
        if (correctAnswer == null || correctAnswer!.trim().isEmpty) {
          return 'Missing correct order';
        }
        final List<String> optionLines =
            options.map((String o) => o.trim()).toList()..sort();
        final List<String> correctLines =
            correctAnswer!.split('\n').map((String l) => l.trim()).toList()
              ..sort();
        if (!_sameElements(optionLines, correctLines)) {
          return 'correctAnswer must be a reordering of the exact lines in options';
        }
      case ExerciseType.matchPairs:
        if (matchPairs.length < 2) return 'Needs at least 2 pairs';
        if (matchPairs.any((MatchPair p) => p.left.trim().isEmpty || p.right.trim().isEmpty)) {
          return 'matchPairs entries must not be empty';
        }
      case ExerciseType.findTheBug:
        if (codeSnippet == null || codeSnippet!.isEmpty) {
          return 'Missing codeSnippet';
        }
        if (correctAnswer == null || correctAnswer!.trim().isEmpty) {
          return 'Missing correctAnswer';
        }
        final List<String> codeLines =
            codeSnippet!.split('\n').map((String l) => l.trim()).toList();
        if (!codeLines.contains(correctAnswer!.trim())) {
          return 'correctAnswer must be exactly one of the lines in codeSnippet';
        }
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

  /// True if [a] and [b] contain the same elements with the same
  /// multiplicity, ignoring order. Used to confirm a reorderLines
  /// `correctAnswer` is a genuine permutation of `options` rather than
  /// a paraphrase that happens to have the same line count.
  static bool _sameElements(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool get isValid => validate() == null;
}
