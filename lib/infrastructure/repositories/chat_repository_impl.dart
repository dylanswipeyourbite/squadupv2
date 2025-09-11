import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:squadupv2/domain/models/message.dart';
import 'package:squadupv2/domain/repositories/chat_repository.dart';
import 'package:squadupv2/infrastructure/helpers/edge_function_helper.dart';
import 'package:squadupv2/core/service_locator.dart';

/// Implementation of ChatRepository using Supabase Edge Functions
class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _supabase;

  // Realtime subscriptions
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<Message>> _messageStreams = {};
  final Map<String, StreamController<MessageUpdate>> _updateStreams = {};
  final Map<String, StreamController<List<String>>> _typingStreams = {};

  ChatRepositoryImpl() : _supabase = locator<SupabaseClient>();

  @override
  Future<List<Message>> getMessages({
    required String squadId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    return invokeEdgeFunctionList<Message>(
      functionName: 'fetch-messages',
      body: {
        'squadId': squadId,
        'limit': limit,
        if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
      },
      itemParser: _parseMessage,
    );
  }

  @override
  Future<Message> sendMessage({
    required String squadId,
    required MessageType type,
    String? content,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    return invokeEdgeFunction<Message>(
      functionName: 'send-message',
      body: {
        'squadId': squadId,
        'type': type.name,
        if (content != null) 'content': content,
        if (metadata != null) 'metadata': metadata,
        if (replyToId != null) 'replyToId': replyToId,
      },
      parser: (data) => _parseMessage(data['message'] as Map<String, dynamic>),
    );
  }

  @override
  Future<Message> editMessage({
    required String messageId,
    required String content,
  }) async {
    return invokeEdgeFunction<Message>(
      functionName: 'edit-message',
      body: {'messageId': messageId, 'content': content},
      parser: (data) => _parseMessage(data['message'] as Map<String, dynamic>),
    );
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await invokeEdgeFunction<void>(
      functionName: 'delete-message',
      body: {'messageId': messageId},
      parser: (_) {},
    );
  }

  @override
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    await invokeEdgeFunction<void>(
      functionName: 'add-reaction',
      body: {'messageId': messageId, 'emoji': emoji},
      parser: (_) {},
    );
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    await invokeEdgeFunction<void>(
      functionName: 'remove-reaction',
      body: {'messageId': messageId, 'emoji': emoji},
      parser: (_) {},
    );
  }

  @override
  Future<void> markMessagesAsRead({
    required String squadId,
    required List<String> messageIds,
  }) async {
    await invokeEdgeFunction<void>(
      functionName: 'mark-messages-read',
      body: {'squadId': squadId, 'messageIds': messageIds},
      parser: (_) {},
    );
  }

  @override
  Stream<List<String>> getTypingIndicators(String squadId) {
    // Create stream controller if it doesn't exist
    _typingStreams[squadId] ??= StreamController<List<String>>.broadcast();

    // Subscribe to typing channel if not already subscribed
    if (!_channels.containsKey('typing:$squadId')) {
      final channel = _supabase.channel('typing:$squadId');

      channel.onPresenceSync((_) {
        final presence = channel.presenceState();
        final typingUsers = <String>[];

        // presence is a list of SinglePresenceState
        for (final state in presence) {
          if (state.presences.isNotEmpty) {
            final payload = state.presences.first.payload;
            if (payload['typing'] == true) {
              typingUsers.add(payload['user_id'] as String);
            }
          }
        }

        _typingStreams[squadId]?.add(typingUsers);
      }).subscribe();

      _channels['typing:$squadId'] = channel;
    }

    return _typingStreams[squadId]!.stream;
  }

  @override
  Future<void> setTypingIndicator({
    required String squadId,
    required bool isTyping,
  }) async {
    final channel = _channels['typing:$squadId'];
    if (channel != null) {
      await channel.track({'typing': isTyping});
    }
  }

  @override
  Stream<Message> subscribeToMessages(String squadId) {
    // Create stream controller if it doesn't exist
    _messageStreams[squadId] ??= StreamController<Message>.broadcast();

    // Subscribe to message channel if not already subscribed
    if (!_channels.containsKey('messages:$squadId')) {
      final channel = _supabase
          .channel('messages:$squadId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'squad_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'squad_id',
              value: squadId,
            ),
            callback: (payload) async {
              try {
                final messageId = payload.newRecord['id'] as String;
                final profileId = payload.newRecord['profile_id'] as String;

                // Get current user's profile ID
                final currentUser = _supabase.auth.currentUser;
                if (currentUser != null) {
                  try {
                    final currentProfile = await _supabase
                        .from('profiles')
                        .select('id')
                        .eq('user_id', currentUser.id)
                        .single();

                    // Skip if this is the current user's message (we already have it)
                    if (currentProfile['id'] == profileId) {
                      return;
                    }
                  } catch (e) {
                    // User profile not found - continue with fetching the message
                  }
                }

                // Small delay to ensure message is fully committed
                await Future.delayed(const Duration(milliseconds: 500));

                // Fetch full message with joins via edge function
                final message = await _fetchSingleMessage(messageId);
                _messageStreams[squadId]?.add(message);
              } catch (e) {
                print('Error fetching new message in real-time: $e');
                // Ignore the error - the message will be loaded on next refresh
              }
            },
          )
          .subscribe();

      _channels['messages:$squadId'] = channel;
    }

    return _messageStreams[squadId]!.stream;
  }

  @override
  Stream<MessageUpdate> subscribeToMessageUpdates(String squadId) {
    // Create stream controller if it doesn't exist
    _updateStreams[squadId] ??= StreamController<MessageUpdate>.broadcast();

    // Subscribe to updates channel if not already subscribed
    if (!_channels.containsKey('updates:$squadId')) {
      final channel = _supabase
          .channel('updates:$squadId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'squad_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'squad_id',
              value: squadId,
            ),
            callback: (payload) async {
              final messageId = payload.newRecord['id'] as String;
              final isDeleted = payload.newRecord['deleted_at'] != null;

              if (isDeleted) {
                _updateStreams[squadId]?.add(
                  MessageUpdate(
                    messageId: messageId,
                    type: MessageUpdateType.deleted,
                  ),
                );
              } else {
                final message = await _fetchSingleMessage(messageId);
                _updateStreams[squadId]?.add(
                  MessageUpdate(
                    messageId: messageId,
                    type: MessageUpdateType.edited,
                    message: message,
                  ),
                );
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'message_reactions',
            callback: (payload) async {
              final messageId = payload.newRecord['message_id'] as String;
              final message = await _fetchSingleMessage(messageId);
              _updateStreams[squadId]?.add(
                MessageUpdate(
                  messageId: messageId,
                  type: MessageUpdateType.reactionAdded,
                  message: message,
                ),
              );
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'message_reactions',
            callback: (payload) async {
              final messageId = payload.oldRecord['message_id'] as String;
              final message = await _fetchSingleMessage(messageId);
              _updateStreams[squadId]?.add(
                MessageUpdate(
                  messageId: messageId,
                  type: MessageUpdateType.reactionRemoved,
                  message: message,
                ),
              );
            },
          )
          .subscribe();

      _channels['updates:$squadId'] = channel;
    }

    return _updateStreams[squadId]!.stream;
  }

  /// Fetch a single message with full data
  Future<Message> _fetchSingleMessage(String messageId) async {
    return invokeEdgeFunction<Message>(
      functionName: 'fetch-message',
      body: {'messageId': messageId},
      parser: (data) => _parseMessage(data['message'] as Map<String, dynamic>),
    );
  }

  /// Parse message from JSON
  Message _parseMessage(Map<String, dynamic> json) {
    // Map database message type to enum
    final typeString = json['type'] as String;
    final type = MessageType.values.firstWhere(
      (t) =>
          t.name == typeString ||
          (typeString == 'activity_checkin' &&
              t == MessageType.activityCheckin),
      orElse: () => MessageType.text,
    );

    // Parse author if present
    MessageAuthor? author;
    if (json['profile'] != null) {
      final profile = json['profile'] as Map<String, dynamic>;
      author = MessageAuthor(
        id: profile['id'] as String,
        displayName: profile['display_name'] as String,
        avatarUrl: profile['avatar_url'] as String?,
      );
    }

    // Parse reactions
    final reactions = <MessageReaction>[];
    if (json['reactions'] is List) {
      reactions.addAll(
        (json['reactions'] as List).map((r) => MessageReaction.fromJson(r)),
      );
    }

    // Parse read receipts
    final readByProfileIds = <String>[];
    if (json['read_receipts'] is List) {
      readByProfileIds.addAll(
        (json['read_receipts'] as List).map((r) => r['profile_id'] as String),
      );
    }

    return Message(
      id: json['id'] as String,
      squadId: json['squad_id'] as String,
      profileId: json['profile_id'] as String,
      type: type,
      content: json['content'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      replyToId: json['reply_to_id'] as String?,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: author,
      reactions: reactions,
      readByProfileIds: readByProfileIds,
    );
  }

  /// Dispose of all subscriptions
  void dispose() {
    _channels.forEach((_, channel) => channel.unsubscribe());
    _channels.clear();

    _messageStreams.forEach((_, controller) => controller.close());
    _messageStreams.clear();

    _updateStreams.forEach((_, controller) => controller.close());
    _updateStreams.clear();

    _typingStreams.forEach((_, controller) => controller.close());
    _typingStreams.clear();
  }
}
