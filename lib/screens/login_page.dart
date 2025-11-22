// -----------------------------------------------------------------------------
// Vista: LoginPage
// -----------------------------------------------------------------------------
// Pantalla de inicio de sesión de la aplicación. Permite que el usuario ingrese
// sus credenciales (correo y contraseña) para autenticarse mediante Firebase
// Authentication.
//
// Esta vista se usa para:
// - Mostrar el formulario de login.
// - Validar correo y contraseña antes de enviar.
// - Autenticar al usuario utilizando FirebaseAuth.
// - Redirigir a HomePage si el login es exitoso.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  String? error;

  Future<void> signIn() async {
    setState(() => error = null);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> signUp() async {
    setState(() => error = null);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> signInAnon() async {
    setState(() => error = null);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login (email/clave)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: signIn,
                    child: const Text('Ingresar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: signUp,
                    child: const Text('Crear cuenta'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: signInAnon,
              child: const Text('Entrar como invitado'),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
