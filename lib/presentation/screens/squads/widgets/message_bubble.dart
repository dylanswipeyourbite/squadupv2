import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:squadupv2/domain/models/message.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/activity_checkin_card.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/poll_card.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart';

/// Widget for displaying a single message bubble
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback onReply;
  final Function(String) onEdit;
  final VoidCallback onDelete;
  final Function(String) onReaction;
  final Function(String) onRemoveReaction;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReaction,
    required this.onRemoveReaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: isCurrentUser ? 48 : 0,
        right: isCurrentUser ? 0 : 48,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) _buildAvatar(theme),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: message.type == MessageType.text
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? theme.primary
                      : const Color(
                          0xFF0F0F23,
                        ), // Use theme's message background
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reply indicator
                    if (message.replyTo != null) _buildReplyIndicator(theme),

                    // Message content
                    _buildMessageContent(theme),

                    // Message metadata
                    _buildMessageMetadata(theme),

                    // Reactions
                    if (message.reactions.isNotEmpty) _buildReactions(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(SquadUpTheme theme) {
    final displayName = message.author?.displayName ?? 'User';
    final initials = _getInitials(displayName);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: theme.primary.withOpacity(0.1),
        backgroundImage: message.author?.avatarUrl != null
            ? NetworkImage(message.author!.avatarUrl!)
            : null,
        child: message.author?.avatarUrl == null
            ? Text(
                initials,
                style: theme.body2.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              )
            : null,
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  Widget _buildReplyIndicator(SquadUpTheme theme) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? theme.surface.withOpacity(0.5)
                    : theme.primary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.replyTo!.author?.displayName ?? 'Unknown',
                    style: theme.body2.copyWith(
                      color: isCurrentUser
                          ? theme.surface.withOpacity(0.8)
                          : theme.onSurfaceSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    message.replyTo!.content ?? '[Message]',
                    style: theme.body2.copyWith(
                      color: isCurrentUser
                          ? theme.surface.withOpacity(0.7)
                          : theme.onSurfaceSecondary.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(SquadUpTheme theme) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content ?? '',
          style: theme.body1.copyWith(
            color: isCurrentUser ? theme.surface : theme.onSurface,
          ),
        );

      case MessageType.activityCheckin:
        return ActivityCheckInCard(
          metadata: ActivityCheckInMetadata.fromJson(message.metadata!),
          comment: message.content,
          isCurrentUser: isCurrentUser,
        );

      case MessageType.poll:
        return PollCard(
          metadata: PollMetadata.fromJson(message.metadata!),
          isCurrentUser: isCurrentUser,
          onVote: (optionIds) {
            // TODO: Implement voting
          },
        );

      case MessageType.image:
      case MessageType.video:
      case MessageType.voice:
        // TODO: Implement media messages
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                message.type == MessageType.image
                    ? Icons.image
                    : message.type == MessageType.video
                    ? Icons.videocam
                    : Icons.mic,
                color: isCurrentUser ? theme.surface : theme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${message.type.name} message',
                style: theme.body2.copyWith(
                  color: isCurrentUser ? theme.surface : theme.onSurface,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMessageMetadata(SquadUpTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Don't show author name for any messages - it's redundant with avatar
          // and creates visual clutter
          Text(
            _formatTime(message.createdAt),
            style: theme.body2.copyWith(
              color: isCurrentUser
                  ? theme.surface.withOpacity(0.7)
                  : theme.onSurfaceSecondary,
            ),
          ),
          if (message.editedAt != null) ...[
            const SizedBox(width: 4),
            Text(
              '(edited)',
              style: theme.body2.copyWith(
                color: isCurrentUser
                    ? theme.surface.withOpacity(0.7)
                    : theme.onSurfaceSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReactions(SquadUpTheme theme) {
    final groupedReactions = <String, List<MessageReaction>>{};
    for (final reaction in message.reactions) {
      groupedReactions.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final reactions = entry.value;
          final hasReacted = reactions.any(
            (r) => r.profileId == message.profileId,
          );

          return GestureDetector(
            onTap: () {
              if (hasReacted) {
                onRemoveReaction(emoji);
              } else {
                onReaction(emoji);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasReacted
                    ? theme.primary.withOpacity(0.2)
                    : theme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasReacted
                      ? theme.primary.withOpacity(0.5)
                      : theme.onSurfaceSecondary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    reactions.length.toString(),
                    style: theme.body2.copyWith(
                      color: hasReacted
                          ? theme.primary
                          : theme.onSurfaceSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('h:mm a').format(time);
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  void _showMessageOptions(BuildContext context) {
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: theme.onSurfaceSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.reply, color: theme.primary),
                title: Text('Reply', style: theme.body1),
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
              ListTile(
                leading: Icon(Icons.add_reaction, color: theme.primary),
                title: Text('React', style: theme.body1),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(context);
                },
              ),
              if (isCurrentUser && message.type == MessageType.text) ...[
                ListTile(
                  leading: Icon(Icons.edit, color: theme.primary),
                  title: Text('Edit', style: theme.body1),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: theme.error),
                  title: Text(
                    'Delete',
                    style: theme.body1.copyWith(color: theme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showReactionPicker(BuildContext context) {
    const reactions = ['👍', '❤️', '😂', '🔥', '💪', '🏃', '⚡', '🎯'];
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.surface,
          content: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: reactions.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onReaction(emoji);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.content);
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.surface,
          title: Text('Edit Message', style: theme.h3),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Message',
              hintStyle: theme.body1.copyWith(color: theme.onSurfaceSecondary),
            ),
            style: theme.body1,
            autofocus: true,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: theme.body1.copyWith(color: theme.onSurfaceSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (controller.text.trim().isNotEmpty) {
                  onEdit(controller.text.trim());
                }
              },
              child: Text(
                'Save',
                style: theme.body1.copyWith(color: theme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.surface,
          title: Text('Delete Message?', style: theme.h3),
          content: Text(
            'This message will be permanently deleted.',
            style: theme.body1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: theme.body1.copyWith(color: theme.onSurfaceSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
              child: Text(
                'Delete',
                style: theme.body1.copyWith(color: theme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
