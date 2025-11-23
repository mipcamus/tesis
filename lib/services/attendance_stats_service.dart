// lib/services/attendance_stats_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseAttendanceStats {
  final int attended_count;
  final int total_done_classes;
  final double percentage;

  CourseAttendanceStats({
    required this.attended_count,
    required this.total_done_classes,
    required this.percentage,
  });
}

class AttendanceStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario logueado');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _classes_collection =>
      _firestore.collection('course_classes');

  CollectionReference<Map<String, dynamic>> get _attendance_collection =>
      _firestore.collection('class_attendance');

  CollectionReference<Map<String, dynamic>> get _course_students_collection =>
      _firestore.collection('course_students');

  /// % de asistencia del alumno loggeado en un curso específico
  Future<double> get_course_attendance_percentage(String course_id) async {
    final stats = await get_course_attendance_stats(course_id);
    return stats.percentage;
  }

  /// Versión para profesor:
  /// Calcula las stats de asistencia de UN alumno específico en UN curso.
  Future<CourseAttendanceStats> get_course_attendance_stats_for_student({
    required String course_id,
    required String student_id,
  }) async {
    // Total de clases realizadas (done = true) de ese curso
    final classes_snapshot = await _classes_collection
        .where('course_id', isEqualTo: course_id)
        .where('done', isEqualTo: true)
        .get();

    final total_done_classes = classes_snapshot.size;

    if (total_done_classes == 0) {
      return CourseAttendanceStats(
        attended_count: 0,
        total_done_classes: 0,
        percentage: 0.0,
      );
    }

    // Clases a las que ESTE alumno asistió en ese curso
    final attended_snapshot = await _attendance_collection
        .where('course_id', isEqualTo: course_id)
        .where('student_id', isEqualTo: student_id)
        .where('present', isEqualTo: true)
        .get();

    final attended_count = attended_snapshot.size;
    final percentage = attended_count * 100.0 / total_done_classes;

    return CourseAttendanceStats(
      attended_count: attended_count,
      total_done_classes: total_done_classes,
      percentage: percentage,
    );
  }

  /// Versión completa: % + totales para un curso
  Future<CourseAttendanceStats> get_course_attendance_stats(
    String course_id,
  ) async {
    final student_id = _uid;

    // Total de clases realizadas (done = true) de ese curso
    final classes_snapshot = await _classes_collection
        .where('course_id', isEqualTo: course_id)
        .where('done', isEqualTo: true)
        .get();

    final total_done_classes = classes_snapshot.size;

    if (total_done_classes == 0) {
      return CourseAttendanceStats(
        attended_count: 0,
        total_done_classes: 0,
        percentage: 0.0,
      );
    }

    // Clases a las que este alumno asistió en ese curso
    final attended_snapshot = await _attendance_collection
        .where('course_id', isEqualTo: course_id)
        .where('student_id', isEqualTo: student_id)
        .where('present', isEqualTo: true)
        .get();

    final attended_count = attended_snapshot.size;
    final percentage = attended_count * 100.0 / total_done_classes;

    return CourseAttendanceStats(
      attended_count: attended_count,
      total_done_classes: total_done_classes,
      percentage: percentage,
    );
  }

  /// % total de asistencia del alumno loggeado en TODOS sus cursos
  Future<double> get_total_attendance_percentage_for_current_student() async {
    final student_id = _uid;

    // 1) Traer todos los cursos donde el alumno está inscrito
    final course_students_snapshot = await _course_students_collection
        .where('student_id', isEqualTo: student_id)
        .get();

    final course_ids = course_students_snapshot.docs
        .map((doc) => doc.data()['course_id'] as String)
        .toSet()
        .toList();

    if (course_ids.isEmpty) {
      return 0.0;
    }

    List<List<String>> _chunk_course_ids(List<String> ids, int chunk_size) {
      final chunks = <List<String>>[];
      for (var i = 0; i < ids.length; i += chunk_size) {
        final end = (i + chunk_size < ids.length) ? i + chunk_size : ids.length;
        chunks.add(ids.sublist(i, end));
      }
      return chunks;
    }

    final chunks = _chunk_course_ids(course_ids, 10);

    int total_done_classes = 0;
    int attended_count = 0;

    // 2) Clases realizadas totales
    for (final chunk in chunks) {
      final classes_snapshot = await _classes_collection
          .where('course_id', whereIn: chunk)
          .where('done', isEqualTo: true)
          .get();

      total_done_classes += classes_snapshot.size;
    }

    if (total_done_classes == 0) {
      return 0.0;
    }

    // 3) Asistencias totales del alumno
    for (final chunk in chunks) {
      final attended_snapshot = await _attendance_collection
          .where('course_id', whereIn: chunk)
          .where('student_id', isEqualTo: student_id)
          .where('present', isEqualTo: true)
          .get();

      attended_count += attended_snapshot.size;
    }

    return attended_count * 100.0 / total_done_classes;
  }

  Stream<CourseAttendanceStats> listen_course_attendance_stats(
    String course_id,
  ) {
    final student_id = _uid;

    // Escuchamos cambios en la asistencia de ESTE curso y alumno.
    return _attendance_collection
        .where('course_id', isEqualTo: course_id)
        .where('student_id', isEqualTo: student_id)
        .where('present', isEqualTo: true)
        .snapshots()
        .asyncMap((attendance_snapshot) async {
          final attended_count = attendance_snapshot.size;

          // Recalculamos las clases realizadas
          final classes_snapshot = await _classes_collection
              .where('course_id', isEqualTo: course_id)
              .where('done', isEqualTo: true)
              .get();

          final total_done_classes = classes_snapshot.size;

          double percentage = 0.0;
          if (total_done_classes > 0) {
            percentage = attended_count * 100.0 / total_done_classes;
          }

          return CourseAttendanceStats(
            attended_count: attended_count,
            total_done_classes: total_done_classes,
            percentage: percentage,
          );
        });
  }

  Stream<double> listen_total_attendance_percentage_for_current_student() {
    final student_id = _uid;

    // Cada vez que cambie la colección de asistencias de este alumno
    // recalculamos el porcentaje total
    return _attendance_collection
        .where('student_id', isEqualTo: student_id)
        .snapshots()
        .asyncMap((_) async {
          return get_total_attendance_percentage_for_current_student();
        });
  }
}
