import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/repositories/squad_repository.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:squadupv2/core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ViewModel for joining a squad
class JoinSquadViewModel extends ChangeNotifier {
  final SquadRepository _squadRepository;
  final IFeedbackService _feedbackService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _inviteCode = '';
  String get inviteCode => _inviteCode;

  final _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  // For displaying the entered code in segments
  List<String> get codeSegments {
    final code = _inviteCode.toUpperCase();
    if (code.length <= 3) return [code];
    if (code.length <= 6) return [code.substring(0, 3), code.substring(3)];
    return [code.substring(0, 3), code.substring(3, 6), code.substring(6)];
  }

  JoinSquadViewModel({
    SquadRepository? squadRepository,
    IFeedbackService? feedbackService,
  }) : _squadRepository = squadRepository ?? locator<SquadRepository>(),
       _feedbackService = feedbackService ?? locator<IFeedbackService>();

  void setInviteCode(String value) {
    // Remove any non-alphanumeric characters and limit to 9 chars
    _inviteCode = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (_inviteCode.length > 9) {
      _inviteCode = _inviteCode.substring(0, 9);
    }
    notifyListeners();
  }

  String? validateInviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Invite code is required';
    }
    final cleanCode = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleanCode.length != 9) {
      return 'Invite code must be 9 characters';
    }
    return null;
  }

  Future<void> joinSquad(
    BuildContext context, {
    bool isOnboarding = false,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final cleanCode = _inviteCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final squad = await _squadRepository.joinSquad(cleanCode);

      // Update shared preferences to indicate user has a squad
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSquad', true);

      if (!context.mounted) return;

      _feedbackService.show(
        context: context,
        message: 'Welcome to ${squad.name}!',
        level: FeedbackLevel.success,
      );

      // Navigate based on onboarding state
      if (isOnboarding) {
        // Complete onboarding
        await prefs.setBool('hasCompletedOnboarding', true);
        if (context.mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        // Go to squad chat
        if (context.mounted) {
          context.go('/squads/chat/${squad.id}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _feedbackService.show(
          context: context,
          message: 'Failed to join squad: ${e.toString()}',
          level: FeedbackLevel.error,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
