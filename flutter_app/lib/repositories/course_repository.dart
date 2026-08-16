import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import '../models/course.dart';
import '../models/user_progress.dart';

/// Loads static course/topic-map definitions from assets/data/courses and
/// resolves each topic's live [TopicNodeStatus] against the user's
/// [UserProgress] (completed topics -> completed, first incomplete with
/// satisfied prerequisites -> available, everything else -> locked).
///
/// Course maps are simple bundled JSON today. Swapping this for a remote
/// CMS or backend later only requires changing [_loadRawCourses].
class CourseRepository {
  CourseRepository();

  List<Course>? _rawCache;

  static const List<String> _courseFiles = <String>[
    'python',
    'javascript',
    'dart',
    'cpp',
    'ai_track',
  ];

  Future<List<Course>> _loadRawCourses() async {
    if (_rawCache != null) return _rawCache!;
    final List<Course> courses = <Course>[];
    for (final String file in _courseFiles) {
      try {
        final String raw = await rootBundle.loadString('assets/data/courses/$file.json');
        final Course course = Course.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (course.topics.isEmpty) {
          // A Course with zero topics almost always means the file was
          // shaped wrong (e.g. a Lesson[] array parsed leniently into an
          // empty Course rather than throwing) rather than an
          // intentionally topic-less course. Surface it loudly instead of
          // silently dropping the course from the list — this is exactly
          // the failure mode that made 4 of 5 courses vanish previously.
          debugPrint(
            'CourseRepository: "$file.json" parsed with zero topics — '
            'check that assets/data/courses/$file.json is a Course object '
            '(not a Lesson[] array) and still adding it to the list so the '
            'UI surfaces the problem instead of hiding the course.',
          );
        }
        courses.add(course);
      } catch (e, st) {
        // Missing or malformed course file. This used to fail silently,
        // which is exactly how 4 of the 5 courses disappeared from the
        // course list with no error anywhere — the JSON for those
        // courses was actually a Lesson[] array (fallback-lesson shape)
        // living under the wrong filename, Course.fromJson threw while
        // parsing 'topics', and this catch swallowed it. Logging now so
        // a future data-file mixup is visible in debug output instead of
        // silently shrinking the course list.
        debugPrint('CourseRepository: failed to load "$file.json": $e\n$st');
      }
    }
    _rawCache = courses;
    return courses;
  }

  Future<List<Course>> getCoursesForTrack(LearningTrack track) async {
    final List<Course> all = await _loadRawCourses();
    return all.where((Course c) => c.track == track).toList();
  }

  Future<Course?> getCourse(String courseId) async {
    final List<Course> all = await _loadRawCourses();
    try {
      return all.firstWhere((Course c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  /// Finds whichever bundled course owns the topic with [topicId].
  /// Used by [ProgressService] to resolve a topic's full lesson/project
  /// list from just a topicId, without every caller needing to also
  /// thread a courseId through.
  Future<Course?> getCourseForTopic(String topicId) async {
    final List<Course> all = await _loadRawCourses();
    for (final Course course in all) {
      if (course.topics.any((TopicNode t) => t.id == topicId)) {
        return course;
      }
    }
    return null;
  }

  /// Returns [course] with every topic's status resolved against
  /// [progress]: completed topics marked completed, the first
  /// not-yet-completed topic whose prerequisites are all satisfied marked
  /// available, everything else locked.
  Course resolveStatuses(Course course, UserProgress progress) {
    final List<TopicNode> resolved = <TopicNode>[];
    bool foundAvailable = false;

    final List<TopicNode> ordered = List<TopicNode>.from(course.topics)
      ..sort((TopicNode a, TopicNode b) => a.orderIndex.compareTo(b.orderIndex));

    for (final TopicNode topic in ordered) {
      if (progress.completedTopicIds.contains(topic.id)) {
        resolved.add(topic.copyWith(status: TopicNodeStatus.completed));
        continue;
      }

      final bool prereqsMet = topic.prerequisiteTopicIds.isEmpty ||
          topic.prerequisiteTopicIds.every(progress.completedTopicIds.contains);

      if (prereqsMet && !foundAvailable) {
        resolved.add(topic.copyWith(status: TopicNodeStatus.available));
        foundAvailable = true;
      } else if (prereqsMet) {
        // Prereqs met but an earlier topic is still the "current" one —
        // still shown as available so users can jump around within
        // already-unlocked territory, matching common learning-app UX.
        resolved.add(topic.copyWith(status: TopicNodeStatus.available));
      } else {
        resolved.add(topic.copyWith(status: TopicNodeStatus.locked));
      }
    }

    return Course(
      id: course.id,
      track: course.track,
      title: course.title,
      description: course.description,
      iconName: course.iconName,
      colorSeed: course.colorSeed,
      topics: resolved,
      isAvailable: course.isAvailable,
      comingSoon: course.comingSoon,
    );
  }
}
