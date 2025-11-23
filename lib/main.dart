import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  print('==== FIREBASE PROJECT ID ====');
  print(DefaultFirebaseOptions.currentPlatform.projectId);
  print('==============================');

  runApp(const MyApp());
}
