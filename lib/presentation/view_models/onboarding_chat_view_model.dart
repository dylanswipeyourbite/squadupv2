import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squadupv2/infrastructure/services/onboarding_service.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/router/app_router.dart';

/// Message in the onboarding chat
class OnboardingMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  OnboardingMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// View model for onboarding chat screen
class OnboardingChatViewModel extends ChangeNotifier {
  final OnboardingService _onboardingService;
  final LoggerService _logger = locator<LoggerService>();

  OnboardingChatViewModel(this._onboardingService);

  final List<OnboardingMessage> _messages = [];
  bool _isLoading = false;
  Map<String, dynamic> _collectedData = {};
  int _messagesExchanged = 0;
  bool _waitingForCompletionConfirmation = false;

  List<OnboardingMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get canSendMessage => !_isLoading;

  // Progress based on message exchanges (typically 6-8 exchanges for good onboarding)
  double get progress => (_messagesExchanged / 8).clamp(0.0, 1.0);

  /// Start the conversation with initial greeting
  void startConversation() {
    _addBotMessage(
      "Hey there! I'm your running coach here at SquadUp. "
      "I'm here to learn what makes you tick as a runner. 🏃‍♂️\n\n"
      "Our AI coaches use everything we discuss to give you truly personalized guidance - "
      "not generic training plans, but advice that fits your life, your goals, your obsessions. "
      "The more honest you are about what drives you, the better I can help you become the runner you want to be.\n\n"
      "So, what's your story? Are you already logging miles, or looking to lace up for the first time?\n\n"
      "If you'd rather jump straight into creating your squad, that's totally fine - just let me know. "
      "But I'd love to learn what makes you different from every other runner out there.",
    );
  }

  /// Send a message from the user
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    // Add user message
    _addUserMessage(text);

    final lowerText = text.toLowerCase();

    // Check if user wants to skip onboarding
    if (lowerText.contains('skip') ||
        lowerText.contains('continue') ||
        lowerText.contains('move on') ||
        lowerText.contains('jump to') ||
        lowerText.contains('create') ||
        lowerText.contains('squad')) {
      _addBotMessage(
        "I understand - sometimes you just want to dive in! "
        "Ready to create your squad? 🚀",
      );
      _waitingForCompletionConfirmation = true;
      return;
    }

    // Check if user is confirming they're ready to complete
    if (_waitingForCompletionConfirmation) {
      if (lowerText.contains('yes') ||
          lowerText.contains('ready') ||
          lowerText.contains('sure') ||
          lowerText.contains('let\'s')) {
        await _completeOnboarding();
        return;
      } else {
        _waitingForCompletionConfirmation = false;
        // Continue the conversation
      }
    }

    _setLoading(true);

    try {
      // Build conversation history for AI
      final messages = _messages
          .map(
            (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          )
          .toList();

      // Get AI response
      final response = await _onboardingService.getAIOnboardingResponse(
        messages: messages,
      );

      // Add AI response
      _addBotMessage(response['message'] as String);

      // Update collected data
      final extractedData = response['extractedData'] as Map<String, dynamic>?;
      if (extractedData != null && extractedData.isNotEmpty) {
        _collectedData.addAll(extractedData);
        _logger.info('Extracted onboarding data: $extractedData');
      }

      // Check if we should wrap up the conversation
      // We want a meaningful conversation - at least 10 exchanges (5 back and forth)
      // and substantial data before completing
      if (_messagesExchanged >= 10 && _hasSubstantialData()) {
        // Ask if they're ready to proceed instead of auto-completing
        _askIfReadyToComplete();
      }
    } catch (e) {
      _logger.error('Error in onboarding chat', e);
      _addBotMessage(
        "I apologize, I'm having a moment here. Mind trying that again? "
        "Sometimes my connection acts up, just like my GPS watch on a trail run.",
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Check if we have collected substantial data for a complete profile
  bool _hasSubstantialData() {
    // We want multiple data points to ensure we really understand the athlete
    int dataPoints = 0;

    if (_collectedData.containsKey('experienceLevel')) dataPoints++;
    if (_collectedData.containsKey('raceGoals')) dataPoints++;
    if (_collectedData.containsKey('timeGoals')) dataPoints++;
    if (_collectedData.containsKey('preferredTime')) dataPoints++;
    if (_collectedData.containsKey('hasInjuryConcerns')) dataPoints++;
    if (_collectedData.containsKey('weeklyMileage')) dataPoints++;
    if (_collectedData.containsKey('motivation')) dataPoints++;

    // Need at least 4 meaningful data points
    return dataPoints >= 4;
  }

  /// Ask if the user is ready to find their squad
  void _askIfReadyToComplete() {
    _addBotMessage(
      "I'm getting a great picture of where you're at and what drives you! "
      "We've covered a lot of ground here. 🏃‍♂️\n\n"
      "Do you feel ready to find your squad, or is there anything else about "
      "your running journey you'd like to share? I'm here to listen!",
    );
    _waitingForCompletionConfirmation = true;
  }

  /// Complete the onboarding process
  Future<void> _completeOnboarding() async {
    _setLoading(true);

    try {
      // Add completion message
      _addBotMessage(
        "This is fantastic! I've got a great sense of where you're at and what you're after. "
        "Let me save your preferences and we'll get you connected with the perfect squad.\n\n"
        "Ready to find your people? 🏃‍♂️",
      );

      // Save the collected data
      await _onboardingService.saveOnboardingData(_collectedData);

      // Mark onboarding as complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);

      // Navigate to squad choice after a short delay
      await Future.delayed(const Duration(seconds: 2));

      if (navigatorKey.currentContext != null) {
        navigatorKey.currentContext!.go(AppRoutes.squadChoice);
      }
    } catch (e) {
      _logger.error('Failed to complete onboarding', e);
      _addBotMessage(
        "Hmm, I'm having trouble saving your info. "
        "Let's try that again - what's your main running goal right now?",
      );
    } finally {
      _setLoading(false);
    }
  }

  void _addUserMessage(String text) {
    _messages.add(OnboardingMessage(text: text, isUser: true));
    _messagesExchanged++;
    notifyListeners();
  }

  void _addBotMessage(String text) {
    _messages.add(OnboardingMessage(text: text, isUser: false));
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
