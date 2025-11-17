// esta es la vista de cursos
import 'package:flutter/material.dart';

import '../models/courses.dart';
import '../services/course_service.dart';
import '../services/user_courses_service.dart';

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

          // Esto trae los cursos del usuario actual
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
