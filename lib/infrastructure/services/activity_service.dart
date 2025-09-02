import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/event_bus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Activity service for managing workouts and check-ins
class ActivityService {
  // ignore: unused_field
  final SupabaseClient _supabase = locator<SupabaseClient>();
  // ignore: unused_field
  final EventBus _eventBus = locator<EventBus>();

  // TODO: Implement activity functionality as per SRS
  // - Manual check-ins with activity type and effort
  // - Auto-synced activities from Terra
  // - Structured metadata (distance, duration, pace, HR, elevation, suffer score)
  // - Activity removal
  // - Richer fields from Terra (cadence, splits, device source)
  // - Run classification (easy, tempo, long, intervals)
  // - AI activity summaries

  // Activity data layers:
  // - Layer 1: Summary (normalized for UI)
  // - Layer 2: Details (structured metrics and series)
  // - Layer 3: Raw Archive (compressed Terra JSON)
}
