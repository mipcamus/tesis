// lib/services/attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_attendance.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Referencia base:
  CollectionReference<Map<String, dynamic>> _coursesRef() =>
      _db.collection('courses');

  /// Marca que un alumno asistió a una clase realizada.
  Future<void> markAttendance({
    required String course_id,
    required String class_id,
    required String user_id,
  }) async {
    final attendanceRef = _coursesRef()
        .doc(course_id)
        .collection('classes')
        .doc(class_id)
        .collection('attendances')
        .doc(user_id);

    final attendance = ClassAttendance(
      user_id: user_id,
      course_id: course_id,
      class_id: class_id,
      attended: true,
      created_at: DateTime.now(),
    );

    await attendanceRef.set(attendance.toMap(), SetOptions(merge: true));
  }

  /// Devuelve un stream que indica si el alumno asistió a esa clase.
  Stream<bool> listenAttendance({
    required String course_id,
    required String class_id,
    required String user_id,
  }) {
    final attendanceRef = _coursesRef()
        .doc(course_id)
        .collection('classes')
        .doc(class_id)
        .collection('attendances')
        .doc(user_id);

    return attendanceRef.snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data();
      return (data?['attended'] as bool?) ?? true;
    });
  }

  /// Obtiene una sola vez si el alumno asistió.
  Future<bool> didStudentAttend({
    required String course_id,
    required String class_id,
    required String user_id,
  }) async {
    final attendanceRef = _coursesRef()
        .doc(course_id)
        .collection('classes')
        .doc(class_id)
        .collection('attendances')
        .doc(user_id);

    final doc = await attendanceRef.get();
    if (!doc.exists) return false;
    final data = doc.data();
    return (data?['attended'] as bool?) ?? true;
  }
}
