import 'package:learning_dashboard/core/failure.dart';
import 'package:learning_dashboard/features/auth/auth_session_store.dart';
import 'package:learning_dashboard/features/auth/presentation/user.dart';

class AuthRepository {
  final AuthSessionStore _sessions;

  AuthRepository(this._sessions);

  /// The session persisted by a previous login, if any.
  ///
  /// Called once when the app boots so an already signed-in user is never asked
  /// for credentials again.
  User? restoreSession() => _sessions.read();

  Future<User> login({
    required String email,
    required String password,
  }) async {
    // Simulate network latency.
    await Future.delayed(const Duration(milliseconds: 900));

    if (password == 'wrong') {
      throw const ServerFailure('Invalid credentials');
    }

    final user = User(
      email: email,
      token: 'mock_jwt_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Persist *before* returning, so a successful login can never be lost when
    // the app is closed/killed right after signing in.
    await _sessions.save(user);

    return user;
  }

  Future<void> logout() => _sessions.clear();
}