import '../../../models/course.dart';
import '../../../models/user_progress.dart';

/// The kind of content a [MapNode] points to. Kept distinct from
/// [TopicNode]/[TopicNodeStatus] on purpose: a topic groups several
/// lessons and (optionally) a mini-project under one prerequisite chain,
/// but each lesson and each mini-project is its own completable thing
/// with its own id and its own status. Collapsing them onto a single
/// per-topic node/status was the root cause of a class of bugs where
/// finishing the last lesson in a topic didn't show as completed and
/// tapping it opened the topic's mini-project instead.
enum MapNodeType { lesson, miniProject }

/// Status of a single map node. Mirrors [LessonStatus]/[MiniProjectStatus]
/// (which already model this correctly) rather than the coarser
/// [TopicNodeStatus], since the map now renders and navigates at
/// lesson/project granularity.
enum MapNodeStatus { locked, available, inProgress, completed }

/// One tappable entity on the course map: either a single lesson or a
/// single mini-project. Never both — a lesson and its topic's
/// mini-project are always distinct [MapNode]s with distinct ids and
/// independently resolved statuses, even though they may render as
/// neighboring dots on the same visual path.
class MapNode {
  const MapNode({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.courseId,
    required this.topicId,
    required this.topicIconName,
    this.isFirstInTopic = false,
  });

  /// Stable id of the underlying lesson or mini-project — NEVER a list
  /// index. This is what navigation and completion are keyed on.
  final String id;
  final MapNodeType type;
  final MapNodeStatus status;

  /// Display label. For lessons this is the parent topic's title (today
  /// every topic has at most one lesson, but resolution below supports
  /// several); for mini-projects it's a fixed "Mini Project" style label
  /// supplied by the caller.
  final String title;

  final String courseId;

  /// The [TopicNode] this node was expanded from. A lesson keeps its
  /// owning topic's id so lesson-completion can still report back into
  /// [ProgressService.completeLesson]/`_maybeCompleteTopic` exactly as
  /// before; a mini-project node uses its own topic in the same way.
  final String topicId;

  final String topicIconName;

  /// True for the first lesson expanded from a given topic. Used only to
  /// decide which node "represents" the topic's icon on the path; has no
  /// effect on status or navigation.
  final bool isFirstInTopic;

  bool get isLocked => status == MapNodeStatus.locked;
  bool get isCompleted => status == MapNodeStatus.completed;
  bool get isInteractive => status == MapNodeStatus.available || status == MapNodeStatus.inProgress;
}

/// Expands a course's [TopicNode]s into an ordered list of independent
/// [MapNode]s (one per lesson, plus one per mini-project) and resolves
/// each one's status directly from [UserProgress]'s per-lesson/per-project
/// completion sets — never from the topic-level rollup, and never by
/// re-deriving "the next thing to open" at tap time.
///
/// Unlock rules, matching the product spec:
///  - A lesson unlocks once every lesson before it *within its own topic*
///    is completed AND the topic's own prerequisite topics are fully
///    completed (every lesson + mini-project in each of them).
///  - A topic's mini-project unlocks only once every lesson in that same
///    topic is completed. Unlocking is NOT completion — a freshly
///    unlocked mini-project is `available`, not `completed`.
///  - Completing topic N's mini-project (or topic N having no
///    mini-project) is a prerequisite for topic N+1's first lesson,
///    matching [TopicNode.prerequisiteTopicIds] semantics.
List<MapNode> resolveMapNodes(Course course, UserProgress progress) {
  final List<TopicNode> topics = List<TopicNode>.from(course.topics)
    ..sort((TopicNode a, TopicNode b) => a.orderIndex.compareTo(b.orderIndex));

  // Bundled course data sometimes models a mini-project two ways at
  // once: (a) as metadata (`miniProjectId`) tacked onto the lesson topic
  // that leads into it, AND (b) as its own dedicated, lesson-less topic
  // further down the list (lessonIds: [], same miniProjectId) that is
  // the actual node meant to appear on the map. When both exist for the
  // same project id, (b) is the canonical owner — it has its own
  // orderIndex/prerequisiteTopicIds placing it correctly on the path —
  // and (a)'s reference is skipped so the project renders exactly once
  // instead of twice.
  final Set<String> dedicatedProjectTopicProjectIds = <String>{
    for (final TopicNode t in topics)
      if (t.lessonIds.isEmpty && t.miniProjectId != null) t.miniProjectId!,
  };

  final List<MapNode> nodes = <MapNode>[];
  bool foundAvailable = false;

  // A topic counts its mini-project toward "fully done" only when this
  // topic is that project's canonical owner (see
  // dedicatedProjectTopicProjectIds above). Otherwise `miniProjectId` is
  // just leftover metadata ("this cluster leads into project X", whose
  // own dedicated topic is what actually gates on completion), and
  // treating it as a hard requirement here would make that project's own
  // prerequisite chain circular — completing conditions requires
  // completing greeting, which requires conditions to be a satisfied
  // prerequisite.
  bool topicFullyDone(TopicNode topic) {
    final bool lessonsDone = topic.lessonIds.every(progress.completedLessonIds.contains);
    final bool topicOwnsItsProject =
        topic.lessonIds.isEmpty || !dedicatedProjectTopicProjectIds.contains(topic.miniProjectId);
    final bool projectDone = topic.miniProjectId == null ||
        !topicOwnsItsProject ||
        progress.completedProjectIds.contains(topic.miniProjectId);
    return lessonsDone && projectDone;
  }

  for (final TopicNode topic in topics) {
    final bool prereqTopicsDone =
        topic.prerequisiteTopicIds.isEmpty || topic.prerequisiteTopicIds.every((String id) {
          // A prerequisite topic counts as done only once ALL of its own
          // lessons and its mini-project (if any) are completed — not
          // merely "unlocked" or "opened".
          TopicNode? prereq;
          for (final TopicNode t in topics) {
            if (t.id == id) {
              prereq = t;
              break;
            }
          }
          if (prereq == null) return progress.completedTopicIds.contains(id);
          return topicFullyDone(prereq);
        });

    // Lessons within this topic, in order.
    bool priorLessonsInTopicDone = true;
    for (int i = 0; i < topic.lessonIds.length; i++) {
      final String lessonId = topic.lessonIds[i];
      final bool isDone = progress.completedLessonIds.contains(lessonId);

      MapNodeStatus status;
      if (isDone) {
        status = MapNodeStatus.completed;
      } else if (prereqTopicsDone && priorLessonsInTopicDone && !foundAvailable) {
        status = MapNodeStatus.available;
        foundAvailable = true;
      } else if (prereqTopicsDone && priorLessonsInTopicDone) {
        // Already-unlocked territory the user can freely revisit, same
        // relaxed rule resolveStatuses() applies at the topic level.
        status = MapNodeStatus.available;
      } else {
        status = MapNodeStatus.locked;
      }

      nodes.add(
        MapNode(
          id: lessonId,
          type: MapNodeType.lesson,
          status: status,
          title: topic.title,
          courseId: topic.courseId,
          topicId: topic.id,
          topicIconName: topic.iconName,
          isFirstInTopic: i == 0,
        ),
      );

      if (!isDone) priorLessonsInTopicDone = false;
    }

    // This topic's mini-project, if it has one — always its own node,
    // never merged with a lesson's id/status. Skip emitting it here if
    // this topic merely *references* a project that a later dedicated,
    // lesson-less topic actually owns (see
    // dedicatedProjectTopicProjectIds above) — that dedicated topic will
    // emit the node itself, in its own correct position on the path.
    final String? projectId = topic.miniProjectId;
    final bool ownsThisProjectNode =
        topic.lessonIds.isEmpty || !dedicatedProjectTopicProjectIds.contains(projectId);
    if (projectId != null && ownsThisProjectNode) {
      final bool allLessonsDone = topic.lessonIds.every(progress.completedLessonIds.contains);
      final bool isDone = progress.completedProjectIds.contains(projectId);

      MapNodeStatus status;
      if (isDone) {
        status = MapNodeStatus.completed;
      } else if (prereqTopicsDone && allLessonsDone && !foundAvailable) {
        status = MapNodeStatus.available;
        foundAvailable = true;
      } else if (prereqTopicsDone && allLessonsDone) {
        status = MapNodeStatus.available;
      } else {
        status = MapNodeStatus.locked;
      }

      nodes.add(
        MapNode(
          id: projectId,
          type: MapNodeType.miniProject,
          status: status,
          title: 'Mini Project',
          courseId: topic.courseId,
          topicId: topic.id,
          topicIconName: 'project',
        ),
      );
    }
  }

  return nodes;
}
