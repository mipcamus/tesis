// esta es la pagina de inicio

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'courses_page.dart';

class HomePage extends StatelessWidget {
  final String email;

  const HomePage({super.key, required this.email});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bienvenido, $email'),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const CoursesPage()));
              },
              child: const Text('Ver cursos'),
            ),
          ],
        ),
      ),
    );
  }
}
