/// Builds system/user prompts for lesson & exercise generation, and for
/// progressive hints. Kept separate from AIService so prompt engineering
/// can evolve independently of provider/networking logic.
class LessonPromptBuilder {
  const LessonPromptBuilder._();

  static const String _jsonShapeInstructions = '''
Respond with ONLY a single JSON object — no markdown, no commentary, no
code fences. The object MUST match this exact shape:

{
  "id": "string, unique slug",
  "title": "string",
  "description": "string, 1-2 sentences",
  "topicId": "string, matches the requested topic id",
  "courseId": "string, matches the requested course id",
  "difficulty": "beginner" | "intermediate" | "advanced",
  "xpReward": integer,
  "exercises": [
    {
      "id": "string, unique within lesson",
      "type": "multipleChoice" | "codeCompletion" | "findTheBug" |
              "reorderLines" | "predictOutput" | "writeCode" |
              "fixTheCode" | "matchPairs" | "practicalTask" |
              "miniChallenge",
      "question": "string",
      "difficulty": "easy" | "medium" | "hard",
      "codeSnippet": "string or null",
      "options": ["string", "..."],
      "matchPairs": [{"left": "string", "right": "string"}],
      "correctAnswer": "string or null",
      "explanation": "string, shown after the user answers",
      "hints": ["progressively more specific hint", "..."]
    }
  ]
}

Rules:
- Produce between 4 and 7 exercises, mixing at least 3 different "type"
  values — do not make every exercise multipleChoice.
- Exercises must increase in difficulty across the lesson.
- For multipleChoice / codeCompletion: "correctAnswer" must be exactly
  equal to one entry in "options".
- For reorderLines: "options" holds the shuffled lines; "correctAnswer"
  holds them newline-joined in the correct order.
- For matchPairs: fill "matchPairs" with 2-4 concept/explanation pairs
  and leave "options"/"correctAnswer" empty.
- "hints" must never simply restate the final answer — the first hint
  should nudge, later hints get progressively more specific.
- All text must be in Russian, matching the app's UI language, EXCEPT
  code identifiers, keywords, and code snippets which stay in their
  natural programming-language form.
''';

  static String lessonSystemPrompt({required String courseTitle}) {
    return '''
You are an expert curriculum designer for CodeQuest, a gamified
programming-education app similar in spirit to Duolingo. You are
generating one bite-sized lesson for the "$courseTitle" course.

$_jsonShapeInstructions
''';
  }

  static String lessonUserPrompt({
    required String courseId,
    required String courseTitle,
    required String topicId,
    required String topicTitle,
    required String difficulty,
    List<String> strugglingTopics = const <String>[],
    List<String> masteredTopics = const <String>[],
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Course: $courseTitle (courseId="$courseId")')
      ..writeln('Topic: $topicTitle (topicId="$topicId")')
      ..writeln('Target difficulty: $difficulty');

    if (strugglingTopics.isNotEmpty) {
      buffer.writeln(
        'The learner has struggled recently with: ${strugglingTopics.join(", ")}. '
        'If relevant to this topic, weave in 1-2 extra reinforcement '
        'exercises touching those concepts.',
      );
    }
    if (masteredTopics.isNotEmpty) {
      buffer.writeln(
        'The learner has already mastered: ${masteredTopics.join(", ")}. '
        'Do not waste exercises re-testing pure basics of those topics.',
      );
    }

    buffer.writeln('Generate one complete lesson JSON object now.');
    return buffer.toString();
  }

  static String hintSystemPrompt() {
    return '''
You are a patient programming tutor inside CodeQuest. The learner is
stuck on an exercise or mini-project and asked for a hint.

Respond with ONLY a JSON object: {"hint": "string"}

Rules:
- NEVER give the full solution or working code.
- Nudge them toward the next concrete step, not the final answer.
- Keep it to one or two short sentences.
- Respond in Russian.
- If "hintLevel" is high (later hint requests for the same exercise),
  you may be more specific, but still stop short of the literal answer.
''';
  }

  static String hintUserPrompt({
    required String question,
    String? codeSnippet,
    required int hintLevel,
    List<String> previousHints = const <String>[],
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Exercise/task: $question');
    if (codeSnippet != null && codeSnippet.isNotEmpty) {
      buffer.writeln('Code:\n$codeSnippet');
    }
    buffer.writeln('hintLevel: $hintLevel');
    if (previousHints.isNotEmpty) {
      buffer.writeln('Hints already given: ${previousHints.join(" | ")}');
    }
    buffer.writeln('Give the next hint now.');
    return buffer.toString();
  }

  static const String _exerciseJsonShape = '''
Respond with ONLY a single JSON object — no markdown, no commentary, no
code fences. The object MUST match this exact shape:

{
  "id": "string, unique slug",
  "type": "multipleChoice" | "codeCompletion" | "findTheBug" |
          "reorderLines" | "predictOutput" | "writeCode" |
          "fixTheCode" | "matchPairs" | "practicalTask" |
          "miniChallenge",
  "question": "string",
  "difficulty": "easy" | "medium" | "hard",
  "codeSnippet": "string or null",
  "options": ["string", "..."],
  "matchPairs": [{"left": "string", "right": "string"}],
  "correctAnswer": "string or null",
  "explanation": "string, shown after the user answers",
  "hints": ["progressively more specific hint", "..."]
}

Rules:
- For multipleChoice / codeCompletion: "correctAnswer" must be exactly
  equal to one entry in "options".
- For reorderLines: "options" holds the shuffled lines; "correctAnswer"
  holds them newline-joined in the correct order.
- For matchPairs: fill "matchPairs" with 2-4 concept/explanation pairs
  and leave "options"/"correctAnswer" empty.
- All text must be in Russian, matching the app's UI language, EXCEPT
  code identifiers, keywords, and code snippets which stay in their
  natural programming-language form.
''';

  /// System prompt for a single standalone exercise — used by Daily
  /// Challenge, which needs exactly one exercise (not a full lesson).
  static String dailyChallengeSystemPrompt() {
    return '''
You are generating today's Daily Challenge for CodeQuest, a gamified
programming-education app. Produce exactly ONE engaging, self-contained
exercise a learner can complete in 1-5 minutes.

$_exerciseJsonShape
''';
  }

  static String dailyChallengeUserPrompt({
    required String topicTitle,
    required String difficulty,
    required List<String> recentTopicLabels,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Focus topic for today: $topicTitle')
      ..writeln('Target difficulty: $difficulty');
    if (recentTopicLabels.isNotEmpty) {
      buffer.writeln(
        'The learner has recently studied: ${recentTopicLabels.join(", ")}. '
        'Prefer variety — avoid repeating yesterday\'s exact angle if possible.',
      );
    }
    buffer.writeln(
      'Favor an interesting type such as findTheBug, predictOutput, or '
      'reorderLines over a plain multipleChoice when it fits the topic.',
    );
    buffer.writeln('Generate one complete exercise JSON object now.');
    return buffer.toString();
  }
}
