import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learning_dashboard/features/auth/presentation/providers/auth_provider.dart';
import 'package:learning_dashboard/features/auth/presentation/screens/login_screen.dart';
import 'package:learning_dashboard/features/courses/presentation/course_dashboard_screen.dart';

/// Root widget of the app.
///
/// It restores the persisted session and routes accordingly:
///  * a stored session  → straight to the course dashboard (never asked to log
///    in again, even after the app was killed in the background),
///  * no stored session → the login screen,
///  * while restoring   → a short splash.
///
/// Because the gate *reacts* to [authSessionProvider], login and logout need no
/// imperative `Navigator` calls at all.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    return switch (session) {
      AuthSessionChecking() => const _SplashScreen(),
      AuthSessionSignedIn() => const CourseDashboardScreen(),
      AuthSessionSignedOut() => const LoginScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 72, color: Colors.indigo),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
