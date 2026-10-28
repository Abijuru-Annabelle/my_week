class Course {
  String name;
  String day;
  int start; // minutes from midnight, 08:30 = 510
  int end;

  Course({
    required this.name,
    required this.day,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'day': day, 'start': start, 'end': end};
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      name: json['name'] as String,
      day: json['day'] as String,
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );
  }
}

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
  return a != b && a.day == b.day && a.start < b.end && b.start < a.end;
}