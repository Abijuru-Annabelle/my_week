import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Course {
  String id; // the Firestore document id
  String name;
  String day;
  int start; // minutes from midnight, 08:30 = 510
  int end;

  Course({
    this.id = '',
    required this.name,
    required this.day,
    required this.start,
    required this.end,
  });

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

// The signed-in user's courses: users/{uid}/courses
CollectionReference<Map<String, dynamic>> myCourses() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('courses');
}

// Sample data, written once when a new account is created
Future<void> addSampleCourses() async {
  final samples = [
    Course(name: 'Mobile Programming', day: 'Mon', start: 480, end: 600),
    Course(name: 'Java', day: 'Mon', start: 600, end: 690),
    Course(name: 'Operating Systems', day: 'Tue', start: 540, end: 660),
    Course(name: 'Physics', day: 'Tue', start: 630, end: 720),
    Course(name: 'Web Technology', day: 'Thu', start: 840, end: 960),
  ];
  final batch = FirebaseFirestore.instance.batch();
  for (final c in samples) {
    batch.set(myCourses().doc(), c.toMap());
  }
  await batch.commit();
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
  return a.id != b.id && a.day == b.day && a.start < b.end && b.start < a.end;
}