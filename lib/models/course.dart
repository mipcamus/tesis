import 'package:flutter/foundation.dart';

// atributos del curso
class Course {
  final String id;
  final String title;
  final String description;
  final String teacherId;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherId,
  });

  /// Esto es un map que es el tipo de dato de Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'teacher_id': teacherId,
    };
  }

  factory Course.fromFirestore(String id, Map<String, dynamic> data) {
    return Course(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      teacherId: data['teacher_id'] ?? '',
    );
  }
}
