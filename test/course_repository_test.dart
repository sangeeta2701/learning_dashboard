import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/core/failure.dart';
import 'package:learning_dashboard/features/courses/course_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetches from remote and writes to cache on success', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = CourseRepository(prefs);

    final courses = await repo.getCourses();

    expect(courses.length, 3);
    expect(courses.first.title, 'Python Programming');
    expect(prefs.getString('courses_cache_v1'), isNotNull);
  });

  test('falls back to cache when remote fails', () async {
    // Pre-seed the cache with one course.
    final cached = [
      {
        'id': 99,
        'title': 'Cached Course',
        'instructor': 'Cached Instructor',
        'lessons': 4,
      },
    ];
    SharedPreferences.setMockInitialValues({
      'courses_cache_v1': jsonEncode(cached),
    });
    final prefs = await SharedPreferences.getInstance();

    final repo = CourseRepository(prefs, simulateRemoteFailure: true);
    final courses = await repo.getCourses();

    expect(courses.length, 1);
    expect(courses.first.title, 'Cached Course');
    expect(courses.first.lessons.length, 4);
  });

  test('throws NetworkFailure when remote fails and cache is empty', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final repo = CourseRepository(prefs, simulateRemoteFailure: true);

    expect(() => repo.getCourses(), throwsA(isA<NetworkFailure>()));
  });
}