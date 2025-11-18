import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course_class.dart';

class CourseClassesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retorna un stream con todas las clases de un curso,
  /// ordenadas por fecha.
  Stream<List<CourseClass>> listenClassesForCourse(String course_id) {
    final classesCollection = _firestore
        .collection('courses')
        .doc(course_id)
        .collection('classes');

    return classesCollection.orderBy('date').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourseClass.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// (para admin/profesor) Crear una clase nueva para un curso.
  Future<void> addClassToCourse({
    required String course_id,
    required DateTime date,
    required bool done,
  }) async {
    final classesCollection = _firestore
        .collection('courses')
        .doc(course_id)
        .collection('classes');

    await classesCollection.add({
      'course_id': course_id,
      'date': Timestamp.fromDate(date),
      'done': done,
    });
  }
}
