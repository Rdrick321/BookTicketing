import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tixtogo/pages/login.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://mkynvxupnliitwaxnlne.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1reW52eHVwbmxpaXR3YXhubG5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzOTc5OTYsImV4cCI6MjA1NTk3Mzk5Nn0.ulwqVBQNuuSmvZcgzp13-doGF9V8JOnh-0DKC_b3tio',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 243, 62, 46),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 237, 76, 64),
        ),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}
