# learning_dashboard

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Persisted state (survives restart / background kill)

Everything that must outlive the process is written through `SharedPreferences`
and read back during boot, so the app never re-asks for information it already
has.

| What | Where | Key |
| --- | --- | --- |
| Auth session (who is signed in) | `lib/features/auth/auth_session_store.dart` | `auth_session_v1` |
| Lesson ticks (per account) | `lib/features/courses/course_progress_store.dart` | `lesson_progress_v1_<email>` |
| Course list cache (offline fallback) | `lib/features/courses/course_repository.dart` | `courses_cache_v1` |

- `sharedPreferencesProvider` (`lib/core/preferences.dart`) hands the single
  `SharedPreferences` instance to the app and is overridden in `main()`.
- `AuthGate` (`lib/features/auth/presentation/auth_gate.dart`) watches
  `authSessionProvider` and routes to the dashboard or the login screen — no
  imperative navigation, so a restored session boots straight into the
  dashboard.
- Lesson ticks live in a store **separate** from the course cache, so
  refreshing the list (or reading it offline) can never wipe progress. Every
  checkbox tap is persisted immediately; the UI updates optimistically first
  and rolls back if the write fails.
- Progress is scoped per signed-in account (`lesson_progress_v1_<email>`), so
  two users sharing a device never see each other's ticks.

### Tests

```
flutter test
```

- `test/auth_session_test.dart` – session persistence and logout.
- `test/course_progress_persistence_test.dart` – ticks survive an online and an
  offline relaunch, and are not erased by a refresh.
- `test/auth_gate_test.dart` – widget level routing: restored session skips
  login, login/logout swap screens, ticking a lesson persists immediately.

