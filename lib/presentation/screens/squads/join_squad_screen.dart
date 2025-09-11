import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/presentation/view_models/join_squad_view_model.dart';

/// Join Squad screen for joining an existing training group
class JoinSquadScreen extends StatelessWidget {
  final bool isOnboarding;

  const JoinSquadScreen({super.key, this.isOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JoinSquadViewModel(),
      child: _JoinSquadView(isOnboarding: isOnboarding),
    );
  }
}

class _JoinSquadView extends StatelessWidget {
  final bool isOnboarding;

  const _JoinSquadView({required this.isOnboarding});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<JoinSquadViewModel>();

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text('Join Squad'),
        backgroundColor: Colors.transparent,
        leading: isOnboarding
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/onboarding/squad-choice'),
              )
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: viewModel.formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              Text(
                'Join Your Crew',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the invite code from your squad captain',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),

              // Invite code input
              Column(
                children: [
                  // Visual representation of the code
                  if (viewModel.inviteCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (
                            int i = 0;
                            i < viewModel.codeSegments.length;
                            i++
                          ) ...[
                            if (i > 0) ...[
                              Container(
                                width: 8,
                                height: 2,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                color: context.colors.primary,
                              ),
                            ],
                            Text(
                              viewModel.codeSegments[i],
                              style: context.textTheme.headlineSmall?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Input field
                  TextFormField(
                    onChanged: viewModel.setInviteCode,
                    validator: viewModel.validateInviteCode,
                    maxLength: 9,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      UpperCaseTextFormatter(),
                    ],
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 20,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Invite Code',
                      hintText: 'ABC123XYZ',
                      counterText: '',
                      prefixIcon: Icon(
                        Icons.vpn_key,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: context.colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Where to find your invite code',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoStep(
                      context,
                      '1',
                      'Ask your squad captain for the invite code',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoStep(
                      context,
                      '2',
                      'Codes are 9 characters (letters and numbers)',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoStep(
                      context,
                      '3',
                      'Once joined, you\'ll have access to squad chat and activities',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Join button
              FilledButton(
                onPressed:
                    viewModel.isLoading || viewModel.inviteCode.length != 9
                    ? null
                    : () => viewModel.joinSquad(
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
                    : const Text('Join Squad'),
              ),

              // Alternative action for onboarding
              if (isOnboarding) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/onboarding/squad-choice'),
                  child: Text(
                    'Back to squad options',
                    style: TextStyle(color: context.colors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoStep(BuildContext context, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom text formatter to convert to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
