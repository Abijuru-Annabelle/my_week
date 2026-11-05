import 'package:cloud_firestore/cloud_firestore.dart';

// MODEL: says what a course is. It never reads or writes data itself.
class Course {
  Course({
    this.id = '',
    required this.name,
    required this.day,
    required this.start,
    required this.end,
  });

  final String id; // the Firestore document id ('' for a new course)
  final String name;
  final String day; // 'Mon' ... 'Fri'
  final int start; // minutes from midnight, 08:30 = 510
  final int end;

  int get minutes => end - start;

  // Only the facts the user typed are saved. Totals and clashes are computed.
  Map<String, dynamic> toMap() => {
        'name': name,
        'day': day,
        'start': start,
        'end': end,
      };

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Course(
      id: doc.id,
      name: data['name'] as String,
      day: data['day'] as String,
      start: (data['start'] as num).toInt(),
      end: (data['end'] as num).toInt(),
    );
  }
}

const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

const dayNames = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
};

// "08:30" -> 510, wrong input -> null
int? parseTime(String text) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  final h = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  if (h > 23 || m > 59) return null;
  return h * 60 + m;
}

// 510 -> "08:30"
String formatTime(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

// 210 -> "3h 30m"
String formatDuration(int minutes) {
  return '${minutes ~/ 60}h ${minutes % 60}m';
}

// Same day, and each starts before the other ends
bool clashes(Course a, Course b) {
  return a.id != b.id && a.day == b.day && a.start < b.end && b.start < a.end;
}
