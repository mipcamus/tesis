// -----------------------------------------------------------------------------
// Widget: HowToEarnPoints
// -----------------------------------------------------------------------------
// Muestra un grid informativo con 4 formas de ganar puntos.
// No tiene interacción: solo es visual.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class HowToEarnPoints extends StatelessWidget {
  const HowToEarnPoints({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cómo ganar puntos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),

        // Grid de 2x2
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            PointsInfoCard(
              title: 'Asistencia',
              description: '+10 pts',
              color: Color(0xFF22C55E), // Verde
              icon: Icons.verified,
            ),
            PointsInfoCard(
              title: 'Puntualidad',
              description: '+5 pts extra',
              color: Color(0xFF3B82F6), // Azul
              icon: Icons.access_time,
            ),
            PointsInfoCard(
              title: 'Desafíos',
              description: 'Hasta +50 pts',
              color: Color(0xFFF59E0B), // Amarillo/naranja
              icon: Icons.emoji_events,
            ),
            PointsInfoCard(
              title: 'Participación',
              description: 'Pregunta al profe',
              color: Color(0xFFA855F7), // Púrpura
              icon: Icons.groups,
            ),
          ],
        ),
      ],
    );
  }
}

class PointsInfoCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  const PointsInfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // fondo oscuro bonito
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono redondo de color
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
