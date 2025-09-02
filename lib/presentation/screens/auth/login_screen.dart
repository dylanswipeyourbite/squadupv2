import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'package:squadupv2/core/router/app_router.dart';
import 'package:squadupv2/presentation/view_models/login_view_model.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome Back, Runner')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.blueGrey[900]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            'Welcome Back, Runner',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Among friends who get the obsession.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        if (viewModel.isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  await viewModel.login(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                  if (context.mounted) {
                                    context.go(
                                      AppRoutes.splash,
                                    ); // Let splash handle routing
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    FeedbackService.error(
                                      context,
                                      e.toString(),
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text('Join the Squad'),
                          ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.signup),
                          child: const Text('New here? Sign up'),
                        ),
                        TextButton(
                          onPressed: () => _showForgotPasswordDialog(context),
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final email = emailController.text;
              if (email.isNotEmpty) {
                try {
                  await locator<AuthService>().sendPasswordResetEmail(email);
                  if (ctx.mounted) {
                    FeedbackService.success(ctx, 'Password reset email sent');
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    FeedbackService.error(ctx, e.toString());
                  }
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
