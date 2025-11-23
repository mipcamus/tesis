// -----------------------------------------------------------------------------
// Vista: EditProfilePage (solo editar foto de perfil)
// -----------------------------------------------------------------------------
// Esta versión permite únicamente cambiar la foto de perfil del usuario.
// No modifica campos de texto.
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _newPhoto;
  bool _saving = false;

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      setState(() {
        _newPhoto = File(picked.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al abrir galería: $e')));
    }
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_newPhoto == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_photos")
        .child("$uid.jpg");

    await ref.putFile(_newPhoto!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    if (_newPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No seleccionaste ninguna foto")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final newPhotoUrl = await _uploadPhoto(uid);

      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "photo_url": newPhotoUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto actualizada con éxito")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.user.photo_url;

    return Scaffold(
      appBar: AppBar(title: const Text("Editar foto de perfil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // FOTO
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _newPhoto != null
                      ? FileImage(_newPhoto!)
                      : (avatar != null && avatar.isNotEmpty)
                      ? NetworkImage(avatar)
                      : null,
                  child: (avatar == null || avatar.isEmpty) && _newPhoto == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // BOTÓN GUARDAR
            _saving
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    onPressed: _saveChanges,
                    label: const Text("Guardar foto"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
