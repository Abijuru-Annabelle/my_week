import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'course.dart';
import 'course_screen.dart';
import 'firebase_options.dart';
import 'weather.dart';

const dayNames = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: kIsWeb ? webFirebaseOptions : null);
  runApp(const MyWeekApp());
}

class MyWeekApp extends StatelessWidget {
  const MyWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Week',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const AuthGate(),
    );
  }
}

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  String selectedDay = 'Mon';

  // Listens to Firestore: the courses now, and again after every change.
  // Created once, so tapping a day chip does not restart it.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> coursesStream =
  myCourses().orderBy('start').snapshots();

  // Weather: the three states
  Weather? weather;
  bool weatherLoading = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  // ---------- Live weather from the API ----------

  Future<void> loadWeather() async {
    try {
      final result = await fetchKigaliWeather();
      setState(() {
        weather = result;
        weatherLoading = false;
        weatherError = null;
      });
    } catch (e) {
      setState(() {
        weatherLoading = false;
        weatherError = 'Could not load the weather. Check your internet connection.';
      });
    }
  }

  void retryWeather() {
    setState(() {
      weatherLoading = true;
      weatherError = null;
    });
    loadWeather();
  }

  // ---------- Computed from the courses, never saved ----------

  int totalMinutes(List<Course> list) {
    int total = 0;
    for (final c in list) {
      total += c.end - c.start;
    }
    return total;
  }

  List<String> clashNames(Course course, List<Course> all) {
    return all.where((o) => clashes(course, o)).map((o) => o.name).toList();
  }

  // ---------- Add, edit, delete ----------

  void openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseScreen(day: selectedDay)),
    );
  }

  void openEdit(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CourseScreen(course: course, day: course.day)),
    );
  }

  Future<void> confirmDelete(Course course) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${course.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure == true) {
      await myCourses().doc(course.id).delete();
    }
  }

  // ---------- Screens ----------

  Widget buildWeather() {
    if (weatherLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (weatherError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.wifi_off),
              const SizedBox(width: 12),
              Expanded(child: Text(weatherError!)),
              FilledButton(
                onPressed: retryWeather,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.cloud, color: Colors.teal),
        title: Text('Kigali now: ${weather!.temperature.round()}°C'),
        subtitle: Text(describe(weather!.code)),
      ),
    );
  }

  Widget buildCourses(List<Course> courses) {
    // Empty state: a new user with no courses yet
    if (courses.isEmpty) {
      return const Center(
        child: Text(
          'No courses yet.\nTap + to add your first course.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final today = courses.where((c) => c.day == selectedDay).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week total: ${formatDuration(totalMinutes(courses))}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: days.map((d) {
            return ChoiceChip(
              label: Text(d),
              selected: selectedDay == d,
              onSelected: (_) => setState(() => selectedDay = d),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          '${dayNames[selectedDay]}: ${formatDuration(totalMinutes(today))}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: today.isEmpty
              ? Center(child: Text('No classes on ${dayNames[selectedDay]}'))
              : ListView.builder(
            itemCount: today.length,
            itemBuilder: (context, index) {
              final c = today[index];
              final clashList = clashNames(c, courses);
              final hasClash = clashList.isNotEmpty;
              return Card(
                color: hasClash ? Colors.red.shade100 : null,
                child: ListTile(
                  leading: Icon(
                    hasClash ? Icons.warning : Icons.book,
                    color: hasClash ? Colors.red : Colors.teal,
                  ),
                  title: Text(c.name),
                  subtitle: Text(
                    '${formatTime(c.start)} – ${formatTime(c.end)}'
                        '${hasClash ? '\nClashes with ${clashList.join(', ')}' : ''}',
                    style:
                    TextStyle(color: hasClash ? Colors.red : null),
                  ),
                  onTap: () => openEdit(c),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => confirmDelete(c),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 My Week'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAdd,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildWeather(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: coursesStream,
                builder: (context, snapshot) {
                  // Error state, e.g. the rules refused
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load your courses.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  // Loading state
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Data: every document becomes a Course
                  final courses =
                  snapshot.data!.docs.map(Course.fromDoc).toList();
                  return buildCourses(courses);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}