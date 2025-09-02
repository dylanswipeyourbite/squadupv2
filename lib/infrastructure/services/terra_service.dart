import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:squadupv2/core/constants/environment.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/event_bus.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// Terra integration events
class TerraConnectionEvent extends AppEvent {
  final String provider;
  final bool isConnected;
  TerraConnectionEvent(this.provider, this.isConnected);
}

class TerraActivitySyncEvent extends AppEvent {
  final int activitiesCount;
  TerraActivitySyncEvent(this.activitiesCount);
}

/// Supported Terra providers
enum TerraProvider {
  garmin('GARMIN'),
  strava('STRAVA'),
  polar('POLAR'),
  fitbit('FITBIT'),
  wahoo('WAHOO'),
  zwift('ZWIFT'),
  oura('OURA'),
  whoop('WHOOP'),
  apple('APPLE'),
  google('GOOGLE');

  final String value;
  const TerraProvider(this.value);

  static TerraProvider? fromString(String value) {
    return TerraProvider.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TerraProvider.strava,
    );
  }
}

/// Terra activity data model
class TerraActivity {
  final String id;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final double? distanceMeters;
  final int? durationSeconds;
  final double? averageHrBpm;
  final double? elevationGainMeters;
  final Map<String, dynamic> rawData;

  TerraActivity({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.distanceMeters,
    this.durationSeconds,
    this.averageHrBpm,
    this.elevationGainMeters,
    required this.rawData,
  });

  factory TerraActivity.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] ?? {};

    return TerraActivity(
      id: metadata['summary_id'] ?? metadata['session_id'] ?? '',
      type: metadata['type'] ?? 'unknown',
      startTime: DateTime.parse(metadata['start_time']),
      endTime: DateTime.parse(metadata['end_time']),
      distanceMeters: json['distance_data']?['summary']?['distance_meters']
          ?.toDouble(),
      durationSeconds: json['active_durations_data']?['activity_seconds'],
      averageHrBpm: json['heart_rate_data']?['summary']?['avg_hr_bpm']
          ?.toDouble(),
      elevationGainMeters:
          json['distance_data']?['summary']?['elevation']?['gain_actual_meters']
              ?.toDouble(),
      rawData: json,
    );
  }
}

/// Terra service for fitness device integrations
class TerraService {
  static const String _baseUrl = 'https://api.tryterra.co/v2';
  final EventBus _eventBus = locator<EventBus>();
  final AuthService _authService = locator<AuthService>();

  /// Generate authentication URL for a provider
  Future<String> generateAuthUrl(TerraProvider provider) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/generateAuthLink'),
        headers: {
          'dev-id': Environment.terraDevId,
          'x-api-key': Environment.terraApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reference_id': user.uid,
          'providers': [provider.value],
          'auth_success_redirect_url': 'squadup://terra/success',
          'auth_failure_redirect_url': 'squadup://terra/failure',
          'language': 'en',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['auth_url'];
      } else {
        throw Exception('Failed to generate auth URL: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terra auth URL generation failed: $e');
    }
  }

  /// Disconnect a provider
  Future<void> disconnectProvider(TerraProvider provider) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/auth/deauthenticateUser'),
        headers: {
          'dev-id': Environment.terraDevId,
          'x-api-key': Environment.terraApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reference_id': user.uid}),
      );

      if (response.statusCode == 200) {
        _eventBus.fire(TerraConnectionEvent(provider.value, false));
      } else {
        throw Exception('Failed to disconnect provider: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terra disconnect failed: $e');
    }
  }

  /// Get connected providers for the current user
  Future<List<TerraProvider>> getConnectedProviders() async {
    final user = _authService.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/userInfo?reference_id=${user.uid}'),
        headers: {
          'dev-id': Environment.terraDevId,
          'x-api-key': Environment.terraApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = data['users'] as List<dynamic>? ?? [];

        final providers = <TerraProvider>[];
        for (final user in users) {
          final providerString = user['provider'] as String?;
          if (providerString != null) {
            final provider = TerraProvider.fromString(providerString);
            if (provider != null) {
              providers.add(provider);
            }
          }
        }

        return providers;
      } else if (response.statusCode == 404) {
        // No connected providers
        return [];
      } else {
        throw Exception('Failed to get connected providers: ${response.body}');
      }
    } catch (e) {
      logger.error('Error getting connected providers', e);
      return [];
    }
  }

  /// Fetch recent activities
  Future<List<TerraActivity>> fetchRecentActivities({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      return [];
    }

    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 7));
    final end = endDate ?? now;

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/activity?reference_id=${user.uid}'
          '&start_date=${start.toIso8601String()}'
          '&end_date=${end.toIso8601String()}'
          '&limit=$limit',
        ),
        headers: {
          'dev-id': Environment.terraDevId,
          'x-api-key': Environment.terraApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = data['data'] as List<dynamic>? ?? [];

        final terraActivities = activities
            .map((json) => TerraActivity.fromJson(json))
            .toList();

        _eventBus.fire(TerraActivitySyncEvent(terraActivities.length));

        return terraActivities;
      } else {
        throw Exception('Failed to fetch activities: ${response.body}');
      }
    } catch (e) {
      logger.error('Error fetching activities', e);
      return [];
    }
  }

  /// Import historical activities
  Future<void> importHistoricalActivities({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/historical'),
        headers: {
          'dev-id': Environment.terraDevId,
          'x-api-key': Environment.terraApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reference_id': user.uid,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to import historical data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terra historical import failed: $e');
    }
  }

  /// Handle deep link callback from Terra auth
  Future<void> handleAuthCallback(Uri uri) async {
    final path = uri.path;

    if (path.contains('success')) {
      // Extract provider from query params if available
      final provider = uri.queryParameters['provider'];
      if (provider != null) {
        _eventBus.fire(TerraConnectionEvent(provider, true));
      }
    } else if (path.contains('failure')) {
      // Handle auth failure
      final error = uri.queryParameters['error'] ?? 'Connection failed';
      throw Exception('Terra auth failed: $error');
    }
  }
}
