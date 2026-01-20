import 'package:flutter/material.dart';
import 'screens/attendance_screen.dart';
import 'screens/exam_scores_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CG Intern Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExamScoresScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
