// -----------------------------------------------------------------------------
// Vista: RewardsPage
// -----------------------------------------------------------------------------
// Pantalla que muestra las recompensas del usuario.
// Por ahora, se centra en mostrar el total de puntos de recompensa.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../widgets/reward_points_card.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis recompensas')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: RewardPointsCard()),
      ),
    );
  }
}
