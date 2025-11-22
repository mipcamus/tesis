// -----------------------------------------------------------------------------
// Servicio: UserCoursesService
// -----------------------------------------------------------------------------
// Servicio encargado de obtener y escuchar en tiempo real los cursos en los que
// un usuario está inscrito. Este servicio actúa como puente entre el usuario
// autenticado y la colección que almacena sus cursos asignados.
//
// Este servicio se usa para:
// - Obtener los IDs de los cursos asociados a un usuario.
// - Facilitar el filtrado de cursos según el rol del usuario.
// - Permitir que la UI muestre únicamente los cursos relevantes para el usuario.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserCoursesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario logueado');
    }
    return user.uid;
  }

  /// course_students/{course_id_student_id} -> { course_id, student_id }
  CollectionReference<Map<String, dynamic>> get _courseStudentsCollection {
    return _firestore.collection('course_students');
  }

  /// Trae los IDs de cursos en los que el usuario actual está inscrito
  Stream<Set<String>> listenEnrolledCourseIds() {
    return _courseStudentsCollection
        .where('student_id', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
          final ids = snapshot.docs
              .map((doc) => doc.data()['course_id'] as String)
              .toSet();
          return ids;
        });
  }

  /// (Opcional) Inscribir al usuario actual en un curso (para pruebas)
  Future<void> enrollCurrentUserInCourse(String course_id) async {
    final doc_id = '${course_id}_$_uid';
    await _courseStudentsCollection.doc(doc_id).set({
      'course_id': course_id,
      'student_id': _uid,
    });
  }

  /// (Opcional) Inscribir un usuario específico en un curso (profesor inscribe alumno)
  Future<void> enrollUserInCourse({
    required String user_id,
    required String course_id,
  }) async {
    final doc_id = '${course_id}_$user_id';
    await _courseStudentsCollection.doc(doc_id).set({
      'course_id': course_id,
      'student_id': user_id,
    });
  }
}
