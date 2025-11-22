import 'package:flutter/foundation.dart';

// atributos del curso
class Course {
  final String id;
  final String title;
  final String description;
  final String teacher_id;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.teacher_id,
  });

  /// Esto es un map que es el tipo de dato de Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'teacher_id': teacher_id,
    };
  }

  factory Course.fromFirestore(String id, Map<String, dynamic> data) {
    return Course(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      teacher_id: data['teacher_id'] ?? '',
    );
  }
}
