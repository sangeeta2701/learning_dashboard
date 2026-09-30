import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/features/courses/course.dart';

void main() {
  group('Course.progressPercent', () {
    Course makeCourse(int total, int completed) => Course(
          id: 1,
          title: 'T',
          instructor: 'I',
          lessons: List.generate(
            total,
            (i) => Lesson(id: 'l$i', title: 'L$i', completed: i < completed),
          ),
        );

    test('returns 0 when no lessons are completed', () {
      expect(makeCourse(10, 0).progressPercent, 0);
    });

    test('returns 100 when all lessons are completed', () {
      expect(makeCourse(10, 10).progressPercent, 100);
    });

    test('rounds to the nearest integer', () {
      expect(makeCourse(3, 1).progressPercent, 33);
      expect(makeCourse(3, 2).progressPercent, 67);
    });

    test('does not divide by zero for an empty course', () {
      expect(makeCourse(0, 0).progressPercent, 0);
    });
  });
}