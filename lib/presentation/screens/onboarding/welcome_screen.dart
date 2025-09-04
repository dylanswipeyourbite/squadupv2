import 'package:flutter/material.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:go_router/go_router.dart';

/// Welcome screen - Entry point to conversational onboarding
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colors.surface,
              context.colors.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Logo and title
                Icon(
                  Icons.directions_run_rounded,
                  size: 100,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome to\nSquadUp',
                  textAlign: TextAlign.center,
                  style: context.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Where obsession finds its tribe',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),

                const Spacer(),

                // Key features
                _buildFeature(
                  context,
                  Icons.groups_rounded,
                  'Small, private squads',
                  'Just 5-8 people who get the 4:30 AM alarm',
                ),
                const SizedBox(height: 20),
                _buildFeature(
                  context,
                  Icons.analytics_rounded,
                  'AI coaching from your data',
                  'Expert guidance grounded in your actual training',
                ),
                const SizedBox(height: 20),
                _buildFeature(
                  context,
                  Icons.favorite_rounded,
                  'For the truly obsessed',
                  'No explaining why you check weather apps 73 times',
                ),

                const Spacer(),

                // CTA button
                FilledButton(
                  onPressed: () => context.go('/onboarding/chat'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'Start Your Journey',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Takes about 3 minutes',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: context.colors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
