import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/core/router/app_router.dart';

/// Squad Choice screen - allows users to create or join a squad
class SquadChoiceScreen extends StatelessWidget {
  const SquadChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Header
              Column(
                children: [
                  Icon(Icons.groups, size: 64, color: context.colors.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Ready to Squad Up?',
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join an existing squad or create your own',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const Spacer(),

              // Choice cards
              Column(
                children: [
                  // Create Squad Card
                  _ChoiceCard(
                    icon: Icons.add_circle_outline,
                    title: 'Create a Squad',
                    description:
                        'Start your own training group and invite your crew',
                    color: context.colors.primary,
                    onTap: () =>
                        context.go('${AppRoutes.createSquad}?onboarding=true'),
                  ),
                  const SizedBox(height: 16),

                  // Join Squad Card
                  _ChoiceCard(
                    icon: Icons.vpn_key,
                    title: 'Join a Squad',
                    description:
                        'Enter an invite code to join an existing squad',
                    color: context.squadUpTheme.successColor,
                    onTap: () =>
                        context.go('${AppRoutes.joinSquad}?onboarding=true'),
                  ),
                ],
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Choice card widget for create/join options
class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: context.colors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
