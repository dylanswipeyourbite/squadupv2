import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'package:squadupv2/core/router/app_router.dart';
import 'package:squadupv2/presentation/view_models/login_view_model.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:go_router/go_router.dart';

/// Login screen placeholder
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (_) => locator<LoginViewModel>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

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
                    // Logo/Title section
                    Icon(
                      Icons.directions_run_rounded,
                      size: 80,
                      color: context.colors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      style: context.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your squad is waiting for you',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
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
                                // Better email validation
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
                              textInputAction: TextInputAction.done,
                              enabled: !viewModel.isLoading,
                              onFieldSubmitted: (_) => _handleLogin(context),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Login button
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: viewModel.isLoading
                                  ? CircularProgressIndicator(
                                      color: context.colors.primary,
                                    )
                                  : FilledButton(
                                      onPressed: () => _handleLogin(context),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          52,
                                        ),
                                      ),
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 16),

                            // Forgot password
                            TextButton(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => _showForgotPasswordDialog(context),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(color: context.colors.primary),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "New to the obsession? ",
                                  style: TextStyle(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : () => context.push(AppRoutes.signup),
                                  child: Text(
                                    'Join us',
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

  Future<void> _handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<LoginViewModel>();
      try {
        await viewModel.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (context.mounted) {
          // Let splash screen handle routing based on onboarding status
          context.go(AppRoutes.splash);
        }
      } catch (e) {
        if (context.mounted) {
          FeedbackService.error(context, e.toString());
        }
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We\'ll send you a password reset link',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'runner@example.com',
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final email = emailController.text.trim();
                try {
                  await locator<AuthService>().sendPasswordResetEmail(email);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    FeedbackService.success(
                      context,
                      'Password reset email sent to $email',
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    FeedbackService.error(ctx, e.toString());
                  }
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}
