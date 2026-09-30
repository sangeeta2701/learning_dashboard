import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/core/failure.dart';
import 'package:learning_dashboard/features/auth/auth_repository.dart';
import 'package:learning_dashboard/features/auth/auth_session_store.dart';
import 'package:learning_dashboard/features/auth/presentation/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthSessionStore', () {
    test('returns null when no session was ever saved', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AuthSessionStore(await SharedPreferences.getInstance());

      expect(store.read(), isNull);
    });

    test('round-trips a user through storage', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AuthSessionStore(await SharedPreferences.getInstance());

      await store.save(const User(email: 'a@b.com', token: 'tok'));

      expect(store.read()?.email, 'a@b.com');
      expect(store.read()?.token, 'tok');
    });

    test('clear() removes the persisted session', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AuthSessionStore(await SharedPreferences.getInstance());
      await store.save(const User(email: 'a@b.com', token: 'tok'));

      await store.clear();

      expect(store.read(), isNull);
    });

    test('ignores a corrupt payload instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        AuthSessionStore.storageKey: 'not-json-at-all',
      });
      final store = AuthSessionStore(await SharedPreferences.getInstance());

      expect(store.read(), isNull);
    });
  });

  group('AuthRepository', () {
    test('login persists the session so the next launch stays signed in',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AuthRepository(AuthSessionStore(prefs));

      final user = await repo.login(
        email: 'student@learning.com',
        password: 'secret123',
      );
      expect(user.email, 'student@learning.com');

      // Kill + relaunch the app: brand-new repository, nothing but storage.
      final restarted = AuthRepository(
        AuthSessionStore(await simulateAppRestart(prefs)),
      );

      expect(restarted.restoreSession()?.email, 'student@learning.com');
      expect(restarted.restoreSession()?.token, user.token);
    });

    test('a rejected login never creates a session', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final repo = AuthRepository(store);

      await expectLater(
        repo.login(email: 'student@learning.com', password: 'wrong'),
        throwsA(isA<ServerFailure>()),
      );

      expect(store.read(), isNull);
    });

    test('logout clears the session even across a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AuthRepository(AuthSessionStore(prefs));

      await repo.login(email: 'student@learning.com', password: 'secret123');
      await repo.logout();

      final restarted = AuthRepository(
        AuthSessionStore(await simulateAppRestart(prefs)),
      );

      expect(restarted.restoreSession(), isNull);
    });
  });
}
