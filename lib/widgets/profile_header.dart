// -----------------------------------------------------------------------------
// Widget: ProfileHeader
// -----------------------------------------------------------------------------
// Muestra la información básica del usuario (nombre, rol, RUT) y un botón
// para editar el perfil. Pensado para usarse en la HomePage o en una pantalla
// de "Perfil y configuración".
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../models/user.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEditProfile;

  const ProfileHeader({super.key, required this.user, this.onEditProfile});

  String _readableRole(String role) {
    switch (role) {
      case 'teacher':
        return 'Profesor';
      case 'student':
        return 'Estudiante';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.name} ${user.last_name}'.trim();
    final initials = [
      if (user.name.isNotEmpty) user.name[0],
      if (user.last_name.isNotEmpty) user.last_name[0],
    ].join().toUpperCase();

    final roleText = _readableRole(user.role);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circular (más adelante se puede cambiar a foto real)
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nombre completo
            Text(
              fullName.isEmpty ? user.mail : fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 4),

            // Rol + RUT / ID
            Text(
              '$roleText • RUT: ${user.rut}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),

            const SizedBox(height: 20),

            // Botón "Editar perfil"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onEditProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Editar perfil',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
