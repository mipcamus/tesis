// -----------------------------------------------------------------------------
// Vista: CoursesPage
// -----------------------------------------------------------------------------
// Muestra la lista de cursos en los que el usuario/alumno está inscrito.
// Esta vista es el punto de entrada del usuario para navegar por sus cursos,
// ver sus clases y la asistencia correspondiente.
//
// Esta vista se usa para:
// - Ver cursos en los que el usuario está inscrito.
// - Obtener la información de cada curso desde CourseService.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../models/course.dart';
import '../services/course_service.dart';
import '../services/user_courses_service.dart';
import 'attendance_page.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final courseService = CourseService();
    final userCoursesService = UserCoursesService();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis cursos')),
      body: StreamBuilder<Set<String>>(
        stream: userCoursesService.listenEnrolledCourseIds(),
        builder: (context, enrolledSnapshot) {
          if (enrolledSnapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar tus cursos: ${enrolledSnapshot.error}',
              ),
            );
          }

          if (!enrolledSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final enrolledIds = enrolledSnapshot.data ?? <String>{};

          if (enrolledIds.isEmpty) {
            return const Center(child: Text('Aún no tienes cursos asignados.'));
          }

          // Ahora pedimos a Firestore solo los cursos con esos IDs
          return StreamBuilder<List<Course>>(
            stream: courseService.listenCoursesByIds(enrolledIds),
            builder: (context, coursesSnapshot) {
              if (coursesSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar cursos: ${coursesSnapshot.error}',
                  ),
                );
              }

              if (!coursesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = coursesSnapshot.data!;

              if (courses.isEmpty) {
                return const Center(
                  child: Text('No se encontraron cursos para este usuario.'),
                );
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
                          builder: (_) => AttendancePage(courseId: course.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
