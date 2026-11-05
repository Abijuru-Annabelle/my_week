import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';

// STATE: the brain. Holds the courses, computes the totals,
// and tells every watching screen when something changes.
class WeekState extends ChangeNotifier {
  WeekState(this._repo) {
    debugPrint('Brain born for ${_repo.uid}');
    _listen();
  }

  final CourseRepository _repo;
  StreamSubscription<List<Course>>? _subscription;

  // The data: private, so only the brain can change it.
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;

  // The filter (step 18): which day, and the search text.
  String _selectedDay = 'Mon';
  String _query = '';

  // Open the pipe to Firestore.
  void _listen() {
    _subscription?.cancel();
    _subscription = _repo.watchAll().listen(
      (list) {
        _courses = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load your courses.\n$e';
        notifyListeners();
      },
    );
  }

  // Error state: try again.
  void retry() {
    _loading = true;
    _error = null;
    notifyListeners();
    _listen();
  }

  // Read-only views for the screens.
  List<Course> get courses => _courses;
  bool get loading => _loading;
  String? get error => _error;
  String get selectedDay => _selectedDay;
  String get query => _query;

  // Habit 2: never saved, computed every time it is read.
  int get weekMinutes => _total(_courses);

  int minutesOn(String day) =>
      _total(_courses.where((c) => c.day == day).toList());

  int get dayMinutes => minutesOn(_selectedDay);

  // The courses of the chosen day, sorted by start time.
  List<Course> get coursesOfDay =>
      _courses.where((c) => c.day == _selectedDay).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  // What the list shows: the chosen day, then the search text.
  List<Course> get visible => coursesOfDay
      .where((c) => c.name.toLowerCase().contains(_query))
      .toList();

  // The names of the courses that clash with this one.
  List<String> clashNames(Course course) =>
      _courses.where((o) => clashes(course, o)).map((o) => o.name).toList();

  static int _total(List<Course> list) =>
      list.fold<int>(0, (total, c) => total + c.minutes);

  // Change the filter, then tell everyone.
  void selectDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  void setQuery(String text) {
    _query = text.trim().toLowerCase();
    notifyListeners();
  }

  // Actions: the brain hands the job to the repository.
  // The new list comes back through the pipe, like every other change.
  Future<void> add(Course course) => _repo.add(course);
  Future<void> edit(String id, Course course) => _repo.update(id, course);
  Future<void> remove(Course course) => _repo.delete(course.id);

  @override
  void dispose() {
    debugPrint('Brain disposed: pipe closed');
    _subscription?.cancel();
    super.dispose();
  }
}
