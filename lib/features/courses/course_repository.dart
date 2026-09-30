// Handles the mock remote fetch, the SharedPreferences cache, the offline
// fallback and the locally persisted lesson progress (which is what makes the
// tick marks survive a restart or a background kill).
import 'dart:convert';

import 'package:learning_dashboard/core/failure.dart';
import 'package:learning_dashboard/features/courses/course_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'course.dart';


class CourseRepository {
  static const _cacheKey = 'courses_cache_v1';

  final SharedPreferences prefs;

  final bool simulateRemoteFailure;

  /// Where lesson ticks live. Kept *outside* the course cache so that a
  /// write-through of the course list (or an offline read) can never erase them.
  final CourseProgressStore progressStore;

  CourseRepository(
    this.prefs, {
    this.simulateRemoteFailure = false,
    CourseProgressStore? progressStore,
  }) : progressStore = progressStore ?? CourseProgressStore(prefs);

  static const _mockJson = '''
  [
    {"id": 1, "title": "Python Programming", "instructor": "John Smith", "progress": 65, "lessons": 20},
    {"id": 2, "title": "Generative AI", "instructor": "Sarah Williams", "progress": 40, "lessons": 16},
    {"id": 3, "title": "Full Stack Development", "instructor": "David Brown", "progress": 25, "lessons": 28}
  ]
  ''';

  Future<List<Course>> getCourses() async {
    try {
      // ---- Mock remote fetch ----
      await Future.delayed(const Duration(milliseconds: 700));
      if (simulateRemoteFailure) {
        throw const NetworkFailure();
      }

      final decoded = jsonDecode(_mockJson) as List<dynamic>;
      final courses = _mergeLocalProgress(
        decoded.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList(),
      );

      // Write-through cache (metadata only – progress lives in its own store).
      await prefs.setString(
        _cacheKey,
        jsonEncode(courses.map((c) => c.toJson()).toList()),
      );

      return courses;
    } on Failure {
      return _readCache();
    } catch (_) {
      return _readCache();
    }
  }

  /// Persists a single lesson tick.
  ///
  /// Called on every checkbox tap so nothing is lost if the OS kills the app
  /// while it sits in the background.
  Future<void> setLessonCompleted(
    String lessonId, {
    required bool completed,
  }) {
    return progressStore.setCompleted(lessonId, completed: completed);
  }

  List<Course> _readCache() {
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      throw const NetworkFailure(
        'No internet and no cached courses available.',
      );
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return _mergeLocalProgress(
        decoded.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (_) {
      // Corrupt cache — treat as empty.
      throw const NetworkFailure(
        'No internet and no cached courses available.',
      );
    }
  }

  /// Re-applies the locally stored ticks on top of whatever the backend (or the
  /// cache) returned.
  ///
  /// Local progress always wins: the mock backend answers with lesson *counts*
  /// only, so without this merge a restart or a pull-to-refresh would silently
  /// reset the learner's progress to 0%.
  List<Course> _mergeLocalProgress(List<Course> courses) {
    final completed = progressStore.readCompletedLessonIds();
    if (completed.isEmpty) return courses;

    return courses
        .map(
          (course) => course.copyWith(
            lessons: course.lessons
                .map(
                  (lesson) =>
                      lesson.copyWith(completed: completed.contains(lesson.id)),
                )
                .toList(),
          ),
        )
        .toList();
  }
}