import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/presentation/view_models/create_squad_view_model.dart';

/// Create Squad screen for starting a new training group
class CreateSquadScreen extends StatelessWidget {
  final bool isOnboarding;

  const CreateSquadScreen({super.key, this.isOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateSquadViewModel(),
      child: _CreateSquadView(isOnboarding: isOnboarding),
    );
  }
}

class _CreateSquadView extends StatelessWidget {
  final bool isOnboarding;

  const _CreateSquadView({required this.isOnboarding});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateSquadViewModel>();

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text('Create Squad'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isOnboarding) {
              context.go('/onboarding/squad-choice');
            } else {
              context.go('/squads');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Form(
          key: viewModel.formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              Text(
                'Start Your Squad',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a private training group for you and your crew',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Squad name input
              TextFormField(
                onChanged: viewModel.setName,
                validator: viewModel.validateName,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: context.colors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Squad Name',
                  hintText: 'Morning Milers, Track Stars, etc.',
                  prefixIcon: Icon(Icons.groups, color: context.colors.primary),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),

              // Description input
              TextFormField(
                onChanged: viewModel.setDescription,
                validator: viewModel.validateDescription,
                maxLength: 200,
                maxLines: 3,
                style: TextStyle(color: context.colors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What\'s your squad about?',
                  prefixIcon: Icon(
                    Icons.description_outlined,
                    color: context.colors.primary,
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: context.colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Private by Design',
                            style: context.textTheme.titleSmall?.copyWith(
                              color: context.colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your squad will be private. You\'ll get an invite code to share with your crew.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Create button
              FilledButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () => viewModel.createSquad(
                        context,
                        isOnboarding: isOnboarding,
                      ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: viewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Create Squad'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
