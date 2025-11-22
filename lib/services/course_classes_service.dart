// -----------------------------------------------------------------------------
// Servicio: CourseClassesService
// -----------------------------------------------------------------------------
// Servicio encargado de manejar las operaciones relacionadas con las clases
// (CourseClass) de un curso. Centraliza la comunicación con Firestore para
// obtener, crear y actualizar las clases asociadas a un curso.
//
// Este servicio se usa para:
// - Obtener todas las clases de un curso específico.
// - Crear nuevas clases dentro de un curso (fechas, estado, etc.).
// - Actualizar el estado de una clase (por ejemplo: marcarla como realizada).
//
// Notas:
// - Todas las clases deben estar asociadas a un course_id válido.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course_class.dart';

class CourseClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _classesCollection {
    return _firestore.collection('course_classes');
  }

  /// clases de un curso específico
  Stream<List<CourseClass>> listenClassesByCourse(String course_id) {
    return _classesCollection
        .where('course_id', isEqualTo: course_id)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CourseClass.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  /// Crear una clase para un curso
  Future<String> createClass({
    required String course_id,
    required DateTime date,
  }) async {
    final docRef = await _classesCollection.add({
      'course_id': course_id,
      'date': Timestamp.fromDate(date),
      'done': false,
    });

    return docRef.id;
  }
}
