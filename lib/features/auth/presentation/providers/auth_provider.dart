import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learning_dashboard/core/failure.dart';
import 'package:learning_dashboard/core/preferences.dart';
import 'package:learning_dashboard/features/auth/auth_repository.dart';
import 'package:learning_dashboard/features/auth/auth_session_store.dart';
import 'package:learning_dashboard/features/auth/presentation/user.dart';

final authSessionStoreProvider = Provider<AuthSessionStore>(
  (ref) => AuthSessionStore(ref.watch(sharedPreferencesProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authSessionStoreProvider)),
);

// ----------------------------------------------------------------- session ---

/// Whether the user is signed in. Backed by [AuthSessionStore], so it survives
/// app restarts and background kills.
sealed class AuthSessionState {
  const AuthSessionState();
}

/// The app just booted and is restoring the persisted session.
class AuthSessionChecking extends AuthSessionState {
  const AuthSessionChecking();
}

class AuthSessionSignedOut extends AuthSessionState {
  const AuthSessionSignedOut();
}

class AuthSessionSignedIn extends AuthSessionState {
  final User user;
  const AuthSessionSignedIn(this.user);
}

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() {
    // Restore asynchronously so a real app could also refresh/validate the
    // token against the backend before deciding.
    Future.microtask(restore);
    return const AuthSessionChecking();
  }

  Future<void> restore() async {
    final user = ref.read(authRepositoryProvider).restoreSession();
    state = user == null
        ? const AuthSessionSignedOut()
        : AuthSessionSignedIn(user);
  }

  /// Published right after a successful login (the repository already saved it).
  void signedIn(User user) => state = AuthSessionSignedIn(user);

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthSessionSignedOut();
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
  AuthSessionNotifier.new,
);

// ------------------------------------------------------------------- login ---

sealed class LoginState {
  const LoginState();
}

class LoginIdle extends LoginState {
  const LoginIdle();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final User user;
  const LoginSuccess(this.user);
}

class LoginError extends LoginState {
  final String message;
  const LoginError(this.message);
}

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginIdle();

  Future<void> login({required String email, required String password}) async {
    state = const LoginLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);

      // The repository persisted the session; publish it so [AuthGate] swaps
      // the login screen for the dashboard.
      ref.read(authSessionProvider.notifier).signedIn(user);
      state = LoginSuccess(user);
    } on Failure catch (f) {
      state = LoginError(f.message);
    } catch (_) {
      state = const LoginError('Something went wrong. Please try again.');
    }
  }
}

final loginProvider =
    NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);