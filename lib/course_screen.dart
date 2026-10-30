import 'package:flutter/material.dart';
import 'course.dart';

const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key, this.course, required this.day});

  final Course? course; // null = adding a new course
  final String day;

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final nameController = TextEditingController();
  final startController = TextEditingController();
  final endController = TextEditingController();
  late String day;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    day = widget.day;
    final c = widget.course;
    if (c != null) {
      nameController.text = c.name;
      startController.text = formatTime(c.start);
      endController.text = formatTime(c.end);
    }
  }

  void show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final start = parseTime(startController.text);
    final end = parseTime(endController.text);

    if (name.isEmpty) {
      show('Course name cannot be empty');
      return;
    }
    if (start == null) {
      show('Start time must be like 08:00');
      return;
    }
    if (end == null) {
      show('End time must be like 10:00');
      return;
    }
    if (end <= start) {
      show('End time must be after start time');
      return;
    }

    final data =
    Course(name: name, day: day, start: start, end: end).toMap();

    setState(() => saving = true);
    try {
      if (widget.course == null) {
        await myCourses().add(data); // new document, random id
      } else {
        await myCourses().doc(widget.course!.id).update(data); // edit
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      show('Could not save the course: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.course != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit course' : 'Add course')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Course name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: day,
              decoration: const InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
              ),
              items: days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) => setState(() => day = value!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    decoration: const InputDecoration(
                      labelText: 'Start (08:00)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endController,
                    decoration: const InputDecoration(
                      labelText: 'End (10:00)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}