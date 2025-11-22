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
import '../services/attendance_stats_service.dart';
import 'attendance_page.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final course_service = CourseService();
    final user_courses_service = UserCoursesService();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis cursos')),
      body: StreamBuilder<Set<String>>(
        stream: user_courses_service.listenEnrolledCourseIds(),
        builder: (context, enrolled_snapshot) {
          if (enrolled_snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar tus cursos: ${enrolled_snapshot.error}',
              ),
            );
          }

          if (!enrolled_snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final enrolled_ids = enrolled_snapshot.data ?? <String>{};

          if (enrolled_ids.isEmpty) {
            return const Center(child: Text('Aún no tienes cursos asignados.'));
          }

          return StreamBuilder<List<Course>>(
            stream: course_service.listenCoursesByIds(enrolled_ids),
            builder: (context, courses_snapshot) {
              if (courses_snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar cursos: ${courses_snapshot.error}',
                  ),
                );
              }

              if (!courses_snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = courses_snapshot.data!;

              if (courses.isEmpty) {
                return const Center(
                  child: Text('No se encontraron cursos para este usuario.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return CourseCard(course: course);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final AttendanceStatsService _stats_service = AttendanceStatsService();

  CourseCard({super.key, required this.course});

  Color _get_color_for_percentage(double p) {
    if (p >= 80) return Colors.green;
    if (p >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _get_icon_for_percentage(double p) {
    if (p >= 80) return Icons.check_circle;
    if (p >= 60) return Icons.warning_amber_rounded;
    return Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CourseAttendanceStats>(
      stream: _stats_service.listen_course_attendance_stats(course.id),
      builder: (context, snapshot) {
        Widget inner;

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          inner = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          inner = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar asistencia: ${snapshot.error}'),
          );
        } else {
          final stats =
              snapshot.data ??
              CourseAttendanceStats(
                attended_count: 0,
                total_done_classes: 0,
                percentage: 0.0,
              );

          final p = stats.percentage;
          final color = _get_color_for_percentage(p);
          final icon = _get_icon_for_percentage(p);

          final percentage_text = '${p.toStringAsFixed(0)}%';

          String detail_text;
          if (stats.total_done_classes == 0) {
            detail_text = 'Aún no hay clases realizadas';
          } else {
            detail_text =
                '${stats.attended_count} de ${stats.total_done_classes} clases asistidas';
          }

          inner = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera fila: título + % + icono
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            percentage_text,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(icon, color: color),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.total_done_classes == 0
                      ? 0
                      : (p.clamp(0, 100) / 100),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              const SizedBox(height: 8),

              // Texto "X de Y clases asistidas"
              Text(
                detail_text,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          );
        }

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AttendancePage(course_id: course.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: inner,
          ),
        );
      },
    );
  }
}
