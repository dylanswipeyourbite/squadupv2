import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:squadupv2/core/router/app_router.dart';
import 'package:squadupv2/presentation/view_models/signup_view_model.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:go_router/go_router.dart';

/// Signup screen placeholder
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SignupViewModel>(
      create: (_) => locator<SignupViewModel>(),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignupViewModel>();

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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),

                    // Logo/Title section
                    Icon(
                      Icons.directions_run_rounded,
                      size: 80,
                      color: context.colors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Join the Obsessed',
                      style: context.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find your crew who gets the 4:30 AM alarm',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Form section
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _displayNameController,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              enabled: !viewModel.isLoading,
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                hintText: 'What should we call you?',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                if (value.length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !viewModel.isLoading,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'runner@example.com',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              enabled: !viewModel.isLoading,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'At least 6 characters',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                // Check for at least one letter and one number
                                if (!RegExp(
                                  r'^(?=.*[a-zA-Z])(?=.*\d)',
                                ).hasMatch(value)) {
                                  return 'Password must contain letters and numbers';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              enabled: !viewModel.isLoading,
                              onFieldSubmitted: (_) => _handleSignup(context),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords don\'t match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Sign up button
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: viewModel.isLoading
                                  ? CircularProgressIndicator(
                                      color: context.colors.primary,
                                    )
                                  : FilledButton(
                                      onPressed: () => _handleSignup(context),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          52,
                                        ),
                                      ),
                                      child: const Text(
                                        'Start Your Journey',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 24),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already obsessed? ",
                                  style: TextStyle(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : () => context.go(AppRoutes.login),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<SignupViewModel>();
      try {
        await viewModel.signup(
          _displayNameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (context.mounted) {
          // Navigate to welcome/onboarding
          context.go(AppRoutes.welcome);
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackService.error(context, e.toString());
        }
      }
    }
  }
}
