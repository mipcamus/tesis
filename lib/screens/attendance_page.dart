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

  // Modal de recompensa por asistencia (+10 puntos)
  Future<void> _showAttendanceRewardDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Asistencia registrada',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Has ganado +10 puntos. Sigue así.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Genial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modal de recompensa por racha de 3 clases seguidas (+20 puntos)
  Future<void> _showStreakBonusDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Racha de asistencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Has asistido a 3 clases seguidas.\nHas ganado +20 puntos extra.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAttendance(CourseClass courseClass) async {
    if (_student_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay usuario autenticado')),
      );
      return;
    }

    try {
      final gotBonus = await _attendanceService.markAttendance(
        course_id: courseClass.course_id,
        class_id: courseClass.id,
        student_id: _student_id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Asistencia registrada')));

      await _showAttendanceRewardDialog();

      if (gotBonus) {
        await _showStreakBonusDialog();
      }
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

          final allClasses = classesSnapshot.data!;
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

                  final alreadyMarked = attendanceList.any(
                    (att) =>
                        att.class_id == courseClass.id && att.present == true,
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
