import 'package:flutter/material.dart';

/// Home screen placeholder
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SquadUp Home')),
      body: const Center(child: Text('Home Screen - To be implemented')),
    );
  }
}
