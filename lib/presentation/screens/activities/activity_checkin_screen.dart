import 'package:flutter/material.dart';

/// Activity Check-in screen placeholder
class ActivityCheckInScreen extends StatelessWidget {
  final Map<String, dynamic>? terraData;

  const ActivityCheckInScreen({super.key, this.terraData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Check-in')),
      body: Center(
        child: Text(
          terraData != null
              ? 'Activity Check-in Screen - To be implemented\nWith Terra data'
              : 'Manual Activity Check-in Screen - To be implemented',
        ),
      ),
    );
  }
}
