import 'package:flutter/material.dart';

/// Join Squad screen placeholder
class JoinSquadScreen extends StatelessWidget {
  final bool isOnboarding;

  const JoinSquadScreen({super.key, this.isOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Squad')),
      body: Center(
        child: Text(
          'Join Squad Screen - To be implemented\nOnboarding: $isOnboarding',
        ),
      ),
    );
  }
}
