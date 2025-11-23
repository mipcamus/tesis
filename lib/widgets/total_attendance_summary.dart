// -----------------------------------------------------------------------------
// Widget: TotalAttendanceSummary
// -----------------------------------------------------------------------------
// Muestra un resumen global de asistencia del alumno en todos sus cursos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../services/attendance_stats_service.dart';

class TotalAttendanceSummary extends StatelessWidget {
  const TotalAttendanceSummary({super.key});

  Color _getColorForPercentage(double p) {
    if (p >= 80) return Colors.green;
    if (p >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final statsService = AttendanceStatsService();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: StreamBuilder<double>(
        // 🔹 NUEVO: usamos un stream en vez de un future
        stream: statsService
            .listen_total_attendance_percentage_for_current_student(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar asistencia: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(),
              ),
            );
          }

          double p = snapshot.data ?? 0.0;
          if (p < 0) p = 0;
          if (p > 100) p = 100;

          final color = _getColorForPercentage(p);

          return SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Mi Asistencia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 14,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.transparent,
                          ),
                        ),
                        CircularProgressIndicator(
                          value: p / 100,
                          strokeWidth: 14,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                        Text(
                          '${p.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Asistencia Total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
