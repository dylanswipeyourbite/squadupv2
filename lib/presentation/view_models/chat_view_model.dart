import 'dart:async';
import 'package:flutter/material.dart';
import 'package:squadupv2/domain/models/message.dart';
import 'package:squadupv2/domain/services/chat_service.dart';
import 'package:squadupv2/domain/services/feedback_service.dart';
import 'package:squadupv2/domain/repositories/chat_repository.dart';
import 'package:squadupv2/infrastructure/services/auth_service.dart';
import 'package:squadupv2/core/service_locator.dart';

/// ViewModel for chat functionality
class ChatViewModel extends ChangeNotifier {
  final String squadId;
  final String squadName;
  final ChatService _chatService;
  final AuthService _authService;

  // State
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  List<String> _typingUsers = [];

  // Subscriptions
  StreamSubscription<Message>? _newMessageSubscription;
  StreamSubscription<MessageUpdate>? _updateSubscription;
  StreamSubscription<List<String>>? _typingSubscription;

  // Controllers
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Reply state
  Message? _replyingTo;

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  List<String> get typingUsers => _typingUsers;
  Message? get replyingTo => _replyingTo;
  String? get currentUserId => _authService.currentUser?.id;

  ChatViewModel({
    required this.squadId,
    required this.squadName,
    required ChatService chatService,
    required AuthService authService,
    required IFeedbackService feedbackService,
  }) : _chatService = chatService,
       _authService = authService {
    _init();
  }

  void _init() {
    // Set up scroll listener for pagination
    scrollController.addListener(_onScroll);

    // Load initial messages
    loadMessages();

    // Subscribe to real-time updates
    _subscribeToUpdates();
  }

  /// Load messages
  Future<void> loadMessages({bool refresh = false}) async {
    if (_isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      print('Loading messages for squad: $squadId');
      final messages = await _chatService.loadMessages(
        squadId: squadId,
        refresh: refresh,
      );

      print('Loaded ${messages.length} messages');
      _messages = messages;
      _hasMore = messages.length >= 50;
      notifyListeners();
    } catch (e) {
      print('Error loading messages: $e');
      _error = e.toString();
      // Error is already stored in _error, UI will show it
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _messages.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final oldestMessage = _messages.last;
      final moreMessages = await _chatService.loadMessages(
        squadId: squadId,
        beforeMessageId: oldestMessage.id,
      );

      if (moreMessages.isEmpty || moreMessages.length < 50) {
        _hasMore = false;
      }

      _messages = [..._messages, ...moreMessages];
      notifyListeners();
    } catch (e) {
      // Error handled silently for pagination
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Send a text message
  Future<void> sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    // Clear input immediately
    messageController.clear();

    try {
      await _chatService.sendTextMessage(
        squadId: squadId,
        content: content,
        replyToId: _replyingTo?.id,
      );

      // Clear reply state
      _replyingTo = null;
      notifyListeners();

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      // Error handled - restore text
      print('Error sending message: $e');
      // Restore the text
      messageController.text = content;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Send an activity check-in
  Future<void> sendActivityCheckIn(
    ActivityCheckInMetadata metadata, {
    String? comment,
  }) async {
    try {
      await _chatService.sendActivityCheckIn(
        squadId: squadId,
        metadata: metadata,
        comment: comment,
      );

      _scrollToBottom();
    } catch (e) {
      // Error handled
    }
  }

  /// Send a poll
  Future<void> sendPoll(PollMetadata metadata) async {
    try {
      await _chatService.sendPoll(squadId: squadId, metadata: metadata);

      _scrollToBottom();
    } catch (e) {
      // Error handled
    }
  }

  /// Edit a message
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _chatService.editMessage(messageId: messageId, content: newContent);
    } catch (e) {
      // Error handled
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
    } catch (e) {
      // Error handled
    }
  }

  /// Add a reaction
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      await _chatService.addReaction(messageId: messageId, emoji: emoji);
    } catch (e) {
      // Error handled
    }
  }

  /// Remove a reaction
  Future<void> removeReaction(String messageId, String emoji) async {
    try {
      await _chatService.removeReaction(messageId: messageId, emoji: emoji);
    } catch (e) {
      // Error handled
    }
  }

  /// Set reply target
  void setReplyingTo(Message? message) {
    _replyingTo = message;
    notifyListeners();

    if (message != null) {
      // Focus the input
      // This would be done in the UI with a FocusNode
    }
  }

  /// Handle typing indicator
  void onTextChanged(String text) {
    final isTyping = text.trim().isNotEmpty;
    _chatService.setTyping(squadId: squadId, isTyping: isTyping);
  }

  /// Mark visible messages as read
  void markVisibleMessagesAsRead() {
    final unreadMessages = _messages
        .where(
          (m) =>
              m.profileId != currentUserId &&
              !m.readByProfileIds.contains(currentUserId),
        )
        .take(20) // Limit to visible messages
        .map((m) => m.id)
        .toList();

    if (unreadMessages.isNotEmpty) {
      _chatService.markMessagesAsRead(
        squadId: squadId,
        messageIds: unreadMessages,
      );
    }
  }

  /// Subscribe to real-time updates
  void _subscribeToUpdates() {
    // New messages
    _newMessageSubscription = _chatService
        .subscribeToNewMessages(squadId)
        .listen((message) {
          // Add to beginning of list
          _messages = [message, ..._messages];
          notifyListeners();

          // Auto-scroll if near bottom
          if (_isNearBottom()) {
            _scrollToBottom();
          }
        });

    // Message updates
    _updateSubscription = _chatService
        .subscribeToMessageUpdates(squadId)
        .listen((update) {
          final index = _messages.indexWhere((m) => m.id == update.messageId);
          if (index != -1) {
            if (update.type == MessageUpdateType.deleted) {
              _messages.removeAt(index);
            } else if (update.message != null) {
              _messages[index] = update.message!;
            }
            notifyListeners();
          }
        });

    // Typing indicators
    _typingSubscription = _chatService
        .subscribeToTypingIndicators(squadId)
        .listen((users) {
          // Filter out current user
          _typingUsers = users.where((u) => u != currentUserId).toList();
          notifyListeners();
        });
  }

  /// Check if scroll is near bottom
  bool _isNearBottom() {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    return position.pixels <= position.minScrollExtent + 100;
  }

  /// Scroll to bottom
  void _scrollToBottom() {
    if (!scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Handle scroll events for pagination
  void _onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      loadMoreMessages();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    _newMessageSubscription?.cancel();
    _updateSubscription?.cancel();
    _typingSubscription?.cancel();
    _chatService.clearCache(squadId);
    super.dispose();
  }
}
