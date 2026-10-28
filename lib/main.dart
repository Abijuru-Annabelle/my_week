import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'course.dart';
import 'course_screen.dart';
import 'weather.dart';

const dayNames = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
};

void main() => runApp(const MyWeekApp());

class MyWeekApp extends StatelessWidget {
  const MyWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Week',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const WeekScreen(),
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

  final List<Course> courses = [
    Course(name: 'Mobile Programming', day: 'Mon', start: 480, end: 600),
    Course(name: 'Java', day: 'Mon', start: 600, end: 690),
    Course(name: 'Operating Systems', day: 'Tue', start: 540, end: 660),
    Course(name: 'Physics', day: 'Tue', start: 630, end: 720),
    Course(name: 'Web Technology', day: 'Thu', start: 840, end: 960),
  ];

  // Weather: the three states
  Weather? weather;
  bool weatherLoading = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
    loadCourses();
    loadWeather();
  }

  // ---------- Saving on the phone ----------

  Future<void> saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final list = courses.map((c) => c.toJson()).toList();
    await prefs.setString('courses', jsonEncode(list));
  }

  Future<void> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('courses');
    if (saved != null) {
      final list = jsonDecode(saved) as List;
      setState(() {
        courses.clear();
        courses.addAll(
          list.map((x) => Course.fromJson(x as Map<String, dynamic>)),
        );
      });
    }
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

  // ---------- Courses ----------

  // Courses of one day, sorted by start time
  List<Course> coursesOn(String day) {
    final list = courses.where((c) => c.day == day).toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  int totalMinutes(List<Course> list) {
    int total = 0;
    for (final c in list) {
      total += c.end - c.start;
    }
    return total;
  }

  List<String> clashNames(Course course) {
    return courses.where((o) => clashes(course, o)).map((o) => o.name).toList();
  }

  void openAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseScreen(day: selectedDay)),
    ).then((result) {
      if (result != null) {
        setState(() {
          courses.add(result);
        });
        saveCourses();
      }
    });
  }

  void openEdit(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CourseScreen(course: course, day: course.day)),
    ).then((_) {
      setState(() {});
      saveCourses();
    });
  }

  void confirmDelete(Course course) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${course.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  courses.remove(course);
                });
                saveCourses();
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final today = coursesOn(selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('📅 My Week')),
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
                  final clashList = clashNames(c);
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
                        style: TextStyle(
                            color: hasClash ? Colors.red : null),
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
        ),
      ),
    );
  }
}