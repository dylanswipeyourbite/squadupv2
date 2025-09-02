import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/event_bus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Squad service for managing squads
class SquadService {
  // ignore: unused_field
  final SupabaseClient _supabase = locator<SupabaseClient>();
  // ignore: unused_field
  final EventBus _eventBus = locator<EventBus>();

  // TODO: Implement squad functionality as per SRS
  // - Create private squad with invite code
  // - Join squad by invite code
  // - View and share invite code (captain only)
  // - View members and weekly activity stats
  // - Delete squad (captain) / Leave squad (member)
  // - 5-8 person limit enforcement
}
