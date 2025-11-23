// -----------------------------------------------------------------------------
// Vista: RewardsPage
// -----------------------------------------------------------------------------
// Pantalla que muestra las recompensas del usuario.
// Por ahora, se centra en mostrar el total de puntos de recompensa.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../widgets/reward_points_card.dart';
import '../widgets/how_to_earn_points.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis recompensas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            RewardPointsCard(),
            SizedBox(height: 24),

            HowToEarnPoints(),
          ],
        ),
      ),
    );
  }
}
