// -----------------------------------------------------------------------------
// Servicio: UserService
// -----------------------------------------------------------------------------
// Servicio encargado de manejar todas las operaciones relacionadas con los
// usuarios dentro de la aplicación.
//
// Este servicio se usa para:
// - Crear un nuevo usuario en Firestore.
// - Verificar si un usuario existe antes de asociarlo a un curso.
// - Listar usuarios (por rol, curso, o criterios específicos).
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel?> listenUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap.id, snap.data()!);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromFirestore(snap.id, snap.data()!);
  }

  /// Crea (o actualiza) el documento del usuario en la colección `users`.
  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String last_name,
    required String rut,
    required String mail,
    String role = 'student', // por defecto alumno
  }) async {
    await _db.collection('users').doc(uid).set(
      {
        'name': name,
        'last_name': last_name,
        'rut': rut,
        'mail': mail,
        'role': role,
      },
      SetOptions(merge: true), // por si ya existía algo, no lo revienta
    );
  }
}
