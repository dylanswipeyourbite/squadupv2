import 'package:squadupv2/domain/models/message.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Get messages for a squad with pagination
  Future<List<Message>> getMessages({
    required String squadId,
    int limit = 50,
    String? beforeMessageId,
  });

  /// Send a new message
  Future<Message> sendMessage({
    required String squadId,
    required MessageType type,
    String? content,
    Map<String, dynamic>? metadata,
    String? replyToId,
  });

  /// Edit an existing message
  Future<Message> editMessage({
    required String messageId,
    required String content,
  });

  /// Delete a message
  Future<void> deleteMessage(String messageId);

  /// Add a reaction to a message
  Future<void> addReaction({required String messageId, required String emoji});

  /// Remove a reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  });

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String squadId,
    required List<String> messageIds,
  });

  /// Get typing indicators for a squad
  Stream<List<String>> getTypingIndicators(String squadId);

  /// Set typing indicator
  Future<void> setTypingIndicator({
    required String squadId,
    required bool isTyping,
  });

  /// Subscribe to new messages in real-time
  Stream<Message> subscribeToMessages(String squadId);

  /// Subscribe to message updates (edits, deletes, reactions)
  Stream<MessageUpdate> subscribeToMessageUpdates(String squadId);
}

/// Update event for messages
class MessageUpdate {
  final String messageId;
  final MessageUpdateType type;
  final Message? message;

  const MessageUpdate({
    required this.messageId,
    required this.type,
    this.message,
  });
}

enum MessageUpdateType { edited, deleted, reactionAdded, reactionRemoved }
