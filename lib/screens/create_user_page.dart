// -----------------------------------------------------------------------------
// Vista: CreateUserPage
// -----------------------------------------------------------------------------
// Pantalla utilizada para registrar un nuevo usuario dentro del sistema. Permite
// ingresar los datos básicos del alumno o profesor y crear su perfil en Firestore.
//
// Esta vista se usa para:
// - Mostrar un formulario para ingresar la información del nuevo usuario.
// - Validar campos como correo institucional y nombre.
// - Crear el usuario a través del servicio correspondiente (UserService).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'student';

  bool _isLoading = false;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Crear usuario en Firebase Auth
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = credential.user!.uid;

      // 2. Crear documento en Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'rut': _rutController.text.trim(),
        'mail': _emailController.text.trim(),
        'role': _selectedRole,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado correctamente')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear usuario')),

      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Form(
          key: _formKey,

          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese un nombre' : null,
              ),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese apellido' : null,
              ),

              TextFormField(
                controller: _rutController,
                decoration: const InputDecoration(labelText: 'RUT'),
                validator: (v) => v == null || v.isEmpty ? 'Ingrese rut' : null,
              ),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Correo inválido' : null,
              ),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),

              const SizedBox(height: 20),

              // Selección de rol
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Estudiante')),
                  DropdownMenuItem(value: 'teacher', child: Text('Profesor')),
                ],
                onChanged: (value) {
                  setState(() => _selectedRole = value!);
                },
              ),

              const SizedBox(height: 30),

              // Botón para crear usuario
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Crear usuario'),
                      onPressed: _createUser,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
