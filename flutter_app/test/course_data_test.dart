import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:codequest/models/course.dart';
import 'package:codequest/models/daily_challenge.dart';
import 'package:codequest/models/lesson.dart';
import 'package:codequest/models/mini_project.dart';

/// Guards against the exact class of bug that made every Daily Challenge
/// and most lessons unsolvable: bundled JSON that's either the wrong
/// shape for the file it's in (a Course object where a Lesson array was
/// expected, or vice versa) or that's shaped correctly but has a
/// `correctAnswer` that doesn't actually match any reachable option/line
/// — which no answer the user gives could ever satisfy.
///
/// This runs against the real bundled assets (not fixtures), so a future
/// content edit that reintroduces either problem fails CI immediately
/// instead of only surfacing as "the app is impossible to use" once
/// installed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const List<String> courseIds = <String>['python', 'javascript', 'dart', 'cpp', 'ai_track'];

  group('course maps (assets/data/courses/*.json)', () {
    for (final String id in courseIds) {
      testWidgets('$id.json parses as a valid Course with resolvable topic links',
          (WidgetTester tester) async {
        final String raw = await rootBundle.loadString('assets/data/courses/$id.json');
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        final Course course = Course.fromJson(decoded);

        expect(course.id, id, reason: 'Course id must match its filename');
        expect(course.topics, isNotEmpty, reason: 'Every course needs at least one topic');

        final Set<String> topicIds = course.topics.map((TopicNode t) => t.id).toSet();
        expect(topicIds.length, course.topics.length, reason: 'Topic ids must be unique');

        for (final TopicNode topic in course.topics) {
          for (final String prereq in topic.prerequisiteTopicIds) {
            expect(
              topicIds.contains(prereq),
              isTrue,
              reason: '${topic.id} references unknown prerequisite $prereq',
            );
          }
        }
      });
    }
  });

  group('bundled lesson fallback pools (assets/data/fallback_lessons/*.json)', () {
    for (final String id in courseIds) {
      testWidgets('$id.json parses as a Lesson array with solvable exercises',
          (WidgetTester tester) async {
        final String raw = await rootBundle.loadString('assets/data/fallback_lessons/$id.json');
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        expect(decoded, isNotEmpty, reason: '$id needs at least one fallback lesson');

        for (final dynamic entry in decoded) {
          final Lesson lesson = Lesson.fromJson(entry as Map<String, dynamic>);
          final List<String> errors = lesson.validate();
          expect(
            errors,
            isEmpty,
            reason: 'Lesson ${lesson.id} failed validation: ${errors.join("; ")}',
          );
        }
      });
    }
  });

  testWidgets('daily_challenges.json entries are all solvable', (WidgetTester tester) async {
    final String raw =
        await rootBundle.loadString('assets/data/fallback_lessons/daily_challenges.json');
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    expect(decoded, isNotEmpty);

    for (final dynamic entry in decoded) {
      final DailyChallenge challenge = DailyChallenge.fromJson(entry as Map<String, dynamic>);
      final List<String> errors = challenge.validate();
      expect(
        errors,
        isEmpty,
        reason: 'Daily challenge ${challenge.exercise.id} failed validation: ${errors.join("; ")}',
      );
    }
  });

  testWidgets('mini_projects.json entries are all valid', (WidgetTester tester) async {
    final String raw = await rootBundle.loadString('assets/data/fallback_lessons/mini_projects.json');
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    expect(decoded, isNotEmpty);

    for (final dynamic entry in decoded) {
      final MiniProject project = MiniProject.fromJson(entry as Map<String, dynamic>);
      final String? error = project.validate();
      expect(error, isNull, reason: 'Mini project ${project.id}: $error');
    }
  });

  group('cross-references between courses, lessons, and mini-projects', () {
    testWidgets('every topic.lessonIds entry exists in that course\'s fallback lesson pool',
        (WidgetTester tester) async {
      for (final String id in courseIds) {
        final String courseRaw = await rootBundle.loadString('assets/data/courses/$id.json');
        final Course course = Course.fromJson(jsonDecode(courseRaw) as Map<String, dynamic>);

        final String lessonsRaw =
            await rootBundle.loadString('assets/data/fallback_lessons/$id.json');
        final List<dynamic> lessonsDecoded = jsonDecode(lessonsRaw) as List<dynamic>;
        final Set<String> lessonIds = lessonsDecoded
            .map((dynamic e) => Lesson.fromJson(e as Map<String, dynamic>).id)
            .toSet();

        for (final TopicNode topic in course.topics) {
          for (final String lessonId in topic.lessonIds) {
            expect(
              lessonIds.contains(lessonId),
              isTrue,
              reason:
                  'Course "$id" topic ${topic.id} references lesson $lessonId, '
                  'which is missing from fallback_lessons/$id.json',
            );
          }
        }
      }
    });

    testWidgets('every topic.miniProjectId exists in mini_projects.json', (WidgetTester tester) async {
      final String projectsRaw =
          await rootBundle.loadString('assets/data/fallback_lessons/mini_projects.json');
      final Set<String> projectIds = (jsonDecode(projectsRaw) as List<dynamic>)
          .map((dynamic e) => MiniProject.fromJson(e as Map<String, dynamic>).id)
          .toSet();

      for (final String id in courseIds) {
        final String courseRaw = await rootBundle.loadString('assets/data/courses/$id.json');
        final Course course = Course.fromJson(jsonDecode(courseRaw) as Map<String, dynamic>);
        for (final TopicNode topic in course.topics) {
          final String? projectId = topic.miniProjectId;
          if (projectId == null) continue;
          expect(
            projectIds.contains(projectId),
            isTrue,
            reason: 'Course "$id" topic ${topic.id} references missing mini project $projectId',
          );
        }
      }
    });
  });
}
