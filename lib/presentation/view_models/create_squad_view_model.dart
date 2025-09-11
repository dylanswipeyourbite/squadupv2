import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/repositories/squad_repository.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ViewModel for creating a squad
class CreateSquadViewModel extends ChangeNotifier {
  final SquadRepository _squadRepository;
  final IFeedbackService _feedbackService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _name = '';
  String get name => _name;

  String _description = '';
  String get description => _description;

  final _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  CreateSquadViewModel({
    SquadRepository? squadRepository,
    IFeedbackService? feedbackService,
  }) : _squadRepository = squadRepository ?? locator<SquadRepository>(),
       _feedbackService = feedbackService ?? locator<IFeedbackService>();

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Squad name is required';
    }
    if (value.trim().length < 3) {
      return 'Squad name must be at least 3 characters';
    }
    if (value.trim().length > 30) {
      return 'Squad name must be less than 30 characters';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value != null && value.trim().length > 200) {
      return 'Description must be less than 200 characters';
    }
    return null;
  }

  Future<void> createSquad(
    BuildContext context, {
    bool isOnboarding = false,
  }) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final squad = await _squadRepository.createSquad(
        name: _name.trim(),
        description: _description.trim().isEmpty ? null : _description.trim(),
      );

      // Update shared preferences to indicate user has a squad
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSquad', true);

      if (!context.mounted) return;

      _feedbackService.show(
        context: context,
        message: 'Squad created! Invite code: ${squad.inviteCode}',
        level: FeedbackLevel.success,
      );

      // Navigate based on onboarding state
      if (isOnboarding) {
        // Complete onboarding
        await prefs.setBool('hasCompletedOnboarding', true);
        if (context.mounted) {
          // Navigate to the squad chat (ObsessionStreamScreen)
          context.go(
            '/squads/chat/${squad.id}',
            extra: {'squadName': squad.name},
          );
        }
      } else {
        // Not onboarding - go back to squads overview
        if (context.mounted) {
          context.go('/squads');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _feedbackService.show(
          context: context,
          message: 'Failed to create squad: ${e.toString()}',
          level: FeedbackLevel.error,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
