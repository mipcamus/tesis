// -----------------------------------------------------------------------------
// Servicio: ClassAttendanceService
// -----------------------------------------------------------------------------
// Servicio encargado de manejar toda la lógica relacionada con la asistencia de
// los alumnos a las clases.
//
// Este servicio se usa para:
// - Registrar asistencia de un alumno a una clase.
// - Obtener la asistencia de un alumno para una clase específica.
// - Obtener la asistencia completa de un curso (todas las clases).
//
// Notas:
// - Este servicio asegura que cada alumno tenga máximo un registro por clase.
// - Evita duplicados mediante combinaciones class_id + student_id.
//
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/class_attendance.dart';

class ClassAttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _attendanceCollection {
    return _firestore.collection('class_attendance');
  }

  /// Marca asistencia de un alumno a una clase de un curso.
  Future<void> markAttendance({
    required String course_id,
    required String class_id,
    required String student_id,
  }) async {
    final doc_id = '${class_id}_$student_id';

    final attendance = ClassAttendance(
      id: doc_id,
      course_id: course_id,
      class_id: class_id,
      student_id: student_id,
      present: true,
      createdAt: DateTime.now(),
    );

    await _attendanceCollection.doc(doc_id).set(attendance.toMap());
  }

  /// sistencias de un alumno en un curso.
  /// saber en qué clases ya marcó asistencia.
  Stream<List<ClassAttendance>> listenAttendanceForStudentInCourse({
    required String course_id,
    required String student_id,
  }) {
    return _attendanceCollection
        .where('course_id', isEqualTo: course_id)
        .where('student_id', isEqualTo: student_id)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ClassAttendance.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  /// (Opcional) Asistencia de un alumno para una clase específica.
  Stream<ClassAttendance?> listenAttendanceForClassAndStudent({
    required String class_id,
    required String student_id,
  }) {
    final doc_id = '${class_id}_$student_id';

    return _attendanceCollection.doc(doc_id).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ClassAttendance.fromFirestore(
        snap.id,
        snap.data() as Map<String, dynamic>,
      );
    });
  }
}
