// lib/widgets/low_attendance_students.dart

// -----------------------------------------------------------------------------
// Widget: LowAttendanceStudents
// -----------------------------------------------------------------------------
// Muestra el listado de alumnos de un curso con asistencia < 60%.
// - Rojo si < 50%
// - Amarillo si 50%–59%
// Incluye botón "Contactar" que abre la app de correo.
// Exclusivo para vistas de profesor.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/course.dart';
import '../models/user.dart';
import '../services/course_students_service.dart';
import '../services/attendance_stats_service.dart';

class LowAttendanceStudents extends StatefulWidget {
  final Course course;

  const LowAttendanceStudents({super.key, required this.course});

  @override
  State<LowAttendanceStudents> createState() => _LowAttendanceStudentsState();
}

class _LowAttendanceStudentsState extends State<LowAttendanceStudents> {
  final CourseStudentsService _studentsService = CourseStudentsService();
  final AttendanceStatsService _statsService = AttendanceStatsService();

  Future<void> _contactStudent(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=Asistencia%20del%20curso&body=Hola,%20queremos%20hablar%20sobre%20tu%20asistencia%20en%20el%20curso%20${widget.course.title}.',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de correo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _studentsService.listenStudentsByCourse(widget.course.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error al cargar alumnos: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final students = snapshot.data!;
        if (students.isEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<_StudentAttendance>>(
          future: _calculateStudentsAttendance(students),
          builder: (context, attSnapshot) {
            if (attSnapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al calcular asistencia: ${attSnapshot.error}',
                ),
              );
            }

            if (!attSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final allStats = attSnapshot.data!;
            final lowAttendance = allStats
                .where((item) => item.percentage < 60.0)
                .toList();

            if (lowAttendance.isEmpty) {
              // Si todos están bien, no mostramos nada
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alumnos con baja asistencia (< 60%)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: lowAttendance.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = lowAttendance[index];

                      final color = item.percentage < 50
                          ? Colors.red
                          : Colors.orange.shade700;

                      return ListTile(
                        title: Text(
                          '${item.student.name} ${item.student.last_name}',
                        ),
                        subtitle: Text(
                          '${item.percentage.toStringAsFixed(0)}% de asistencia',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _contactStudent(item.student.mail),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Contactar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_StudentAttendance>> _calculateStudentsAttendance(
    List<UserModel> students,
  ) async {
    final List<_StudentAttendance> result = [];

    for (final s in students) {
      final stats = await _statsService.get_course_attendance_stats_for_student(
        course_id: widget.course.id,
        student_id: s.id,
      );

      result.add(_StudentAttendance(student: s, percentage: stats.percentage));
    }

    return result;
  }
}

class _StudentAttendance {
  final UserModel student;
  final double percentage;

  _StudentAttendance({required this.student, required this.percentage});
}
