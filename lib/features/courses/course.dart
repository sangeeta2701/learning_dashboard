class Lesson {
  final String id;
  final String title;
  final bool completed;

  const Lesson({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Lesson copyWith({bool? completed}) => Lesson(
        id: id,
        title: title,
        completed: completed ?? this.completed,
      );
}

class Course {
  final int id;
  final String title;
  final String instructor;
  final List<Lesson> lessons;

  const Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.lessons,
  });

  int get totalLessons => lessons.length;
  int get completedLessons => lessons.where((l) => l.completed).length;

  /// Progress as an integer percentage (0–100).
  int get progressPercent => totalLessons == 0
      ? 0
      : ((completedLessons / totalLessons) * 100).round();

  Course copyWith({List<Lesson>? lessons}) => Course(
        id: id,
        title: title,
        instructor: instructor,
        lessons: lessons ?? this.lessons,
      );

  // ---- JSON ----
  //
  // The mock API ships a lesson *count* ("lessons": 20), not a lesson list.
  // We generate placeholder titles locally. A real backend would return the
  // list from `/courses/{id}/lessons`.

  factory Course.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final count = (json['lessons'] as num).toInt();
    return Course(
      id: id,
      title: json['title'] as String,
      instructor: json['instructor'] as String,
      lessons: List.generate(
        count,
        (i) => Lesson(id: '${id}_$i', title: _lessonTitle(i)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'instructor': instructor,
        'lessons': lessons.length,
      };

  static const _defaultTitles = [
    'Introduction',
    'Variables & Data Types',
    'Functions',
    'OOP',
    'Collections',
    'Error Handling',
    'Async Programming',
    'Testing',
    'Architecture',
    'Deployment',
    'Performance',
    'Security',
    'Networking',
    'State Management',
    'Animations',
    'Accessibility',
    'Localization',
    'CI/CD',
    'Code Review',
    'Final Project',
  ];

  static String _lessonTitle(int i) =>
      i < _defaultTitles.length ? _defaultTitles[i] : 'Lesson ${i + 1}';
}