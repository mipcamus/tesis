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
// - Registra eventos para evidencias de prueba (examen).
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/class_attendance.dart'; // ✅ ruta correcta
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

  CollectionReference<Map<String, dynamic>> get _eventsCollection {
    return _firestore.collection('events');
  }

  static const int attendancePoints = 10;
  static const int streak3BonusPoints = 20;

  // ---------------------------------------------------------------------------
  // ✅ Registrar asistencia escaneando QR (Alumno)
  // ---------------------------------------------------------------------------
  /// qrData puede venir como:
  /// 1) JSON: {"class_id":"...","token":"..."}  (tu QrScanPage actual)
  /// 2) JSON: {"class_id":"...","qr_token":"..."} (también soportado)
  /// 3) Texto: "classId|token"
  ///
  /// Retorna:
  /// - true  => hubo bonus por racha
  /// - false => asistencia normal (o duplicado)
  ///
  /// Lanza Exception si:
  /// - QR inválido / formato incorrecto
  /// - Clase no existe
  /// - Token no coincide
  /// - QR expirado
  Future<bool> markAttendanceByQr({
    required String qrData,
    required String student_id,
  }) async {
    String? classId;
    String? token;

    final trimmed = qrData.trim();

    // 1) Intentar JSON
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          classId = decoded['class_id']?.toString();

          // ✅ Acepta "token" (QrScanPage) o "qr_token"
          token = (decoded['token'] ?? decoded['qr_token'])?.toString();
        }
      } catch (_) {
        // seguimos a parseo alternativo
      }
    }

    // 2) Intentar formato "classId|token"
    if ((classId == null || token == null) && trimmed.contains('|')) {
      final parts = trimmed.split('|');
      if (parts.length >= 2) {
        classId = parts[0].trim();
        token = parts[1].trim();
      }
    }

    if (classId == null || classId.isEmpty || token == null || token.isEmpty) {
      await _eventsCollection.add({
        'type': 'qr_scan_invalid_format',
        'student_id': student_id,
        'raw': trimmed,
        'createdAt': DateTime.now().toIso8601String(),
      });
      throw Exception('QR inválido (formato no reconocido).');
    }

    // Buscar clase en Firestore
    final classSnap = await _classesCollection.doc(classId).get();
    if (!classSnap.exists || classSnap.data() == null) {
      await _eventsCollection.add({
        'type': 'qr_scan_class_not_found',
        'student_id': student_id,
        'class_id': classId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      throw Exception('Clase no existe.');
    }

    final classData = classSnap.data()!;
    final storedToken = (classData['qr_token'] ?? '').toString(); // Firestore
    final courseId = (classData['course_id'] ?? '').toString();

    if (courseId.isEmpty) {
      await _eventsCollection.add({
        'type': 'qr_scan_missing_course_id',
        'student_id': student_id,
        'class_id': classId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      throw Exception('La clase no tiene course_id.');
    }

    if (storedToken.isEmpty || storedToken != token) {
      await _eventsCollection.add({
        'type': 'qr_scan_token_mismatch',
        'student_id': student_id,
        'class_id': classId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      throw Exception('QR inválido (token no coincide).');
    }

    // Validar expiración
    final issuedAtRaw = classData['qr_issuedAt'];
    final validMinutesRaw = classData['qr_validMinutes'];

    DateTime? issuedAt;
    if (issuedAtRaw is Timestamp) {
      issuedAt = issuedAtRaw.toDate();
    } else if (issuedAtRaw is String) {
      issuedAt = DateTime.tryParse(issuedAtRaw);
    }

    final int? validMinutes = (validMinutesRaw is int)
        ? validMinutesRaw
        : int.tryParse((validMinutesRaw ?? '').toString());

    if (issuedAt == null || validMinutes == null || validMinutes <= 0) {
      await _eventsCollection.add({
        'type': 'qr_scan_missing_expiration_data',
        'student_id': student_id,
        'class_id': classId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      throw Exception('El QR no tiene datos de expiración válidos.');
    }

    final expiresAt = issuedAt.add(Duration(minutes: validMinutes));
    final now = DateTime.now();

    if (now.isAfter(expiresAt)) {
      await _eventsCollection.add({
        'type': 'qr_scan_expired',
        'student_id': student_id,
        'class_id': classId,
        'expiresAt': expiresAt.toIso8601String(),
        'createdAt': now.toIso8601String(),
      });
      throw Exception('QR expirado.');
    }

    // ✅ Si todo ok, registrar asistencia normal (reutilizamos tu método)
    await _eventsCollection.add({
      'type': 'qr_scan_valid',
      'student_id': student_id,
      'class_id': classId,
      'course_id': courseId,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return markAttendance(
      course_id: courseId,
      class_id: classId,
      student_id: student_id,
    );
  }

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

        transaction.set(_eventsCollection.doc(), {
          'type': 'attendance_registered',
          'course_id': course_id,
          'class_id': class_id,
          'student_id': student_id,
          'createdAt': now.toIso8601String(),
        });
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

          transaction.set(_eventsCollection.doc(), {
            'type': 'attendance_updated',
            'course_id': course_id,
            'class_id': class_id,
            'student_id': student_id,
            'createdAt': now.toIso8601String(),
          });
        } else {
          transaction.update(ref, {'updatedAt': now.toIso8601String()});

          transaction.set(_eventsCollection.doc(), {
            'type': 'attendance_duplicate_attempt',
            'course_id': course_id,
            'class_id': class_id,
            'student_id': student_id,
            'createdAt': now.toIso8601String(),
          });
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

    await _eventsCollection.add({
      'type': 'streak3_bonus_granted',
      'course_id': course_id,
      'class_id': latestClassId,
      'student_id': student_id,
      'createdAt': DateTime.now().toIso8601String(),
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
      return ClassAttendance.fromFirestore(snap.id, snap.data()!);
    });
  }
}
