import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/repositories/squad_repository.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';

/// Home screen that redirects to the user's squad
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _squadRepository = locator<SquadRepository>();
  final _logger = locator<LoggerService>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSquads();
  }

  Future<void> _loadUserSquads() async {
    try {
      final squads = await _squadRepository.getUserSquads();

      if (!mounted) return;

      if (squads.isNotEmpty) {
        // User has squads - go to squads overview
        context.go('/squads');
      } else {
        // No squads, go to squad choice
        context.go('/onboarding/squad-choice');
      }
    } catch (e) {
      _logger.error('Error loading user squads', e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.colors.primary,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Unable to load squads',
                    style: context.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadUserSquads,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
