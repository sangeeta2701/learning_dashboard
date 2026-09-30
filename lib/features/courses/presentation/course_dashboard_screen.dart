import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learning_dashboard/features/auth/presentation/providers/auth_provider.dart';
import 'package:learning_dashboard/features/courses/course.dart';
import 'package:learning_dashboard/features/courses/presentation/course_details_screen.dart';
import 'package:learning_dashboard/features/courses/presentation/providers/courses_provider.dart';


class CourseDashboardScreen extends ConsumerWidget {
  const CourseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(coursesProvider.notifier).load(),
          ),
          const _AccountMenu(),
        ],
      ),
      body: switch (state) {
        CoursesLoading() => const Center(child: CircularProgressIndicator()),
        CoursesEmpty() => _EmptyView(
            onRetry: () => ref.read(coursesProvider.notifier).load(),
          ),
        CoursesError(:final message) => _ErrorView(
            message: message,
            onRetry: () => ref.read(coursesProvider.notifier).load(),
          ),
        CoursesData(:final courses) => RefreshIndicator(
            onRefresh: () => ref.read(coursesProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _CourseCard(
                course: courses[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CourseDetailsScreen(course: courses[i]),
                  ),
                ),
              ),
            ),
          ),
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                course.instructor,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: course.progressPercent / 100,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${course.progressPercent}% • '
                    '${course.completedLessons}/${course.totalLessons} lessons',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  FilledButton.tonal(
                    onPressed: onTap,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = switch (ref.watch(authSessionProvider)) {
      AuthSessionSignedIn(:final user) => user.email,
      _ => null,
    };

    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle),
      onSelected: (value) {
        if (value == 'logout') {
          // Clears the persisted session; [AuthGate] then shows the login
          // screen again on this and on every future launch.
          ref.read(authSessionProvider.notifier).signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            email ?? 'Signed in',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text('Log out'),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No courses yet'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Refresh')),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}