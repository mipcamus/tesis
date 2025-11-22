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
        courseId: widget.course_id,
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

              return ListTile(
                title: Text('Clase ${index + 1}'),
                subtitle: Text(formattedDate),
                trailing: Icon(
                  courseClass.done ? Icons.check_circle : Icons.schedule,
                  color: courseClass.done ? Colors.green : Colors.grey,
                ),
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
