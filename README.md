# Learning Dashboard

A small, offline-capable Learning Dashboard built for the Senior Mobile App
Developer technical assignment.

**Stack:** Flutter · Riverpod · `package:http` · `shared_preferences` ·
Flutter's built-in `Navigator`.

---

## Quick start

```bash
flutter pub get
flutter run          # any device or emulator
flutter test         # runs the full test suite
flutter analyze      # should report zero issues
```

**Login:** any valid email + any password ≥ 6 characters.
Use password `wrong` to exercise the error state.

**Reset progress:** tap the ⟳ icon in the dashboard app bar. A confirmation
dialog lists the affected courses before clearing.

---

## What's in the app

| Screen | What it does |
|---|---|
| **Login** | Email + password validation, loading spinner, error banner. Mock API with 900 ms latency; `wrong` password triggers a 401. |
| **Course Dashboard** | Loads courses from the assignment's JSON. Handles **loading / success / empty / error**. Reset-progress action. Per-user account menu with logout. |
| **Course Details** | Full lesson list, tap to toggle completion. Progress bar and % update live on both the details and dashboard screens. |

**Offline:** after one successful load, restart the app with no network — the
course list is served from `SharedPreferences`.

---

## Folder structure

```
lib/
├── main.dart                         App entry, ProviderScope + prefs override
│
├── core/                             Cross-cutting concerns
│   ├── api_client.dart               http wrapper, timeouts, error mapping
│   ├── failure.dart                  Sealed Failure hierarchy
│   ├── preferences.dart              sharedPreferencesProvider (overridden in main)
│   └── validators.dart               Email + password rules
│
└── features/                         Vertical slices, one folder per feature
    ├── auth/
    │   ├── auth_gate.dart            Decides login vs dashboard on launch
    │   ├── auth_repository.dart      Mock login API
    │   ├── auth_session_store.dart   Persists the signed-in user
    │   ├── user.dart                 Signed-in user model
    │   └── presentation/
    │       ├── providers/
    │       │   └── auth_provider.dart     LoginState + LoginNotifier + session
    │       └── screens/
    │           └── login_screen.dart
    │
    └── courses/
        ├── course.dart                    Course + Lesson (with JSON parsing)
        ├── course_repository.dart         Mock fetch + SharedPreferences cache
        ├── course_progress_store.dart     Per-account lesson completion store
        └── presentation/
            ├── providers/
            │   └── courses_provider.dart  CoursesState + CoursesNotifier
            └── screens/
                ├── course_dashboard_screen.dart
                └── course_details_screen.dart

test/
├── auth_gate_test.dart                    Widget test: gate routing
├── auth_session_test.dart                 Session persist / restore / sign out
├── course_progress_test.dart              Pure logic: progressPercent
├── course_progress_persistence_test.dart  Toggle → store → reload
├── course_repository_test.dart            Remote + offline fallback
└── test_helpers.dart                      Shared test fixtures
```

The rule of thumb: **`core/` is generic, `features/` is product code.** If a
piece of logic belongs to *this app's behaviour*, it lives under a feature. If
it would survive being copied into another app untouched, it lives in `core/`.

---


## 1. Architecture

Feature-first, three layers per feature:

```
Widget  →  Riverpod Notifier  →  Repository  →  http / SharedPreferences
```

- **Widgets** render state; they never fetch or persist.
- **Notifiers** own the UI state for a screen. State is a **sealed class**
  (`CoursesLoading`, `CoursesData`, `CoursesError`, `CoursesEmpty`) so widgets
  `switch` exhaustively — this rules out the classic bug where stale data is
  shown alongside an error.
- **Repositories** talk to the network and to disk, and return plain domain
  objects.

### Why this shape (and not full Clean Architecture)

The assignment is three screens. Adding use cases and abstract repository
interfaces would mean ~10 files of pure forwarding. What actually matters for
production-readiness is:

1. **Separation of concerns** — UI never touches `http` or SharedPreferences.
2. **Testability** — progress math and the offline fallback are unit-testable
   without a widget tree.
3. **Predictable state** — sealed states mean the UI can't be in two states at
   once.
4. **Right-sized layering** — one concrete `CourseRepository`, because there's
   exactly one data path. Adding an interface later is a 10-line refactor, not
   a rewrite.

### Why Riverpod

Provider's successor by the same author. Compile-time safety, Notifiers that
are testable without widget tests, and no `BuildContext` dependency in the
state layer. GetX was deliberately avoided — its service-locator style hides
dependencies instead of surfacing them.

### Why `package:http` and `Navigator`

`http` is the minimal, official client; for a handful of endpoints it beats
Dio on clarity. Swapping to Dio is a one-file change (`core/api_client.dart`).

Three screens, one of which takes a `Course` object as an argument. Plain
`Navigator.push(MaterialPageRoute(...))` is the simplest, most readable
option. A router (go_router, auto_route) earns its keep for deep links,
nested shells, or web URLs — none of which apply here.

### Per-user state

Progress is scoped by signed-in email (`lesson_progress_v1_<email>`). Two
accounts on the same device never see each other's ticks. `AuthSessionStore`
persists the session so the user stays signed in across restarts, and
`AuthGate` routes to the correct screen on launch.

## 2. Offline support

- **Write-through course cache.** Every successful fetch is serialised to
  `courses_cache_v1` in SharedPreferences.
- **Fallback on failure.** `CourseRepository` catches remote errors and reads
  the cache. If the cache is also empty, it throws `NetworkFailure`, which the
  dashboard renders as an error state with a Retry button.
- **Cold-start offline.** Same code path runs on app restart — previously
  loaded courses stay visible.
- **Progress is persisted on every tap** (optimistically, rolled back only if
  storage rejects the write) so ticks survive backgrounding and restarts.
- **Reset is scoped:** clearing progress does *not* clear the course cache —
  offline mode keeps working after a reset.

`SharedPreferences.getInstance()` is awaited in `main()` and injected via a
Riverpod override, so every consumer stays synchronous.

## 3. Security

In production, **never** store auth tokens in SharedPreferences — it's
plaintext on disk and extractable from rooted devices and backups.

- **iOS / macOS:** Keychain Services via `flutter_secure_storage`
  (`kSecClassGenericPassword`,
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- **Android:** `EncryptedSharedPreferences` (Jetpack Security) or the
  Keystore-backed `flutter_secure_storage`, preferably with a hardware-backed
  key (`StrongBox`) on modern devices.
- **Tokens:** short-lived JWTs with silent refresh via a rotating refresh
  token. Wipe secure storage and log out if refresh fails.
- **Transport:** enforce HTTPS with certificate pinning to the API host.

## 4. Scale — 1M users, hundreds of courses

1. **Pagination + a proper local DB.** Replace SharedPreferences with **Drift**
   or **sqflite**. Fetch `/courses?cursor=…&limit=20`, store rows
   individually, and lazy-load. This is the biggest single change at scale.
2. **Incremental sync via ETags / `If-None-Match`.** On `304`, skip the
   payload. Track `lastSyncedAt` and pull only deltas — significant savings in
   data and battery.
3. **Offline write queue with idempotency keys.** Lesson completions queued
   locally and replayed on reconnect, without double-counting on retry.
4. **Observability.** Sentry / Crashlytics, structured logs, and Firebase
   Performance traces on cold-start and frame drops, with alerts on
   regressions.
5. **Backend-for-frontend.** A dedicated BFF keeps mobile payloads small and
   stable, decoupled from internal service churn.

## 5. Second platform (Android → iOS)

The architecture maps 1:1 to SwiftUI:

| Flutter | SwiftUI |
|---|---|
| Riverpod `Notifier` | `@Observable` class (iOS 17+) or `ObservableObject` |
| `ProviderScope` | `@EnvironmentObject` / `.environment(…)` |
| `package:http` | `URLSession` + `async/await` |
| SharedPreferences | `UserDefaults` (or Core Data / `SQLite.swift` at scale) |
| `flutter_secure_storage` | Keychain via `SecItemAdd` |
| `Navigator.push` | `NavigationStack` + `navigationDestination` |
| Sealed `UiState` classes | Swift `enum UiState { case loading, empty, data([Course]), error(String) }` |

Same layering (`View → Notifier → Repository → Remote + Local`), same test
coverage ported to `XCTest`, same offline strategy. The only structural
difference is SwiftUI's property-wrapper-driven dependency injection replacing
Riverpod's `ProviderScope`.

---

## Testing

```bash
flutter test
```

| File | What it covers |
|---|---|
| `course_progress_test.dart` | Progress math, edge cases (zero lessons, rounding) |
| `course_repository_test.dart` | Remote success → cache write; remote failure → cache read; empty cache → `NetworkFailure` |
| `course_progress_persistence_test.dart` | Toggle a lesson → write through store → read back |
| `auth_session_test.dart` | Sign in persists; sign out clears; corrupt payload recovers |
| `auth_gate_test.dart` | Widget test: gate routes to login vs dashboard |

---

## Design trade-offs

- **Mock API ships a lesson *count*, not a list.** `Course.fromJson` generates
  placeholder lesson titles (`Introduction`, `Variables & Data Types`, …). A
  real backend would expose `GET /courses/{id}/lessons` — the swap is a
  one-file change inside `course_repository.dart`.
- **Progress is intentionally separate from the course cache.** A "reset
  progress" action clears only `lesson_progress_v1_<email>`; the course list
  in `courses_cache_v1` survives, so offline mode keeps working after a reset.
- **No use cases / abstract interfaces.** One implementation each. Adding the
  abstraction now is ceremony. When a second data source appears, extracting
  the interface is mechanical.
- **SharedPreferences for the cache.** Correct for three courses. Moving to
  Drift is a one-file change inside `CourseRepository` — the Notifier and UI
  don't know the difference.

---

*Assignment submission — not licensed for redistribution.*