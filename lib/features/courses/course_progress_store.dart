import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores *which lessons are ticked* on the device.
///
/// The course cache only keeps course metadata (title/instructor/lesson count)
/// and the mock backend has no progress endpoint, so completions are stored
/// separately and merged back into the course list on every load. Keeping them
/// out of the course cache means a cache write-through (or an offline read) can
/// never erase the learner's progress.
class CourseProgressStore {
  /// Public so tests can seed/inspect storage without duplicating the key.
  static const storageKeyPrefix = 'lesson_progress_v1';

  final SharedPreferences prefs;

  /// Progress is scoped per signed-in account so two users on the same device
  /// never see each other's ticks.
  final String scope;

  CourseProgressStore(this.prefs, {this.scope = 'guest'});

  String get storageKey => '${storageKeyPrefix}_$scope';

  Set<String> readCompletedLessonIds() {
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <String>{};

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<String>().toSet();
    } catch (_) {
      // Corrupt payload – start from a clean slate instead of crashing.
      return <String>{};
    }
  }

  Future<void> setCompleted(String lessonId, {required bool completed}) async {
    final ids = readCompletedLessonIds();
    if (completed) {
      ids.add(lessonId);
    } else {
      ids.remove(lessonId);
    }

    final sorted = ids.toList()..sort();
    await prefs.setString(storageKey, jsonEncode(sorted));
  }

  Future<void> clear() async {
    await prefs.remove(storageKey);
  }
}
