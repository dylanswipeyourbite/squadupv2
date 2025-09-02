import 'package:flutter/material.dart';

/// Create Squad screen placeholder
class CreateSquadScreen extends StatelessWidget {
  final bool isOnboarding;

  const CreateSquadScreen({super.key, this.isOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Squad')),
      body: Center(
        child: Text(
          'Create Squad Screen - To be implemented\nOnboarding: $isOnboarding',
        ),
      ),
    );
  }
}
