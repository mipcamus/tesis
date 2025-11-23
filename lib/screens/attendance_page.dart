// -----------------------------------------------------------------------------
// Vista: AttendancePage
// -----------------------------------------------------------------------------
// Pantalla encargada de mostrar la asistencia de un alumno en un curso
// Aquí se listan las clases del curso junto con su estado (si fue o no fue).
//
// Esta vista se usa para:
// - Consultar todas las clases del curso (CourseClass).
// - Obtener la asistencia del alumno desde ClassAttendance.
// - Mostrar visualmente si el alumno asistió o no a cada clase.
// - Permitir marcar asistencia.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/course_class.dart';
import '../models/class_attendance.dart';
import '../services/course_classes_service.dart';
import '../services/class_attendance_service.dart';

class AttendancePage extends StatefulWidget {
  final String course_id;

  const AttendancePage({super.key, required this.course_id});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _classService = CourseClassService();
  final _attendanceService = ClassAttendanceService();

  String? _student_id;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _student_id = user?.uid;
      _loadingUser = false;
    });
  }

  Future<void> _markAttendance(CourseClass courseClass) async {
    if (_student_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay usuario autenticado')),
      );
      return;
    }

    try {
      await _attendanceService.markAttendance(
        course_id: courseClass.course_id,
        class_id: courseClass.id,
        student_id: _student_id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Asistencia registrada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al marcar asistencia: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_student_id == null) {
      return const Scaffold(
        body: Center(child: Text('No hay alumno autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Asistencias')),
      body: StreamBuilder<List<CourseClass>>(
        stream: _classService.listenClassesByCourse(widget.course_id),
        builder: (context, classesSnapshot) {
          if (classesSnapshot.hasError) {
            return Center(
              child: Text('Error al cargar clases: ${classesSnapshot.error}'),
            );
          }

          if (!classesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Todas las clases de ese curso
          final allClasses = classesSnapshot.data!;

          // Solo clases con done == true
          final doneClasses = allClasses.where((c) => c.done == true).toList();

          if (doneClasses.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay clases disponibles para marcar asistencia.',
              ),
            );
          }

          return StreamBuilder<List<ClassAttendance>>(
            stream: _attendanceService.listenAttendanceForStudentInCourse(
              course_id: widget.course_id,
              student_id: _student_id!,
            ),
            builder: (context, attendanceSnapshot) {
              if (attendanceSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar asistencias: ${attendanceSnapshot.error}',
                  ),
                );
              }

              if (!attendanceSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final attendanceList = attendanceSnapshot.data!;

              return ListView.separated(
                itemCount: doneClasses.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final courseClass = doneClasses[index];

                  // ¿Este alumno ya marcó asistencia en esta clase?
                  final alreadyMarked = attendanceList.any(
                    (att) => att.class_id == courseClass.id && att.present,
                  );

                  final date = courseClass.date;
                  final formattedDate =
                      '${date.day.toString().padLeft(2, '0')}/'
                      '${date.month.toString().padLeft(2, '0')}/'
                      '${date.year} '
                      '${date.hour.toString().padLeft(2, '0')}:'
                      '${date.minute.toString().padLeft(2, '0')}';

                  return ListTile(
                    title: Text('Clase ${index + 1}'),
                    subtitle: Text(formattedDate),
                    trailing: alreadyMarked
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Asistió'),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () => _markAttendance(courseClass),
                            child: const Text('Marcar asistencia'),
                          ),
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
