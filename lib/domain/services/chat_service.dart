import 'dart:async';
import 'package:squadupv2/domain/models/message.dart';
import 'package:squadupv2/domain/repositories/chat_repository.dart';
import 'package:squadupv2/core/event_bus.dart';

/// Domain service for chat business logic
class ChatService {
  final ChatRepository _repository;
  final EventBus _eventBus;

  // Cache for messages by squad
  final Map<String, List<Message>> _messagesCache = {};

  // Typing indicator timers
  final Map<String, Timer> _typingTimers = {};

  ChatService({required ChatRepository repository, required EventBus eventBus})
    : _repository = repository,
      _eventBus = eventBus;

  /// Load messages for a squad
  Future<List<Message>> loadMessages({
    required String squadId,
    bool refresh = false,
    String? beforeMessageId,
  }) async {
    if (!refresh &&
        _messagesCache.containsKey(squadId) &&
        beforeMessageId == null) {
      return _messagesCache[squadId]!;
    }

    final messages = await _repository.getMessages(
      squadId: squadId,
      beforeMessageId: beforeMessageId,
    );

    if (beforeMessageId == null) {
      _messagesCache[squadId] = messages;
    } else {
      // Append to existing cache
      _messagesCache[squadId] = [..._messagesCache[squadId] ?? [], ...messages];
    }

    return messages;
  }

  /// Send a text message
  Future<Message> sendTextMessage({
    required String squadId,
    required String content,
    String? replyToId,
  }) async {
    final message = await _repository.sendMessage(
      squadId: squadId,
      type: MessageType.text,
      content: content,
      replyToId: replyToId,
    );

    _addMessageToCache(squadId, message);
    _eventBus.fire(MessageSentEvent(message));

    return message;
  }

  /// Send an activity check-in
  Future<Message> sendActivityCheckIn({
    required String squadId,
    required ActivityCheckInMetadata metadata,
    String? comment,
  }) async {
    final message = await _repository.sendMessage(
      squadId: squadId,
      type: MessageType.activityCheckin,
      content: comment,
      metadata: metadata.toJson(),
    );

    _addMessageToCache(squadId, message);
    _eventBus.fire(MessageSentEvent(message));

    return message;
  }

  /// Send a poll
  Future<Message> sendPoll({
    required String squadId,
    required PollMetadata metadata,
  }) async {
    final message = await _repository.sendMessage(
      squadId: squadId,
      type: MessageType.poll,
      content: metadata.question,
      metadata: metadata.toJson(),
    );

    _addMessageToCache(squadId, message);
    _eventBus.fire(MessageSentEvent(message));

    return message;
  }

  /// Edit a message
  Future<Message> editMessage({
    required String messageId,
    required String content,
  }) async {
    final message = await _repository.editMessage(
      messageId: messageId,
      content: content,
    );

    _updateMessageInCache(message);
    _eventBus.fire(MessageEditedEvent(message));

    return message;
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _repository.deleteMessage(messageId);
    _removeMessageFromCache(messageId);
    _eventBus.fire(MessageDeletedEvent(messageId));
  }

  /// Add a reaction
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    await _repository.addReaction(messageId: messageId, emoji: emoji);
  }

  /// Remove a reaction
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    await _repository.removeReaction(messageId: messageId, emoji: emoji);
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String squadId,
    required List<String> messageIds,
  }) async {
    await _repository.markMessagesAsRead(
      squadId: squadId,
      messageIds: messageIds,
    );
  }

  /// Handle typing indicator
  Future<void> setTyping({
    required String squadId,
    required bool isTyping,
  }) async {
    // Cancel existing timer
    _typingTimers[squadId]?.cancel();

    if (isTyping) {
      await _repository.setTypingIndicator(squadId: squadId, isTyping: true);

      // Auto-stop typing after 5 seconds
      _typingTimers[squadId] = Timer(const Duration(seconds: 5), () {
        _repository.setTypingIndicator(squadId: squadId, isTyping: false);
      });
    } else {
      await _repository.setTypingIndicator(squadId: squadId, isTyping: false);
    }
  }

  /// Subscribe to real-time updates
  Stream<Message> subscribeToNewMessages(String squadId) {
    return _repository.subscribeToMessages(squadId).map((message) {
      _addMessageToCache(squadId, message);
      return message;
    });
  }

  /// Subscribe to message updates
  Stream<MessageUpdate> subscribeToMessageUpdates(String squadId) {
    return _repository.subscribeToMessageUpdates(squadId);
  }

  /// Subscribe to typing indicators
  Stream<List<String>> subscribeToTypingIndicators(String squadId) {
    return _repository.getTypingIndicators(squadId);
  }

  // Helper methods
  void _addMessageToCache(String squadId, Message message) {
    if (!_messagesCache.containsKey(squadId)) {
      _messagesCache[squadId] = [];
    }
    _messagesCache[squadId]!.insert(0, message);
  }

  void _updateMessageInCache(Message message) {
    _messagesCache.forEach((squadId, messages) {
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = message;
      }
    });
  }

  void _removeMessageFromCache(String messageId) {
    _messagesCache.forEach((squadId, messages) {
      messages.removeWhere((m) => m.id == messageId);
    });
  }

  /// Clear cache for a squad
  void clearCache(String squadId) {
    _messagesCache.remove(squadId);
  }

  /// Dispose of resources
  void dispose() {
    _typingTimers.forEach((_, timer) => timer.cancel());
    _typingTimers.clear();
    _messagesCache.clear();
  }
}

// Event classes
class MessageSentEvent {
  final Message message;
  MessageSentEvent(this.message);
}

class MessageEditedEvent {
  final Message message;
  MessageEditedEvent(this.message);
}

class MessageDeletedEvent {
  final String messageId;
  MessageDeletedEvent(this.messageId);
}
