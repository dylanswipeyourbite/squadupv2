import 'package:flutter/material.dart';

/// Squad Main screen placeholder (chat)
class SquadMainScreen extends StatelessWidget {
  final String squadId;
  final String squadName;

  const SquadMainScreen({
    super.key,
    required this.squadId,
    required this.squadName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(squadName)),
      body: Center(
        child: Text('Squad Chat Screen - To be implemented\nSquad: $squadName'),
      ),
    );
  }
}
