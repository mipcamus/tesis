// lib/models/class_attendance.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassAttendance {
  final String user_id;
  final String course_id;
  final String class_id;
  final bool attended;
  final DateTime created_at;

  ClassAttendance({
    required this.user_id,
    required this.course_id,
    required this.class_id,
    required this.attended,
    required this.created_at,
  });

  factory ClassAttendance.fromDoc({
    required String course_id,
    required String class_id,
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data()!;
    return ClassAttendance(
      user_id: doc.id,
      course_id: course_id,
      class_id: class_id,
      attended: data['attended'] as bool? ?? true,
      created_at:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'attended': attended, 'created_at': Timestamp.fromDate(created_at)};
  }
}
