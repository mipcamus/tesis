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
}
