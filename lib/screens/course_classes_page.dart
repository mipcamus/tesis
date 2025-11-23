// -----------------------------------------------------------------------------
// Vista: CourseClassesPage
// -----------------------------------------------------------------------------
// Muestra todas las clases programadas de un curso seleccionado. Esta pantalla
// permite al usuario ver la lista de CourseClass asociadas a un curso
//
// Esta vista se usa para:
// - Listar las clases del curso (CourseClass).
// - Mostrar fecha, estado (realizada / pendiente).
// - Navegar a páginas donde se gestiona o visualiza la asistencia.
// - Permitir marcar clases como realizadas, según permisos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    final uid = currentUser.uid;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = snap.data();
    final role = data?['role'] ?? 'student';

    setState(() {
      _isTeacher = role == 'teacher';
      _loadingRole = false;
    });
  }

  Future<void> _createClass() async {
    // Elegir fecha
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    // Elegir hora (opcional, pero útil)
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (pickedTime == null) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      await _classService.createClass(
        course_id: widget.course_id,
        date: dateTime,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clase creada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear clase: $e')));
    }
  }

  // NEW: marcar clase como realizada y mostrar modal con QR
  Future<void> _markClassAsDone(CourseClass courseClass) async {
    try {
      // Actualizamos el atributo done en Firestore
      await FirebaseFirestore.instance
          .collection('course_classes')
          .doc(courseClass.id)
          .update({'done': true});

      if (!mounted) return;

      // Modal con QR
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ClassQrDialog(courseClass: courseClass),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al marcar clase como realizada: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // aunque tarde un poquito en cargar el rol, igual podemos mostrar la lista
    return Scaffold(
      appBar: AppBar(title: const Text('Clases del curso')),
      body: StreamBuilder<List<CourseClass>>(
        stream: _classService.listenClassesByCourse(widget.course_id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar clases: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data!;

          if (classes.isEmpty) {
            return const Center(
              child: Text('Aún no hay clases creadas para este curso.'),
            );
          }

          return ListView.separated(
            itemCount: classes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final courseClass = classes[index];

              final formattedDate =
                  '${courseClass.date.day.toString().padLeft(2, '0')}/'
                  '${courseClass.date.month.toString().padLeft(2, '0')}/'
                  '${courseClass.date.year} '
                  '${courseClass.date.hour.toString().padLeft(2, '0')}:'
                  '${courseClass.date.minute.toString().padLeft(2, '0')}';

              final statusIcon = Icon(
                courseClass.done ? Icons.check_circle : Icons.schedule,
                color: courseClass.done ? Colors.green : Colors.grey,
              );

              return ListTile(
                title: Text('Clase ${index + 1}'),
                subtitle: Text(formattedDate),
                trailing: _isTeacher
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          statusIcon,
                          const SizedBox(width: 8),
                          if (!courseClass.done)
                            TextButton(
                              onPressed: () => _markClassAsDone(courseClass),
                              child: const Text('Marcar como realizada'),
                            ),
                        ],
                      )
                    : statusIcon,
                // aquí más adelante puedes abrir asistencia, etc.
              );
            },
          );
        },
      ),

      // FAB solo para profesores
      floatingActionButton: _isTeacher
          ? FloatingActionButton(
              onPressed: _createClass,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// NEW: Widget de la modal con QR (placeholder con ícono)
class _ClassQrDialog extends StatelessWidget {
  final CourseClass courseClass;

  const _ClassQrDialog({required this.courseClass});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Clase marcada como realizada',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pide a tus alumnos que escaneen este código QR para registrar su asistencia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            // Placeholder del QR
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2, size: 130, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
