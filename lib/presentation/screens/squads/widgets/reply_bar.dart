import 'package:flutter/material.dart';
import 'package:squadupv2/domain/models/message.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart' as app_theme;

/// Reply bar shown when replying to a message
class ReplyBar extends StatelessWidget {
  final Message message;
  final VoidCallback onCancel;

  const ReplyBar({super.key, required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.primary.withOpacity(0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${message.author?.displayName ?? 'Unknown'}',
                  style: theme.body2.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getMessagePreview(message),
                  style: theme.body2.copyWith(color: theme.onSurfaceSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.onSurfaceSecondary),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content ?? '';
      case MessageType.activityCheckin:
        return '🏃 Activity check-in';
      case MessageType.poll:
        return '📊 ${message.content ?? 'Poll'}';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.voice:
        return '🎤 Voice note';
    }
  }
}
