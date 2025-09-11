import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/domain/models/squad.dart';
import 'package:squadupv2/domain/repositories/squad_repository.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:squadupv2/core/router/app_router.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ViewModel for squad details screen
class SquadDetailViewModel extends ChangeNotifier {
  final String squadId;
  final SquadRepository _squadRepository;
  final IFeedbackService _feedbackService;

  Squad? _squad;
  Squad? get squad => _squad;

  List<SquadMember> _members = [];
  List<SquadMember> get members => _members;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isCaptain = false;
  bool get isCaptain => _isCaptain;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  SquadDetailViewModel({
    required this.squadId,
    SquadRepository? squadRepository,
    IFeedbackService? feedbackService,
  }) : _squadRepository = squadRepository ?? locator<SquadRepository>(),
       _feedbackService = feedbackService ?? locator<IFeedbackService>() {
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      loadSquad(),
      loadMembers(),
      checkCaptainStatus(),
      loadStats(),
    ]);
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _initialize();
  }

  Future<void> loadSquad() async {
    try {
      _squad = await _squadRepository.getSquad(squadId);
      notifyListeners();
    } catch (e) {
      // Error handled silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMembers() async {
    try {
      _members = await _squadRepository.getSquadMembers(squadId);
      notifyListeners();
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> checkCaptainStatus() async {
    try {
      _isCaptain = await _squadRepository.isUserCaptain(squadId);
      notifyListeners();
    } catch (e) {
      _isCaptain = false;
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await _squadRepository.getSquadStats(squadId);
      notifyListeners();
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> copyInviteCode(BuildContext context) async {
    if (_squad == null) return;

    await Clipboard.setData(ClipboardData(text: _squad!.inviteCode));
    if (context.mounted) {
      _feedbackService.show(
        context: context,
        message: 'Invite code copied to clipboard',
        level: FeedbackLevel.success,
      );
    }
  }

  Future<void> shareInviteCode(BuildContext context) async {
    if (_squad == null) return;

    // TODO: Implement share functionality
    _feedbackService.show(
      context: context,
      message: 'Share functionality coming soon!',
      level: FeedbackLevel.info,
    );
  }

  Future<void> leaveSquad(BuildContext context) async {
    try {
      await _squadRepository.leaveSquad(squadId);

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();

      // Check if user has other squads
      final squads = await _squadRepository.getUserSquads();
      if (squads.isEmpty) {
        await prefs.setBool('hasSquad', false);
      }

      if (!context.mounted) return;

      _feedbackService.show(
        context: context,
        message: 'You have left the squad',
        level: FeedbackLevel.success,
      );

      context.go(AppRoutes.home);
    } catch (e) {
      if (context.mounted) {
        _feedbackService.show(
          context: context,
          message: 'Failed to leave squad: ${e.toString()}',
          level: FeedbackLevel.error,
        );
      }
    }
  }

  Future<void> deleteSquad(BuildContext context) async {
    if (!_isCaptain) return;

    try {
      await _squadRepository.deleteSquad(squadId);

      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();

      // Check if user has other squads
      final squads = await _squadRepository.getUserSquads();
      if (squads.isEmpty) {
        await prefs.setBool('hasSquad', false);
      }

      if (!context.mounted) return;

      _feedbackService.show(
        context: context,
        message: 'Squad deleted successfully',
        level: FeedbackLevel.success,
      );

      context.go(AppRoutes.home);
    } catch (e) {
      if (context.mounted) {
        _feedbackService.show(
          context: context,
          message: 'Failed to delete squad: ${e.toString()}',
          level: FeedbackLevel.error,
        );
      }
    }
  }

  void showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          'Delete Squad?',
          style: TextStyle(color: context.colors.onSurface),
        ),
        content: Text(
          'This will permanently delete ${_squad?.name ?? 'the squad'} and remove all members. This action cannot be undone.',
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              deleteSquad(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
            child: const Text('Delete Squad'),
          ),
        ],
      ),
    );
  }

  void showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          'Leave Squad?',
          style: TextStyle(color: context.colors.onSurface),
        ),
        content: Text(
          'Are you sure you want to leave ${_squad?.name ?? 'this squad'}? You\'ll need an invite code to rejoin.',
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              leaveSquad(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
            child: const Text('Leave Squad'),
          ),
        ],
      ),
    );
  }
}
