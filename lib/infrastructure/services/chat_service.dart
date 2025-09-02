import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:squadupv2/core/event_bus.dart';

/// Chat service for real-time messaging
class ChatService {
  final SupabaseClient supabase;
  final EventBus eventBus;

  ChatService({required this.supabase, required this.eventBus});

  // TODO: Implement chat functionality as per SRS
  // - Real-time messaging
  // - Message types (text, image, voice, video)
  // - Activity check-ins
  // - Mentions with autocomplete
  // - Polls
  // - Reactions
  // - Quote replies
  // - Edit/delete messages
  // - Read receipts
  // - Typing indicators
  // - Link previews
  // - Search
}
