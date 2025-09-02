import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/event_bus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Race service for managing races and training
class RaceService {
  // ignore: unused_field
  final SupabaseClient _supabase = locator<SupabaseClient>();
  // ignore: unused_field
  final EventBus _eventBus = locator<EventBus>();

  // TODO: Implement race functionality as per SRS
  // - Add upcoming races with date/distance
  // - Share race with squads
  // - Set primary squad for race
  // - Training window recognition (16 weeks out)
  // - Race-mode SquadPulse
  // - Collective training momentum tracking
  // - Race countdown and phase management
}
