import 'package:flutter/material.dart';

/// Welcome screen placeholder
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: const Center(child: Text('Welcome Screen - To be implemented')),
    );
  }
}
