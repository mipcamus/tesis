// -----------------------------------------------------------------------------
// Servicio: ClassAttendanceService
// -----------------------------------------------------------------------------
// Servicio encargado de manejar toda la lógica relacionada con la asistencia de
// los alumnos a las clases.
//
// Este servicio se usa para:
// - Registrar asistencia de un alumno a una clase.
// - Obtener la asistencia de un alumno para una clase específica.
// - Obtener la asistencia completa de un curso (todas las clases).
//
// Notas:
// - Este servicio asegura que cada alumno tenga máximo un registro por clase.
// - Evita duplicados mediante combinaciones class_id + student_id.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/class_attendance.dart';
import 'reward_service.dart';

class ClassAttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RewardService _rewardService = RewardService();

  CollectionReference<Map<String, dynamic>> get _attendanceCollection {
    return _firestore.collection('class_attendance');
  }

  CollectionReference<Map<String, dynamic>> get _classesCollection {
    return _firestore.collection('course_classes');
  }

  static const int attendancePoints = 10;
  static const int streak3BonusPoints = 20;

  /// Marca asistencia y devuelve:
  /// true  => hubo bonus por racha
  /// false => asistencia normal
  Future<bool> markAttendance({
    required String course_id,
    required String class_id,
    required String student_id,
  }) async {
    final doc_id = '${class_id}_$student_id';
    final ref = _attendanceCollection.doc(doc_id);

    bool becamePresent = false;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final now = DateTime.now();

      if (!snapshot.exists) {
        final attendance = ClassAttendance(
          id: doc_id,
          course_id: course_id,
          class_id: class_id,
          student_id: student_id,
          present: true,
          createdAt: now,
        );

        transaction.set(ref, attendance.toMap());

        await _rewardService.add_points_to_current_user(attendancePoints);
        becamePresent = true;
      } else {
        final data = snapshot.data() as Map<String, dynamic>;
        final wasPresent = data['present'] == true;

        if (!wasPresent) {
          transaction.update(ref, {
            'present': true,
            'updatedAt': now.toIso8601String(),
          });

          await _rewardService.add_points_to_current_user(attendancePoints);
          becamePresent = true;
        } else {
          transaction.update(ref, {'updatedAt': now.toIso8601String()});
        }
      }
    });

    if (becamePresent) {
      try {
        final gotBonus = await _checkThreeInARowReward(
          course_id: course_id,
          student_id: student_id,
        );
        return gotBonus;
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  /// Devuelve true si se otorgó el bonus de racha
  Future<bool> _checkThreeInARowReward({
    required String course_id,
    required String student_id,
  }) async {
    final classesSnap = await _classesCollection
        .where('course_id', isEqualTo: course_id)
        .where('done', isEqualTo: true)
        .orderBy('date', descending: true)
        .limit(3)
        .get();

    if (classesSnap.docs.length < 3) return false;

    final classIds = classesSnap.docs.map((d) => d.id).toList();

    final attendanceSnap = await _attendanceCollection
        .where('class_id', whereIn: classIds)
        .where('student_id', isEqualTo: student_id)
        .where('present', isEqualTo: true)
        .get();

    if (attendanceSnap.docs.length < 3) return false;

    final latestClassId = classIds.first;
    final latestDocId = '${latestClassId}_$student_id';
    final latestDoc = await _attendanceCollection.doc(latestDocId).get();

    final latestData = latestDoc.data() as Map<String, dynamic>? ?? {};
    final alreadyRewarded = latestData['streak3_reward'] == true;

    if (alreadyRewarded) return false;

    await _rewardService.add_points_to_current_user(streak3BonusPoints);

    await _attendanceCollection.doc(latestDocId).update({
      'streak3_reward': true,
    });

    return true;
  }

  Stream<List<ClassAttendance>> listenAttendanceForStudentInCourse({
    required String course_id,
    required String student_id,
  }) {
    return _attendanceCollection
        .where('course_id', isEqualTo: course_id)
        .where('student_id', isEqualTo: student_id)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ClassAttendance.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<ClassAttendance?> listenAttendanceForClassAndStudent({
    required String class_id,
    required String student_id,
  }) {
    final doc_id = '${class_id}_$student_id';

    return _attendanceCollection.doc(doc_id).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ClassAttendance.fromFirestore(
        snap.id,
        snap.data() as Map<String, dynamic>,
      );
    });
  }
}
