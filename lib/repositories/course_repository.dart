import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

// REPOSITORY: the only class that talks to Firestore for courses.
class CourseRepository {
  CourseRepository(this.uid);

  final String uid;

  // users/{uid}/courses: the path your security rules protect.
  CollectionReference<Map<String, dynamic>> get _courses =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('courses');

  // The pipe: the list now, and again after every change.
  Stream<List<Course>> watchAll() => _courses
      .orderBy('start')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Course.fromDoc).toList());

  Future<void> add(Course course) => _courses.add(course.toMap());

  Future<void> update(String id, Course course) =>
      _courses.doc(id).update(course.toMap());

  Future<void> delete(String id) => _courses.doc(id).delete();

  // Sample data for a brand new account.
  Future<void> addSamples() async {
    final samples = [
      Course(name: 'Mobile Programming', day: 'Mon', start: 480, end: 600),
      Course(name: 'Java', day: 'Mon', start: 600, end: 690),
      Course(name: 'Operating Systems', day: 'Tue', start: 540, end: 660),
      Course(name: 'Physics', day: 'Tue', start: 630, end: 720),
      Course(name: 'Web Technology', day: 'Thu', start: 840, end: 960),
    ];
    final batch = FirebaseFirestore.instance.batch();
    for (final c in samples) {
      batch.set(_courses.doc(), c.toMap());
    }
    await batch.commit();
  }
}
