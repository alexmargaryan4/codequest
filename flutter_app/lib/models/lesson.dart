import 'exercise.dart';

enum LessonDifficulty {
  beginner,
  intermediate,
  advanced;

  static LessonDifficulty fromJson(String value) {
    return LessonDifficulty.values.firstWhere(
      (LessonDifficulty e) => e.name == value,
      orElse: () => LessonDifficulty.beginner,
    );
  }

  String toJson() => name;
}

enum LessonStatus {
  locked,
  available,
  inProgress,
  completed;

  static LessonStatus fromJson(String value) {
    return LessonStatus.values.firstWhere(
      (LessonStatus e) => e.name == value,
      orElse: () => LessonStatus.locked,
    );
  }

  String toJson() => name;
}

/// A single lesson: a short sequence of exercises around one topic node
/// on the course map (e.g. "Variables", "Conditions").
///
/// This is the structured shape that BOTH AI-generated content and
/// hand-authored fallback content must conform to. [validate] is run on
/// every AI response before the lesson is ever shown to the user.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.topicId,
    required this.courseId,
    required this.difficulty,
    required this.exercises,
    this.status = LessonStatus.locked,
    this.orderIndex = 0,
    this.xpReward = 30,
    this.isAiGenerated = false,
    this.generatedAt,
  });

  final String id;
  final String title;
  final String description;

  /// The topic/node id this lesson belongs to on the course map
  /// (e.g. 'python_variables').
  final String topicId;

  /// The parent course id (e.g. 'python').
  final String courseId;

  final LessonDifficulty difficulty;
  final List<Exercise> exercises;
  final LessonStatus status;

  /// Position of this lesson within its topic's lesson list.
  final int orderIndex;

  final int xpReward;

  /// True if this lesson came from OpenAI/Groq rather than the bundled
  /// fallback content. Used by the cache layer and by adaptive difficulty.
  final bool isAiGenerated;
  final DateTime? generatedAt;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      difficulty: LessonDifficulty.fromJson(json['difficulty'] as String? ?? 'beginner'),
      exercises: (json['exercises'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: LessonStatus.fromJson(json['status'] as String? ?? 'locked'),
      orderIndex: json['orderIndex'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 30,
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'topicId': topicId,
        'courseId': courseId,
        'difficulty': difficulty.toJson(),
        'exercises': exercises.map((Exercise e) => e.toJson()).toList(),
        'status': status.toJson(),
        'orderIndex': orderIndex,
        'xpReward': xpReward,
        'isAiGenerated': isAiGenerated,
        'generatedAt': generatedAt?.toIso8601String(),
      };

  Lesson copyWith({LessonStatus? status}) {
    return Lesson(
      id: id,
      title: title,
      description: description,
      topicId: topicId,
      courseId: courseId,
      difficulty: difficulty,
      exercises: exercises,
      status: status ?? this.status,
      orderIndex: orderIndex,
      xpReward: xpReward,
      isAiGenerated: isAiGenerated,
      generatedAt: generatedAt,
    );
  }

  /// Validates structural integrity of an (often AI-generated) lesson.
  /// Returns a list of problems; empty list means the lesson is safe to
  /// show to the user.
  List<String> validate() {
    final List<String> errors = <String>[];
    if (id.isEmpty) errors.add('Lesson missing id');
    if (title.isEmpty) errors.add('Lesson missing title');
    if (topicId.isEmpty) errors.add('Lesson missing topicId');
    if (courseId.isEmpty) errors.add('Lesson missing courseId');
    if (exercises.isEmpty) errors.add('Lesson has no exercises');

    for (int i = 0; i < exercises.length; i++) {
      final String? exError = exercises[i].validate();
      if (exError != null) {
        errors.add('Exercise[$i]: $exError');
      }
    }
    return errors;
  }

  bool get isValid => validate().isEmpty;

  /// Value equality keyed on [id]. lessonSessionProvider is a
  /// StateNotifierProvider.family keyed by a Lesson instance — without
  /// this override, two Lesson objects loaded for the same lesson id (e.g.
  /// after lessonProvider is re-read) would compare unequal by identity
  /// and silently spin up a second, fresh session instead of reusing the
  /// in-progress one.
  @override
  bool operator ==(Object other) => other is Lesson && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
