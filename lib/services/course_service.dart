// este servicio contiene los metodos de la clase curso

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/courses.dart';

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

  // Metodo para traer los cursos del usuario actual
  Stream<List<Course>> listenCoursesByIds(Set<String> ids) {
    if (ids.isEmpty) {
      // si no tiene cursos asignados, devolvemos lista vacía
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
}
