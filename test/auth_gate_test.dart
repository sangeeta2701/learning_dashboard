import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/core/preferences.dart';
import 'package:learning_dashboard/features/auth/auth_repository.dart';
import 'package:learning_dashboard/features/auth/auth_session_store.dart';
import 'package:learning_dashboard/features/auth/presentation/user.dart';
import 'package:learning_dashboard/features/auth/presentation/providers/auth_provider.dart';
import 'package:learning_dashboard/features/courses/course.dart';
import 'package:learning_dashboard/features/courses/course_repository.dart';
import 'package:learning_dashboard/features/courses/presentation/providers/courses_provider.dart';
import 'package:learning_dashboard/main.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockCourseRepository extends Mock implements CourseRepository {}

const _user = User(email: 'student@learning.com', token: 'mock_token');

const _courses = [
  Course(
    id: 1,
    title: 'Python Programming',
    instructor: 'John Smith',
    lessons: [
      Lesson(id: '1_0', title: 'Introduction'),
      Lesson(id: '1_1', title: 'Variables & Data Types'),
    ],
  ),
];

void main() {
  late SharedPreferences prefs;
  late _MockAuthRepository auth;
  late _MockCourseRepository courses;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    auth = _MockAuthRepository();
    courses = _MockCourseRepository();

    when(() => courses.getCourses()).thenAnswer((_) async => _courses);
    when(
      () => courses.setLessonCompleted(any(), completed: any(named: 'completed')),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          courseRepositoryProvider.overrideWithValue(courses),
        ],
        child: const LearningDashboardApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a stored session boots straight into the dashboard',
      (tester) async {
    await AuthSessionStore(prefs).save(_user); // session left by a previous run
    when(() => auth.restoreSession()).thenReturn(_user);

    await pumpApp(tester);

    expect(find.text('My Courses'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('without a stored session the login screen is shown',
      (tester) async {
    when(() => auth.restoreSession()).thenReturn(null);

    await pumpApp(tester);

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('My Courses'), findsNothing);
  });

  testWidgets('signing in swaps the login screen for the dashboard',
      (tester) async {
    when(() => auth.restoreSession()).thenReturn(null);
    when(
      () => auth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _user);

    await pumpApp(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'student@learning.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('My Courses'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('logging out returns to the login screen', (tester) async {
    await AuthSessionStore(prefs).save(_user);
    when(() => auth.restoreSession()).thenReturn(_user);
    when(() => auth.logout()).thenAnswer((_) async {});

    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.account_circle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('My Courses'), findsNothing);
  });

  testWidgets('ticking a lesson persists it immediately', (tester) async {
    await AuthSessionStore(prefs).save(_user);
    when(() => auth.restoreSession()).thenReturn(_user);

    await pumpApp(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Introduction'));
    await tester.pumpAndSettle();

    verify(() => courses.setLessonCompleted('1_0', completed: true)).called(1);
  });
}
