import 'package:squadupv2/core/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// Service for managing onboarding flow and data
class OnboardingService {
  final SupabaseClient _supabase = locator<SupabaseClient>();
  final AuthService _authService = locator<AuthService>();
  final LoggerService _logger = locator<LoggerService>();

  /// Save onboarding data to user profile
  Future<void> saveOnboardingData(Map<String, dynamic> data) async {
    try {
      final profileId = _authService.currentProfileId;
      if (profileId == null) {
        throw Exception('No profile ID found');
      }

      // Update profile with onboarding data
      await _supabase
          .from('profiles')
          .update({
            'onboarding_completed': true,
            'onboarding_data': data,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profileId);

      _logger.info('Onboarding data saved for profile: $profileId');
    } catch (e) {
      _logger.error('Failed to save onboarding data', e);
      rethrow;
    }
  }

  /// Get AI-generated onboarding suggestions based on collected data
  Future<OnboardingSuggestions> getOnboardingSuggestions(
    Map<String, dynamic> userData,
  ) async {
    // This is now fully AI-driven through our Edge Functions
    // The AI will generate completely personalized suggestions
    // based on the conversation data, not hardcoded templates

    // For now, return a placeholder that indicates AI will handle this
    return OnboardingSuggestions(
      trainingFocus: 'AI-personalized focus based on your conversation',
      initialPlan: 'Custom plan generated from your specific needs and goals',
      weeklyStructure: 'Tailored to your lifestyle and preferences',
      tips: [
        'Personalized tips will be generated based on your unique situation',
      ],
    );
  }

  /// Call AI assistant for personalized onboarding
  Future<Map<String, dynamic>> getAIOnboardingResponse({
    required List<Map<String, String>> messages,
  }) async {
    try {
      final profileId = _authService.currentProfileId;
      if (profileId == null) {
        throw Exception('No profile ID found');
      }

      // Call edge function for AI response
      final response = await _supabase.functions.invoke(
        'onboarding-assistant',
        body: {'messages': messages, 'profileId': profileId},
      );

      if (response.data == null) {
        throw Exception('No response from AI assistant');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      _logger.error('Failed to get AI onboarding response', e);
      // Return a fallback response
      return {
        'message':
            "I apologize, I'm having trouble connecting right now. Let's try again - tell me about your running journey.",
        'extractedData': {},
      };
    }
  }
}

/// Onboarding suggestions model
class OnboardingSuggestions {
  final String trainingFocus;
  final String initialPlan;
  final String weeklyStructure;
  final List<String> tips;

  OnboardingSuggestions({
    required this.trainingFocus,
    required this.initialPlan,
    required this.weeklyStructure,
    required this.tips,
  });
}
