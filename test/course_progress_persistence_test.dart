import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/features/courses/course_progress_store.dart';
import 'package:learning_dashboard/features/courses/course_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CourseProgressStore', () {
    test('persists completed lesson ids across a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = CourseProgressStore(prefs);

      await store.setCompleted('1_0', completed: true);
      await store.setCompleted('1_2', completed: true);

      final restarted = CourseProgressStore(await simulateAppRestart(prefs));

      expect(restarted.readCompletedLessonIds(), containsAll(['1_0', '1_2']));
    });

    test('un-checking a lesson removes it again', () async {
      SharedPreferences.setMockInitialValues({});
      final store = CourseProgressStore(await SharedPreferences.getInstance());

      await store.setCompleted('1_0', completed: true);
      await store.setCompleted('1_0', completed: false);

      expect(store.readCompletedLessonIds(), isEmpty);
    });

    test('progress is scoped per account', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final alice = CourseProgressStore(prefs, scope: 'alice@x.com');
      final bob = CourseProgressStore(prefs, scope: 'bob@x.com');

      await alice.setCompleted('1_0', completed: true);

      expect(alice.readCompletedLessonIds(), contains('1_0'));
      expect(bob.readCompletedLessonIds(), isEmpty);
    });

    test('ignores a corrupt payload instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        '${CourseProgressStore.storageKeyPrefix}_guest': 'not-json',
      });
      final store = CourseProgressStore(await SharedPreferences.getInstance());

      expect(store.readCompletedLessonIds(), isEmpty);
    });
  });

  group('CourseRepository', () {
    test('lesson ticks survive an app restart (online mode)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = CourseRepository(prefs);

      final courses = await repo.getCourses();
      final first = courses.first;
      await repo.setLessonCompleted(first.lessons.first.id, completed: true);
      await repo.setLessonCompleted(first.lessons[1].id, completed: true);

      // Kill the app in the background and reopen it.
      final restarted = CourseRepository(await simulateAppRestart(prefs));
      final reloaded = await restarted.getCourses();

      expect(reloaded.first.completedLessons, 2);
      expect(reloaded.first.lessons.first.completed, isTrue);
      expect(reloaded.first.lessons[2].completed, isFalse);
      // 2 of 20 lessons.
      expect(reloaded.first.progressPercent, 10);
    });

    test('lesson ticks survive an offline launch (remote down, cache used)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final online = CourseRepository(prefs);
      final courses = await online.getCourses(); // fills the cache

      await online.setLessonCompleted(
        courses[1].lessons.first.id,
        completed: true,
      );

      final offline = CourseRepository(
        await simulateAppRestart(prefs),
        simulateRemoteFailure: true,
      );
      final cached = await offline.getCourses();

      expect(cached[1].completedLessons, 1);
      expect(cached[1].lessons.first.completed, isTrue);
      expect(cached.first.completedLessons, 0);
    });

    test('refreshing from the backend does not wipe stored ticks', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = CourseRepository(prefs);

      final courses = await repo.getCourses();
      await repo.setLessonCompleted(
        courses.first.lessons.first.id,
        completed: true,
      );

      // A manual refresh / pull-to-refresh re-fetches from the backend.
      final refreshed = await repo.getCourses();

      expect(refreshed.first.completedLessons, 1);
      expect(refreshed.first.lessons.first.completed, isTrue);
    });
  });
}
