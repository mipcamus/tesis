// -----------------------------------------------------------------------------
// Modelo: CourseClass
// -----------------------------------------------------------------------------
// Representa una clase programada dentro de un curso
//
// Este modelo se usa para:
// - Mostrar la lista de clases de un curso.
// - Marcar una clase como realizada (done = true).
//
// Campos:
//   - id: ID único del registro en Firestore.
//   - course_id: ID del curso al que pertenece la clase.
//   - date: Fecha y hora programada de la clase.
//   - done: Indica si la clase se realizó (true) o está pendiente (false).
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

class CourseClass {
  final String id;
  final String course_id;
  final DateTime date;
  final bool done;

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
