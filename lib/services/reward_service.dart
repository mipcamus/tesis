// lib/services/reward_service.dart

// -----------------------------------------------------------------------------
// Servicio: RewardService
// -----------------------------------------------------------------------------
// Maneja los puntos de recompensa del usuario.
// - Guarda los puntos en el documento del usuario en Firestore.
// - Permite obtener, escuchar e incrementar los puntos.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario logueado');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _current_user_doc {
    return _firestore.collection('users').doc(_uid);
  }

  /// Obtiene los puntos actuales del usuario logueado.
  Future<int> get_current_user_points() async {
    final doc = await _current_user_doc.get();
    if (!doc.exists) {
      return 0;
    }
    final data = doc.data()!;
    final points = data['reward_points'];
    if (points is int) {
      return points;
    }
    return 0;
  }

  /// Devuelve un stream con los puntos actuales del usuario logueado.
  Stream<int> listen_current_user_points() {
    return _current_user_doc.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return 0;
      }
      final data = snapshot.data()!;
      final points = data['reward_points'];
      if (points is int) {
        return points;
      }
      return 0;
    });
  }

  /// Incrementa en [points] los puntos del usuario actual.
  /// Si el doc no existe, lo crea con ese valor.
  Future<void> add_points_to_current_user(int points) async {
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(_current_user_doc);

      if (!doc.exists) {
        transaction.set(_current_user_doc, {
          'reward_points': points,
        }, SetOptions(merge: true));
      } else {
        final current = (doc.data()?['reward_points'] ?? 0) as int;
        final updated = current + points;
        transaction.update(_current_user_doc, {'reward_points': updated});
      }
    });
  }
}
