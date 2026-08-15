enum LearningTrack {
  programming,
  ai;

  static LearningTrack fromJson(String value) {
    return LearningTrack.values.firstWhere(
      (LearningTrack e) => e.name == value,
      orElse: () => LearningTrack.programming,
    );
  }

  String toJson() => name;
}

enum TopicNodeStatus {
  locked,
  available,
  inProgress,
  completed;

  static TopicNodeStatus fromJson(String value) {
    return TopicNodeStatus.values.firstWhere(
      (TopicNodeStatus e) => e.name == value,
      orElse: () => TopicNodeStatus.locked,
    );
  }

  String toJson() => name;
}

/// One node on the course map (e.g. "Variables", "Loops", "Mini Project").
/// A topic groups several [Lesson]s and may culminate in a [MiniProject].
class TopicNode {
  const TopicNode({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
    this.lessonIds = const <String>[],
    this.miniProjectId,
    this.prerequisiteTopicIds = const <String>[],
    this.status = TopicNodeStatus.locked,
    this.iconName = 'code',
  });

  final String id;
  final String courseId;
  final String title;
  final int orderIndex;
  final List<String> lessonIds;
  final String? miniProjectId;

  /// Topic ids that must be completed before this one unlocks. Usually
  /// just the previous node, but kept as a list to allow future branching
  /// course maps (e.g. two topics both unlocking a third).
  final List<String> prerequisiteTopicIds;

  final TopicNodeStatus status;
  final String iconName;

  factory TopicNode.fromJson(Map<String, dynamic> json) {
    return TopicNode(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      orderIndex: json['orderIndex'] as int? ?? 0,
      lessonIds: (json['lessonIds'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      miniProjectId: json['miniProjectId'] as String?,
      prerequisiteTopicIds: (json['prerequisiteTopicIds'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      status: TopicNodeStatus.fromJson(json['status'] as String? ?? 'locked'),
      iconName: json['iconName'] as String? ?? 'code',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'courseId': courseId,
        'title': title,
        'orderIndex': orderIndex,
        'lessonIds': lessonIds,
        'miniProjectId': miniProjectId,
        'prerequisiteTopicIds': prerequisiteTopicIds,
        'status': status.toJson(),
        'iconName': iconName,
      };

  TopicNode copyWith({TopicNodeStatus? status}) {
    return TopicNode(
      id: id,
      courseId: courseId,
      title: title,
      orderIndex: orderIndex,
      lessonIds: lessonIds,
      miniProjectId: miniProjectId,
      prerequisiteTopicIds: prerequisiteTopicIds,
      status: status ?? this.status,
      iconName: iconName,
    );
  }
}

/// A full course (e.g. "Python", "Prompt Engineering"). Courses live under
/// a [LearningTrack] (Programming or AI) and own an ordered list of
/// [TopicNode]s that make up the visual learning map.
class Course {
  const Course({
    required this.id,
    required this.track,
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorSeed,
    this.topics = const <TopicNode>[],
    this.isAvailable = true,
    this.comingSoon = false,
  });

  final String id;
  final LearningTrack track;
  final String title;
  final String description;
  final String iconName;

  /// Hex color string (e.g. '#4C5FD5') used to derive this course's accent
  /// color without hardcoding a Flutter Color into the data layer.
  final String colorSeed;

  final List<TopicNode> topics;

  /// Whether this course can be selected today. Kept true for the 4
  /// launch languages and the AI track; future languages can ship with
  /// isAvailable=false + comingSoon=true to appear grayed-out in the UI.
  final bool isAvailable;
  final bool comingSoon;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String? ?? '',
      track: LearningTrack.fromJson(json['track'] as String? ?? 'programming'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'code',
      colorSeed: json['colorSeed'] as String? ?? '#4C5FD5',
      topics: (json['topics'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => TopicNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      comingSoon: json['comingSoon'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'track': track.toJson(),
        'title': title,
        'description': description,
        'iconName': iconName,
        'colorSeed': colorSeed,
        'topics': topics.map((TopicNode t) => t.toJson()).toList(),
        'isAvailable': isAvailable,
        'comingSoon': comingSoon,
      };
}
