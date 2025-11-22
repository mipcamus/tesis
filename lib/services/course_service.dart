// -----------------------------------------------------------------------------
// Servicio: CourseService
// -----------------------------------------------------------------------------
// Servicio encargado de manejar todas las operaciones relacionadas con los
// cursos dentro de la aplicación.
//
// Este servicio se usa para:
// - Crear un nuevo curso en Firestore.
// - Obtener la información de un curso por su ID.
// - Escuchar en tiempo real los cambios en un curso específico.
// - Obtener todos los cursos disponibles.
// - Actualizar datos del curso (nombre, descripción, docente, etc.).
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course.dart';

class CourseService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _coursesCollection {
    return _firestore.collection('courses');
  }

  // Metodo para traer todos los cursos
  Stream<List<Course>> listenAllCourses() {
    return _coursesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  // Metodo para traer los cursos del usuario actual (por IDs)
  Stream<List<Course>> listenCoursesByIds(Set<String> ids) {
    if (ids.isEmpty) {
      return Stream.value(const <Course>[]);
    }

    return _coursesCollection
        .where(FieldPath.documentId, whereIn: ids.toList())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Course.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  //  crear curso para un profesor
  Future<String> createCourse({
    required String title,
    required String description,
    required String teacher_id,
  }) async {
    final docRef = await _coursesCollection.add({
      'title': title,
      'description': description,
      'teacher_id': teacher_id,
    });

    return docRef.id;
  }

  // cursos de un profesor
  Stream<List<Course>> listenCoursesByTeacher(String teacher_id) {
    return _coursesCollection
        .where('teacher_id', isEqualTo: teacher_id)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Course.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }
}
