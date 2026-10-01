import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learning_dashboard/core/failure.dart';
import 'package:learning_dashboard/core/preferences.dart';
import 'package:learning_dashboard/features/auth/presentation/providers/auth_provider.dart';
import 'package:learning_dashboard/features/courses/course.dart';
import 'package:learning_dashboard/features/courses/course_progress_store.dart';
import 'package:learning_dashboard/features/courses/course_repository.dart';

/// Lesson ticks are stored per signed-in account, so two users sharing a device
/// never see each other's progress.
final courseProgressStoreProvider = Provider<CourseProgressStore>((ref) {
  final session = ref.watch(authSessionProvider);
  final scope = switch (session) {
    AuthSessionSignedIn(:final user) => user.email,
    _ => 'guest',
  };

  return CourseProgressStore(
    ref.watch(sharedPreferencesProvider),
    scope: scope,
  );
});

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => CourseRepository(
    ref.watch(sharedPreferencesProvider),
    progressStore: ref.watch(courseProgressStoreProvider),
  ),
);

sealed class CoursesState {
  const CoursesState();
}

class CoursesLoading extends CoursesState {
  const CoursesLoading();
}

class CoursesEmpty extends CoursesState {
  const CoursesEmpty();
}

class CoursesData extends CoursesState {
  final List<Course> courses;
  const CoursesData(this.courses);
}

class CoursesError extends CoursesState {
  final String message;
  const CoursesError(this.message);
}

class CoursesNotifier extends Notifier<CoursesState> {
  @override
  CoursesState build() {
    Future.microtask(load);
    return const CoursesLoading();
  }

  Future<void> load() async {
    state = const CoursesLoading();
    try {
      final courses = await ref.read(courseRepositoryProvider).getCourses();
      state = courses.isEmpty ? const CoursesEmpty() : CoursesData(courses);
    } on Failure catch (f) {
      state = CoursesError(f.message);
    } catch (e) {
      state = CoursesError('Unexpected error: $e');
    }
  }

  /// Flips a lesson and persists it right away.
  Future<void> toggleLesson(int courseId, String lessonId) async {
    final current = state;
    if (current is! CoursesData) return;

    final lesson = _findLesson(current.courses, courseId, lessonId);
    if (lesson == null) return;

    final nextCompleted = !lesson.completed;
    _writeLesson(courseId, lessonId, completed: nextCompleted);

    try {
      await ref
          .read(courseRepositoryProvider)
          .setLessonCompleted(lessonId, completed: nextCompleted);
    } catch (_) {
      // Storage rejected the write – undo the optimistic tick.
      _writeLesson(courseId, lessonId, completed: lesson.completed);
    }
  }

  /// Clears every saved lesson tick for the current account and rebuilds the
  /// in-memory state so both the dashboard and details screens update at once.
  ///
  /// The cached *course list* is intentionally kept – only progress is reset.
  Future<void> resetProgress() async {
    await ref.read(courseProgressStoreProvider).clear();

    final current = state;
    if (current is! CoursesData) return;

    final reset = current.courses
        .map(
          (c) => c.copyWith(
            lessons: [
              for (final l in c.lessons) l.copyWith(completed: false),
            ],
          ),
        )
        .toList();

    state = CoursesData(reset);
  }

  void _writeLesson(
    int courseId,
    String lessonId, {
    required bool completed,
  }) {
    final current = state;
    if (current is! CoursesData) return;

    final updated = current.courses.map((c) {
      if (c.id != courseId) return c;
      final lessons = c.lessons
          .map((l) => l.id == lessonId ? l.copyWith(completed: completed) : l)
          .toList();
      return c.copyWith(lessons: lessons);
    }).toList();

    state = CoursesData(updated);
  }

  static Lesson? _findLesson(
    List<Course> courses,
    int courseId,
    String lessonId,
  ) {
    for (final course in courses) {
      if (course.id != courseId) continue;
      for (final lesson in course.lessons) {
        if (lesson.id == lessonId) return lesson;
      }
    }
    return null;
  }
}

final coursesProvider =
    NotifierProvider<CoursesNotifier, CoursesState>(CoursesNotifier.new);