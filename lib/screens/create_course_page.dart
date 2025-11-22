// -----------------------------------------------------------------------------
// Vista: CreateCoursePage
// -----------------------------------------------------------------------------
// Pantalla utilizada para que un profesor pueda crear un nuevo curso dentro de la aplicación. Permite
// al usuario ingresar la información necesaria del curso y guardarla en Firestore.
//
// Esta vista se usa para:
// - Mostrar un formulario para ingresar los datos del curso.
// - Llamar a CourseService para crear el curso en la base de datos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/course_service.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay profesor autenticado')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final courseService = CourseService();

      await courseService.createCourse(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        teacher_id: currentUser.uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso creado correctamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear curso: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear curso')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del curso',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese un título' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del curso',
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese una descripción' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: _saveCourse,
                      label: const Text('Guardar curso'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
