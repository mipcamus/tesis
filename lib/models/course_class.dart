import 'package:cloud_firestore/cloud_firestore.dart';

class CourseClass {
  final String id;
  final String course_id;
  final DateTime date; // fecha y hora de la clase
  final bool done; // true = realizada, false = no realizada

  const CourseClass({
    required this.id,
    required this.course_id,
    required this.date,
    required this.done,
  });

  Map<String, dynamic> toMap() {
    return {
      'course_id': course_id,
      'date': Timestamp.fromDate(date),
      'done': done,
    };
  }

  factory CourseClass.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['date'] as Timestamp?;

    return CourseClass(
      id: id,
      course_id: data['course_id'] ?? '',
      date: timestamp?.toDate() ?? DateTime.now(),
      done: data['done'] ?? false,
    );
  }
}
