// -----------------------------------------------------------------------------
// Vista: CourseStudentsPage
// -----------------------------------------------------------------------------
// Muestra y gestiona la lista de alumnos inscritos en un curso específico.
// Permite visualizar los estudiantes asociados al curso y añadir nuevos alumnos
// mediante su correo electrónico.
//
// Esta vista se usa para:
// - Consultar alumnos inscritos en el curso en tiempo real (Firestore).
// - Inscribir un nuevo estudiante ingresando su correo electrónico.
// - Validar si el usuario existe y agregarlo al curso mediante CourseStudentsService.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course.dart';
import '../models/user.dart';
import '../services/course_students_service.dart';

class CourseStudentsPage extends StatefulWidget {
  final Course course;

  const CourseStudentsPage({super.key, required this.course});

  @override
  State<CourseStudentsPage> createState() => _CourseStudentsPageState();
}

class _CourseStudentsPageState extends State<CourseStudentsPage> {
  final CourseStudentsService _studentsService = CourseStudentsService();
  bool _isAdding = false;

  Future<void> _showAddStudentDialog() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Inscribir alumno'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Correo del alumno',
              hintText: 'alumno@colegio.cl',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // cerrar
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un correo')),
                  );
                  return;
                }

                Navigator.pop(context); // cerrar el diálogo
                await _addStudentByEmail(email);
              },
              child: const Text('Inscribir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addStudentByEmail(String email) async {
    if (_isAdding) return;

    setState(() => _isAdding = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Buscar usuario por correo (campo 'mail')
      final query = await firestore
          .collection('users')
          .where('mail', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontró usuario con el correo $email'),
          ),
        );
        return;
      }

      final userDoc = query.docs.first;
      final student_id = userDoc.id;

      await _studentsService.enrollStudentInCourse(
        course_id: widget.course.id,
        student_id: student_id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alumno inscrito correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al inscribir alumno: $e')));
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      appBar: AppBar(title: Text('Alumnos de ${course.title}')),

      body: StreamBuilder<List<UserModel>>(
        stream: _studentsService.listenStudentsByCourse(course.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar alumnos: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!;

          if (students.isEmpty) {
            return const Center(
              child: Text('Aún no hay alumnos inscritos en este curso.'),
            );
          }

          return ListView.separated(
            itemCount: students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = students[index];

              return ListTile(
                title: Text('${student.name} ${student.last_name}'),
                subtitle: Text('${student.mail}\nRUT: ${student.rut}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),

      // 👉 Botón flotante + para inscribir alumno
      floatingActionButton: FloatingActionButton(
        onPressed: _isAdding ? null : _showAddStudentDialog,
        child: _isAdding
            ? const CircularProgressIndicator()
            : const Icon(Icons.add),
      ),
    );
  }
}
