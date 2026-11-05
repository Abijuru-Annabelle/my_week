import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../state/week_state.dart';
import 'course_screen.dart';
import 'weather_card.dart';

// SCREEN: just draws. It watches the brain and calls its methods.
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  // Open the form and hand it the SAME brain (step 8 and 14).
  void _openForm(BuildContext context, Course? course) {
    final week = context.read<WeekState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<WeekState>.value(
          value: week,
          child: CourseScreen(
            course: course,
            day: course?.day ?? week.selectedDay,
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Course course) async {
    final week = context.read<WeekState>(); // read BEFORE the await
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
      await week.remove(course);
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = context.watch<WeekState>(); // rebuild at every change

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
        onPressed: () => _openForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WeatherCard(),
            const SizedBox(height: 12),
            Expanded(child: _body(context, week)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WeekState week) {
    // Error state
    if (week.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(week.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.read<WeekState>().retry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    // Loading state
    if (week.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Empty state: no courses at all
    if (week.courses.isEmpty) {
      return const Center(
        child: Text(
          'No courses yet.\nTap + to add your first course.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final visible = week.visible; // the filtered list, computed by the brain
    final dayName = dayNames[week.selectedDay];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week total: ${formatDuration(week.weekMinutes)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // The filter: watched in build, read when tapped
        Wrap(
          spacing: 8,
          children: days
              .map((d) => ChoiceChip(
                    label: Text(d),
                    selected: week.selectedDay == d,
                    onSelected: (_) => context.read<WeekState>().selectDay(d),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search a course',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (text) => context.read<WeekState>().setQuery(text),
        ),
        const SizedBox(height: 12),
        Text(
          '$dayName: ${formatDuration(week.dayMinutes)}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: week.coursesOfDay.isEmpty
              ? Center(child: Text('No classes on $dayName'))
              : visible.isEmpty
                  ? const Center(child: Text('Nothing matches your search.'))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final c = visible[index];
                        final clashList = week.clashNames(c);
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
                            onTap: () => _openForm(context, c),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _delete(context, c),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
