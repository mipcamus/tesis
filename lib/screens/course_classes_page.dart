import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/course_class.dart';
import '../services/course_classes_service.dart';

class CourseClassesPage extends StatefulWidget {
  final String course_id;

  const CourseClassesPage({super.key, required this.course_id});

  @override
  State<CourseClassesPage> createState() => _CourseClassesPageState();
}

class _CourseClassesPageState extends State<CourseClassesPage> {
  final _classService = CourseClassService();
  bool _isTeacher = false;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isTeacher = false;
        _loadingRole = false;
      });
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    setState(() {
      _isTeacher = snap.data()?['role'] == 'teacher';
      _loadingRole = false;
    });
  }

  String _generateQrToken() {
    final random = Random.secure();
    return List.generate(
      32,
      (_) => random.nextInt(36).toRadixString(36),
    ).join();
  }

  Future<void> _markClassAsDone(CourseClass courseClass) async {
    try {
      final token = _generateQrToken();

      await FirebaseFirestore.instance
          .collection('course_classes')
          .doc(courseClass.id)
          .update({
            'done': true,
            'qr_token': token,
            'qr_issuedAt': FieldValue.serverTimestamp(),
            'qr_validMinutes': 30,
          });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ClassQrDialog(classId: courseClass.id, qrToken: token),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// ✅ Crear una clase (rápido) en Firestore
  Future<void> _createNewClass() async {
    try {
      // 1) Elegir fecha/hora de la clase
      final now = DateTime.now();
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 2),
      );
      if (pickedDate == null) return;

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );
      if (pickedTime == null) return;

      final classDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // 2) Guardar en Firestore
      await FirebaseFirestore.instance.collection('course_classes').add({
        'course_id': widget.course_id,
        'date': Timestamp.fromDate(classDateTime),
        'done': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Clase creada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error creando clase: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clases del curso')),

      // ✅ AQUÍ vuelve el botón "+"
      floatingActionButton: _isTeacher
          ? FloatingActionButton(
              onPressed: _createNewClass,
              child: const Icon(Icons.add),
            )
          : null,

      body: StreamBuilder<List<CourseClass>>(
        stream: _classService.listenClassesByCourse(widget.course_id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data!;

          if (classes.isEmpty) {
            return const Center(child: Text('No hay clases aún.'));
          }

          return ListView.separated(
            itemCount: classes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = classes[index];
              return ListTile(
                title: Text('Clase ${index + 1}'),
                subtitle: Text(c.date.toString()),
                trailing: _isTeacher
                    ? (c.done
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : TextButton(
                              onPressed: () => _markClassAsDone(c),
                              child: const Text('Marcar como realizada'),
                            ))
                    : Icon(
                        Icons.check_circle,
                        color: c.done ? Colors.green : Colors.grey,
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClassQrDialog extends StatelessWidget {
  final String classId;
  final String qrToken;

  const _ClassQrDialog({required this.classId, required this.qrToken});

  @override
  Widget build(BuildContext context) {
    // ✅ Payload real en JSON (esto sí lo podrás leer al escanear)
    final qrPayload = jsonEncode({'class_id': classId, 'token': qrToken});

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Clase marcada como realizada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Los estudiantes deben escanear este QR para registrar su asistencia.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ✅ QR real (JSON)
            QrImageView(data: qrPayload, size: 230),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
