// -----------------------------------------------------------------------------
// Servicio: CourseStudentsService
// -----------------------------------------------------------------------------
// Servicio encargado de gestionar la relación entre cursos y estudiantes.
//
// Este servicio se usa para:
// - Inscribir un estudiante en un curso utilizando su correo.
// - Obtener la lista de estudiantes inscritos en un curso específico.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class CourseStudentsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// course_students/{course_id_student_id} -> { course_id, student_id }
  CollectionReference<Map<String, dynamic>> get _courseStudentsCollection {
    return _firestore.collection('course_students');
  }

  /// Escucha los alumnos inscritos en un curso específico
  Stream<List<UserModel>> listenStudentsByCourse(String course_id) {
    return _courseStudentsCollection
        .where('course_id', isEqualTo: course_id)
        .snapshots()
        .asyncMap((snapshot) async {
          final student_ids = snapshot.docs
              .map((doc) => doc.data()['student_id'] as String)
              .toSet()
              .toList();

          if (student_ids.isEmpty) return <UserModel>[];

          final usersSnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: student_ids)
              .get();

          return usersSnapshot.docs
              .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  /// Inscribe un alumno en un curso (idempotente)
  Future<void> enrollStudentInCourse({
    required String course_id,
    required String student_id,
  }) async {
    final doc_id = '${course_id}_$student_id'; // evita duplicados
    await _courseStudentsCollection.doc(doc_id).set({
      'course_id': course_id,
      'student_id': student_id,
    });
  }
}
