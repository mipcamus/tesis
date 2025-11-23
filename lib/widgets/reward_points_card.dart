// -----------------------------------------------------------------------------
// Widget: RewardPointsCard
// -----------------------------------------------------------------------------
// Muestra la cantidad total de puntos de recompensa del usuario actual.
// Usa RewardService para escuchar los cambios en tiempo real.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../services/reward_service.dart';
import '../services/attendance_stats_service.dart'; // NUEVO

class RewardPointsCard extends StatelessWidget {
  const RewardPointsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardService = RewardService();
    final attendanceStatsService = AttendanceStatsService(); // NUEVO

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF083F2D), // verde oscuro
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/reward_wallpaper.jpg'),
          fit: BoxFit.cover,
          opacity: 0.25,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        // NUEVO: primero pedimos el % de asistencia total
        child: FutureBuilder<double>(
          future: attendanceStatsService
              .get_total_attendance_percentage_for_current_student(),
          builder: (context, attendanceSnapshot) {
            double attendancePercent = 0;
            if (attendanceSnapshot.hasData) {
              attendancePercent = attendanceSnapshot.data ?? 0;
              if (attendancePercent < 0) attendancePercent = 0;
              if (attendancePercent > 100) attendancePercent = 100;
            }

            return StreamBuilder<int>(
              stream: rewardService.listen_current_user_points(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Error al cargar puntos: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  );
                }

                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final points = snapshot.data ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mensaje motivacional
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '😀 ',
                          style: TextStyle(fontSize: 28, color: Colors.white),
                        ),
                        Text(
                          '¡Sigue así, vas genial!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Número gigante
                    Text(
                      '$points Puntos',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // TEXTO ACTUALIZADO: usa el % real
                    Text(
                      'Has asistido al ${attendancePercent.toStringAsFixed(0)}% de tus clases.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE5F6EE),
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
