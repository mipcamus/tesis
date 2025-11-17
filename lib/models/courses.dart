// clase que representa los cursos

import 'package:flutter/foundation.dart';

// atributos del curso
class Course {
  final String id;
  final String title;
  final String description;

  const Course({
    required this.id,
    required this.title,
    required this.description,
  });

  /// Esto es un map que es el tipo de dato de Firestore
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'description': description};
  }

  factory Course.fromFirestore(String id, Map<String, dynamic> data) {
    return Course(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
    );
  }
}
