import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learning_dashboard/features/courses/course.dart';
import 'package:learning_dashboard/features/courses/presentation/providers/courses_provider.dart';


class CourseDetailsScreen extends ConsumerWidget {
  final Course course;
  const CourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   
    final live = ref.watch(coursesProvider.select((s) {
      if (s is CoursesData) {
        for (final c in s.courses) {
          if (c.id == course.id) return c;
        }
      }
      return null;
    })) ??
        course;

    final notifier = ref.read(coursesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(live.title),
      
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              live.instructor,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: live.progressPercent / 100,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progress: ${live.progressPercent}% '
              '(${live.completedLessons}/${live.totalLessons} lessons)',
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: live.lessons.length,
                itemBuilder: (_, i) {
                  final l = live.lessons[i];
                  return CheckboxListTile(
                    value: l.completed,
                    onChanged: (_) => notifier.toggleLesson(live.id, l.id),
                    title: Text(l.title),
                    secondary: Icon(
                      l.completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: l.completed ? Colors.green : Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}