import 'package:flutter/material.dart';

import 'src/map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpoofGuard Navigator',
      theme: ThemeData( // Theme of the application.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff38789a)),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
