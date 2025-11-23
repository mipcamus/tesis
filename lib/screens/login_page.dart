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
// - Redirigir a HomePage si el login es exitoso (manejado por el Stream de auth).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';
import '../services/auth_session_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  String? error;

  final UserService _userService = UserService();

  Future<void> signIn() async {
    setState(() => error = null);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      // ✅ MVP simple: si el login fue correcto, guardamos SIEMPRE
      // las credenciales en memoria. Asumimos que solo los profesores
      // verán la pantalla de crear usuario.
      AuthSession.teacherEmail = email.text.trim();
      AuthSession.teacherPassword = pass.text.trim();

      // La navegación a Home la manejas con tu Stream de auth en main.dart
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> signUp() async {
    setState(() => error = null);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      final uid = cred.user!.uid;

      await _userService.createUserDocument(
        uid: uid,
        name: '',
        last_name: '',
        rut: '',
        mail: email.text.trim(),
        role: 'student', // por defecto alumno
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
              ],
            ),
            const SizedBox(height: 8),
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
