import 'package:shared_preferences/shared_preferences.dart';

/// Simulates a full app restart / background kill.
///
/// Everything that was *actually written* to storage is kept, while the
/// in-memory [SharedPreferences] instance (and every Dart object holding app
/// state, e.g. Riverpod providers) is thrown away – exactly what happens when
/// Android/iOS kills the process and the user reopens the app.
///
/// `setMockInitialValues` resets the singleton, so the returned instance is a
/// genuine new object that can only see what was persisted.
Future<SharedPreferences> simulateAppRestart(SharedPreferences prefs) async {
  final persisted = <String, Object>{
    for (final key in prefs.getKeys()) key: prefs.get(key)!,
  };

  SharedPreferences.setMockInitialValues(persisted);

  return SharedPreferences.getInstance();
}
