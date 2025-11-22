// -----------------------------------------------------------------------------
// Vista: TeacherCoursesPage
// -----------------------------------------------------------------------------
// Muestra la lista de cursos asignados a un profesor. Esta pantalla permite que
// el docente visualice y administre los cursos que imparte, accediendo a sus
// clases, estudiantes, etc.
//
// Esta vista se usa para:
// - Obtener los cursos donde el usuario actual tiene rol de profesor.
// - Mostrar la lista completa de cursos asignados.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/course.dart';
import '../services/course_service.dart';
import 'course_classes_page.dart';
import 'course_students_page.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No hay profesor autenticado')),
      );
    }

    final teacher_id = currentUser.uid;
    final courseService = CourseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis cursos (profesor)')),
      body: StreamBuilder<List<Course>>(
        stream: courseService.listenCoursesByTeacher(teacher_id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar cursos: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!;

          if (courses.isEmpty) {
            return const Center(child: Text('Aún no has creado cursos.'));
          }

          return ListView.separated(
            itemCount: courses.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final course = courses[index];

              return ListTile(
                title: Text(course.title),
                subtitle: Text(course.description),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CourseStudentsPage(course: course),
                    ),
                  );
                },
                // botón secundario para ver clases:
                trailing: IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CourseClassesPage(course_id: course.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
