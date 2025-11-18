import 'package:flutter/material.dart';

import '../models/course_class.dart';
import '../services/course_classes_service.dart';

class CourseClassesPage extends StatelessWidget {
  final String course_id;

  const CourseClassesPage({super.key, required this.course_id});

  @override
  Widget build(BuildContext context) {
    final service = CourseClassesService();

    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<List<CourseClass>>(
        stream: service.listenClassesForCourse(course_id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data!;

          if (classes.isEmpty) {
            return const Center(child: Text('Aún no hay clases programadas.'));
          }

          return ListView.separated(
            itemCount: classes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = classes[index];

              final dateStr =
                  '${c.date.day.toString().padLeft(2, '0')}/'
                  '${c.date.month.toString().padLeft(2, '0')}/'
                  '${c.date.year}';

              return ListTile(
                title: Text('$dateStr'),
                trailing: Icon(
                  c.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: c.done ? Colors.green : Colors.grey,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
