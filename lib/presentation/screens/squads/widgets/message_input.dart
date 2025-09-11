import 'package:flutter/material.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart';

/// Message input widget with attachments and actions
class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String) onTextChanged;
  final VoidCallback onAttachmentTap;
  final VoidCallback onActivityCheckIn;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onTextChanged,
    required this.onAttachmentTap,
    required this.onActivityCheckIn,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onTextChanged(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          top: BorderSide(color: theme.onSurfaceSecondary.withOpacity(0.1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.primary),
            onPressed: widget.onAttachmentTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 8),

          // Input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(
                  0xFF0F0F23,
                ), // Consistent with message bubbles
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      decoration: InputDecoration(
                        hintText: 'Message @sage...',
                        hintStyle: theme.body1.copyWith(
                          color: theme.onSurfaceSecondary.withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      style: theme.body1.copyWith(color: theme.onSurface),
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  // Quick actions inside input
                  if (!_hasText) ...[
                    IconButton(
                      icon: Icon(
                        Icons.directions_run,
                        color: theme.onSurfaceSecondary,
                        size: 20,
                      ),
                      onPressed: widget.onActivityCheckIn,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      tooltip: 'Activity check-in',
                    ),
                    const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: Icon(
                _hasText ? Icons.send : Icons.mic,
                color: _hasText ? theme.primary : theme.onSurfaceSecondary,
              ),
              onPressed: _hasText ? widget.onSend : _recordVoiceNote,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
    );
  }

  void _recordVoiceNote() {
    // TODO: Implement voice recording
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Voice notes coming soon',
          style: theme.body2.copyWith(color: theme.surface),
        ),
        backgroundColor: theme.primary,
      ),
    );
  }
}
