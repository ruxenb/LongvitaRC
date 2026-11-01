import 'package:flutter/material.dart';

void main() {
  runApp(const LongvitaApp());
}

class LongvitaApp extends StatelessWidget {
  const LongvitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Longvita',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Longvita - Barebone Ready'),
        ),
      ),
    );
  }
}
