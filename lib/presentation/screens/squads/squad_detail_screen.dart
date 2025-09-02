import 'package:flutter/material.dart';

/// Squad Detail screen placeholder
class SquadDetailScreen extends StatelessWidget {
  final String squadId;

  const SquadDetailScreen({super.key, required this.squadId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Squad Details')),
      body: Center(
        child: Text(
          'Squad Detail Screen - To be implemented\nSquad ID: $squadId',
        ),
      ),
    );
  }
}
