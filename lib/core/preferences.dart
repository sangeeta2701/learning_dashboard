import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single [SharedPreferences] instance created in `main()`.
///
/// Every feature (auth session, course cache, lesson progress) reads from this
/// same instance, which is why it lives in `core` instead of inside a feature.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);
