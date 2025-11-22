// -----------------------------------------------------------------------------
// Modelo: ClassAttendance
// -----------------------------------------------------------------------------
// Representa la asistencia de un alumno a una clase específica dentro de un
// curso. Cada registro indica si un alumno asistió o no a una clase realizada.
//
// Este modelo se usa para:
// - Registrar asistencia en Firestore.
// - Consultar si un alumno asistió a una clase.
// - Calcular estadísticas de asistencia por curso.
//
// Campos:
//   - id: ID único del registro en Firestore.
//   - class_id: ID de la clase (CourseClass) a la que pertenece la asistencia.
//   - student_id: ID del alumno.
//   - attended: true si asistió, false si faltó.
//   - timestamp: Momento en que se registró la asistencia.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

class ClassAttendance {
  final String id;
  final String courseId;
  final String classId;
  final String studentId;
  final bool present;
  final DateTime createdAt;

  const ClassAttendance({
    required this.id,
    required this.courseId,
    required this.classId,
    required this.studentId,
    required this.present,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'course_id': courseId,
      'class_id': classId,
      'student_id': studentId,
      'present': present,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory ClassAttendance.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['created_at'] as Timestamp?;

    return ClassAttendance(
      id: id,
      courseId: data['course_id'] ?? '',
      classId: data['class_id'] ?? '',
      studentId: data['student_id'] ?? '',
      present: data['present'] ?? false,
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }
}
