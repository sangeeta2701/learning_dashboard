import 'dart:convert';

import 'package:learning_dashboard/features/auth/presentation/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the signed-in [User] on the device.
///
/// This is what stops the app from asking for credentials on every launch:
/// the session is written on login and read back when the app boots.
class AuthSessionStore {
  /// Public so tests can seed/inspect storage without duplicating the key.
  static const storageKey = 'auth_session_v1';

  final SharedPreferences prefs;

  AuthSessionStore(this.prefs);

  /// Reads the stored session.
  ///
  /// Synchronous on purpose – [SharedPreferences] is already loaded in memory
  /// by the time the app starts, so no `await` (and no login flash) is needed.
  User? read() {
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final user = User.fromJson(json);
      if (user.email.isEmpty || user.token.isEmpty) return null;
      return user;
    } catch (_) {
      // Corrupt or legacy payload: treat it as "signed out" instead of crashing.
      return null;
    }
  }

  Future<void> save(User user) async {
    await prefs.setString(storageKey, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    await prefs.remove(storageKey);
  }
}
