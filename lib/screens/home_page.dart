// -----------------------------------------------------------------------------
// Vista: HomePage
// -----------------------------------------------------------------------------
// Pantalla principal de la aplicación una vez que el usuario ha iniciado sesión.
// Funciona como el punto central de navegación, permitiendo acceder a las
// distintas secciones: cursos, clases, usuarios, asistencia, etc.
//
// Esta vista se usa para:
// - Mostrar el menú o las opciones principales de la aplicación.
// - Redirigir al usuario a las páginas
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'courses_page.dart';
import 'create_user_page.dart';
import 'create_course_page.dart';
import 'teacher_courses_page.dart';

class HomePage extends StatelessWidget {
  final String email;

  const HomePage({super.key, required this.email});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Por seguridad: si no hay usuario logueado, podrías redirigir al login
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario autenticado')),
      );
    }

    final uid = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar usuario: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          final role = data?['role'] ?? 'student'; // valor por defecto

          final isTeacher = role == 'teacher';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bienvenido, $email'),
                const SizedBox(height: 20),

                // Botón para ver cursos donde está inscrito (usa course_students vía UserCoursesService)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CoursesPage()),
                    );
                  },
                  child: const Text('Ver cursos'),
                ),

                const SizedBox(height: 20),

                // Ver mis cursos (como profesor, usa teacher_id en courses)
                if (isTeacher)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TeacherCoursesPage(),
                        ),
                      );
                    },
                    label: const Text('Ver mis cursos (profesor)'),
                  ),

                const SizedBox(height: 10),

                // profesor: botón para crear usuario
                if (isTeacher)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateUserPage(),
                        ),
                      );
                    },
                    label: const Text('Crear usuario'),
                  ),

                const SizedBox(height: 10),

                // profesor: botón para crear curso
                if (isTeacher)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateCoursePage(),
                        ),
                      );
                    },
                    label: const Text('Crear curso'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
