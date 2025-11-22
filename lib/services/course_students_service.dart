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

  /// course_students/{courseId_studentId} -> { course_id, student_id }
  CollectionReference<Map<String, dynamic>> get _courseStudentsCollection {
    return _firestore.collection('course_students');
  }

  /// Escucha los alumnos inscritos en un curso específico
  Stream<List<UserModel>> listenStudentsByCourse(String courseId) {
    return _courseStudentsCollection
        .where('course_id', isEqualTo: courseId)
        .snapshots()
        .asyncMap((snapshot) async {
          final studentIds = snapshot.docs
              .map((doc) => doc.data()['student_id'] as String)
              .toSet()
              .toList();

          if (studentIds.isEmpty) return <UserModel>[];

          final usersSnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: studentIds)
              .get();

          return usersSnapshot.docs
              .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  /// Inscribe un alumno en un curso (idempotente)
  Future<void> enrollStudentInCourse({
    required String courseId,
    required String studentId,
  }) async {
    final docId = '${courseId}_$studentId'; // evita duplicados
    await _courseStudentsCollection.doc(docId).set({
      'course_id': courseId,
      'student_id': studentId,
    });
  }
}
