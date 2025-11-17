// este servicio contiene los metodos de los cursos inscritos

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserCoursesService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario logueado');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _enrolledCollection {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('enrolledCourses');
  }

  // Metodo que trae los cursos asignados
  Stream<Set<String>> listenEnrolledCourseIds() {
    return _enrolledCollection.snapshots().map((snapshot) {
      final ids = snapshot.docs.map((doc) => doc.id).toSet();
      return ids;
    });
  }
}
