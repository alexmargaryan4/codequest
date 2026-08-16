import 'package:flutter_test/flutter_test.dart';

import 'package:codequest/features/course_map/application/map_node_resolver.dart';
import 'package:codequest/models/course.dart';
import 'package:codequest/models/user_progress.dart';

/// Covers the course-map bug: a topic that bundles several lessons and a
/// mini-project must render and navigate as independent nodes, each with
/// its own id/status, resolved straight from [UserProgress]'s
/// per-lesson/per-project completion sets — never from a per-topic
/// rollup, and never by re-deriving "the next thing to open" at tap time.
///
/// The fixture below mirrors the exact shape used by every bundled course
/// (see assets/data/courses/*.json): a mini-project is referenced both as
/// metadata on the lesson-topic that leads into it AND as its own
/// dedicated, lesson-less topic further down the list — the shape that
/// originally caused duplicate/circular resolution if not handled
/// explicitly (see [resolveMapNodes]'s `dedicatedProjectTopicProjectIds`).
void main() {
  const Course course = Course(
    id: 'python',
    track: LearningTrack.programming,
    title: 'Python',
    description: '',
    iconName: 'code',
    colorSeed: '#4C5FD5',
    topics: <TopicNode>[
      TopicNode(
        id: 'topic_1',
        courseId: 'python',
        title: 'Lesson 1 Topic',
        orderIndex: 0,
        lessonIds: <String>['lesson_1'],
      ),
      TopicNode(
        id: 'topic_2',
        courseId: 'python',
        title: 'Lesson 2 Topic',
        orderIndex: 1,
        lessonIds: <String>['lesson_2'],
        prerequisiteTopicIds: <String>['topic_1'],
      ),
      TopicNode(
        id: 'topic_3',
        courseId: 'python',
        title: 'Lesson 3 Topic',
        orderIndex: 2,
        lessonIds: <String>['lesson_3'],
        // Redundant metadata mirroring the real course JSON shape: this
        // topic references the same project id its dedicated successor
        // topic owns. Must NOT cause the project to render twice, and
        // must NOT make "topic_3 fully done" require the project too.
        miniProjectId: 'project_1',
        prerequisiteTopicIds: <String>['topic_2'],
      ),
      TopicNode(
        id: 'topic_project_1',
        courseId: 'python',
        title: 'Mini Project',
        orderIndex: 3,
        miniProjectId: 'project_1',
        prerequisiteTopicIds: <String>['topic_3'],
      ),
      TopicNode(
        id: 'topic_4',
        courseId: 'python',
        title: 'Lesson 4 Topic',
        orderIndex: 4,
        lessonIds: <String>['lesson_4'],
        prerequisiteTopicIds: <String>['topic_project_1'],
      ),
    ],
  );

  /// Second mini-project further down the path, used by the
  /// "multiple mini-projects" scenario. Built by appending to [course]'s
  /// topic list rather than duplicating the whole fixture.
  Course courseWithSecondProject() {
    return Course(
      id: course.id,
      track: course.track,
      title: course.title,
      description: course.description,
      iconName: course.iconName,
      colorSeed: course.colorSeed,
      topics: <TopicNode>[
        ...course.topics,
        const TopicNode(
          id: 'topic_5',
          courseId: 'python',
          title: 'Lesson 5 Topic',
          orderIndex: 5,
          lessonIds: <String>['lesson_5'],
          miniProjectId: 'project_2',
          prerequisiteTopicIds: <String>['topic_4'],
        ),
        const TopicNode(
          id: 'topic_project_2',
          courseId: 'python',
          title: 'Mini Project',
          orderIndex: 6,
          miniProjectId: 'project_2',
          prerequisiteTopicIds: <String>['topic_5'],
        ),
      ],
    );
  }

  MapNode nodeById(List<MapNode> nodes, String id) =>
      nodes.firstWhere((MapNode n) => n.id == id, orElse: () => throw StateError('missing $id'));

  group('lesson completion unlocks the mini-project, not the reverse', () {
    test('Scenario 1: completing the last lesson before a mini-project marks it completed '
        'and unlocks (but does not complete) the mini-project', () {
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1', 'lesson_2', 'lesson_3'},
      );

      final List<MapNode> nodes = resolveMapNodes(course, progress);

      final MapNode lesson3 = nodeById(nodes, 'lesson_3');
      expect(lesson3.status, MapNodeStatus.completed, reason: 'Lesson 3 must show as completed');

      final MapNode project = nodeById(nodes, 'project_1');
      expect(project.type, MapNodeType.miniProject);
      expect(
        project.status,
        MapNodeStatus.available,
        reason: 'Mini project must unlock once its prerequisite lessons are done',
      );
      // Unlocking must not double as completion.
      expect(project.isCompleted, isFalse);

      // Exactly one node for the project — no duplicate from the
      // redundant miniProjectId metadata on topic_3.
      expect(nodes.where((MapNode n) => n.id == 'project_1').length, 1);

      // Lesson 4 stays locked: it depends on the *project* being done,
      // not merely unlocked.
      expect(nodeById(nodes, 'lesson_4').status, MapNodeStatus.locked);
    });

    test('mini-project is locked before its prerequisite lessons are complete', () {
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1', 'lesson_2'}, // lesson_3 NOT done
      );

      final List<MapNode> nodes = resolveMapNodes(course, progress);

      expect(nodeById(nodes, 'lesson_3').status, MapNodeStatus.available);
      expect(nodeById(nodes, 'project_1').status, MapNodeStatus.locked);
    });
  });

  group('tap behavior is derived purely from node id/type/status', () {
    test('Scenario 2: a completed lesson node is not interactive (tapping it is a no-op)', () {
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1', 'lesson_2', 'lesson_3'},
      );
      final List<MapNode> nodes = resolveMapNodes(course, progress);

      final MapNode lesson3 = nodeById(nodes, 'lesson_3');
      expect(lesson3.isCompleted, isTrue);
      expect(
        lesson3.isInteractive,
        isFalse,
        reason: 'Completed lessons must not be tappable to reopen/replay',
      );
    });

    test('Scenario 3: an unlocked mini-project node is interactive on its own id', () {
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1', 'lesson_2', 'lesson_3'},
      );
      final List<MapNode> nodes = resolveMapNodes(course, progress);

      final MapNode project = nodeById(nodes, 'project_1');
      expect(project.isInteractive, isTrue);
      expect(project.type, MapNodeType.miniProject);
    });

    test('Scenario 5: a completed mini-project node is not interactive', () {
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1', 'lesson_2', 'lesson_3'},
        completedProjectIds: <String>{'project_1'},
      );
      final List<MapNode> nodes = resolveMapNodes(course, progress);

      final MapNode project = nodeById(nodes, 'project_1');
      expect(project.isCompleted, isTrue);
      expect(project.isInteractive, isFalse);
    });

    test('a locked lesson node is not interactive', () {
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1'},
      );
      final List<MapNode> nodes = resolveMapNodes(course, progress);

      final MapNode lesson3 = nodeById(nodes, 'lesson_3');
      expect(lesson3.status, MapNodeStatus.locked);
      expect(lesson3.isInteractive, isFalse);
    });
  });

  group('mini-project completion unlocks the next lesson', () {
    test('Scenario 4: completing the mini-project marks it completed and unlocks lesson 4', () {
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1', 'lesson_2', 'lesson_3'},
        completedProjectIds: <String>{'project_1'},
      );
      final List<MapNode> nodes = resolveMapNodes(course, progress);

      expect(nodeById(nodes, 'project_1').status, MapNodeStatus.completed);
      expect(
        nodeById(nodes, 'lesson_4').status,
        MapNodeStatus.available,
        reason: 'Lesson 4 unlocks once its prerequisite mini-project is completed',
      );
    });
  });

  group('Scenario 6: resolution is a pure function of persisted UserProgress', () {
    test('re-resolving with the same persisted progress after a simulated restart '
        'reproduces the exact same completed/unlocked state', () {
      final UserProgress persisted = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1', 'lesson_2', 'lesson_3'},
        totalXp: 90,
      );

      // "Restart" = build a fresh UserProgress from the same data (as
      // ProgressRepository.load() would after re-reading SQLite) and
      // resolve again.
      final UserProgress reloaded = UserProgress.fromJson(persisted.toJson());
      final List<MapNode> nodes = resolveMapNodes(course, reloaded);

      expect(nodeById(nodes, 'lesson_3').status, MapNodeStatus.completed);
      expect(nodeById(nodes, 'project_1').status, MapNodeStatus.available);
      expect(reloaded.totalXp, 90);
    });
  });

  group('Scenario 7: multiple mini-projects only depend on their own prerequisites', () {
    test('completing the first mini-project does not unlock or complete the second', () {
      final Course multi = courseWithSecondProject();
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{'lesson_1', 'lesson_2', 'lesson_3'},
        completedProjectIds: <String>{'project_1'},
      );

      final List<MapNode> nodes = resolveMapNodes(multi, progress);

      expect(nodeById(nodes, 'project_1').status, MapNodeStatus.completed);
      // lesson_4 (which only depends on project_1) unlocks...
      expect(nodeById(nodes, 'lesson_4').status, MapNodeStatus.available);
      // ...but lesson_5 and project_2, further down the chain, must stay
      // locked: they depend on lesson_4 and project_1 being far more
      // thoroughly completed than they are here.
      expect(nodeById(nodes, 'lesson_5').status, MapNodeStatus.locked);
      expect(nodeById(nodes, 'project_2').status, MapNodeStatus.locked);
    });

    test('finishing every lesson up to project 2 unlocks project 2 without touching project 1',
        () {
      final Course multi = courseWithSecondProject();
      final UserProgress progress = const UserProgress().copyWith(
        completedLessonIds: <String>{
          'lesson_1',
          'lesson_2',
          'lesson_3',
          'lesson_4',
          'lesson_5',
        },
        completedProjectIds: <String>{'project_1'},
      );

      final List<MapNode> nodes = resolveMapNodes(multi, progress);

      expect(nodeById(nodes, 'project_1').status, MapNodeStatus.completed);
      expect(nodeById(nodes, 'project_2').status, MapNodeStatus.available);
      expect(nodeById(nodes, 'project_2').isCompleted, isFalse);
    });
  });

  test('each lesson and mini-project id appears at most once, never merged or reused', () {
    final UserProgress progress = const UserProgress().copyWith(
      completedLessonIds: <String>{'lesson_1', 'lesson_2', 'lesson_3'},
      completedProjectIds: <String>{'project_1'},
    );
    final List<MapNode> nodes = resolveMapNodes(course, progress);

    final List<String> ids = nodes.map((MapNode n) => n.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'No id should be duplicated across nodes');

    // Every lesson id is its own node, distinct from the project id.
    expect(nodeById(nodes, 'lesson_3').id, isNot(equals('project_1')));
  });
}
