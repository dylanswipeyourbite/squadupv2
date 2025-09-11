import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/domain/models/message.dart';
import 'package:squadupv2/presentation/view_models/chat_view_model.dart';
import 'package:squadupv2/presentation/view_models/squad_list_view_model.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/message_bubble.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/message_input.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/typing_indicator.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/reply_bar.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squad_switcher.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart'
    as theme_utils;

/// The main chat screen for a squad - "Obsession Stream"
class ObsessionStreamScreen extends StatefulWidget {
  final String squadId;
  final String squadName;

  const ObsessionStreamScreen({
    super.key,
    required this.squadId,
    required this.squadName,
  });

  @override
  State<ObsessionStreamScreen> createState() => _ObsessionStreamScreenState();
}

class _ObsessionStreamScreenState extends State<ObsessionStreamScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = theme_utils.SquadUpTheme.of(context);

    return Consumer2<ChatViewModel, SquadListViewModel>(
      builder: (context, viewModel, squadListViewModel, child) {
        final currentSquad = squadListViewModel.currentSquad;

        return Scaffold(
          backgroundColor: colors.surface,
          body: CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: colors.surface,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      Theme.of(context).brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                ),
                leadingWidth: 56,
                leading: Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        if (squadListViewModel.squads.length > 1)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${squadListViewModel.squads.length}',
                                  style: TextStyle(
                                    color: colors.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => SquadSwitcher.show(context),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentSquad?.name ?? widget.squadName,
                      style: theme.h3.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (viewModel.typingUsers.isNotEmpty)
                      Text(
                        '${viewModel.typingUsers.join(", ")} typing...',
                        style: theme.body2.copyWith(
                          color: colors.primary,
                          fontSize: 12,
                        ),
                      )
                    else if (currentSquad != null)
                      Text(
                        '${currentSquad.memberCount} members',
                        style: theme.body2.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: colors.onSurface.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        context.push('/squads/details/${widget.squadId}');
                      },
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: colors.onSurface.withOpacity(0.1),
                  ),
                ),
              ),

              // Messages area
              SliverFillRemaining(
                child: Column(
                  children: [
                    // Messages list
                    Expanded(
                      child: viewModel.isLoading && viewModel.messages.isEmpty
                          ? _buildLoadingState(theme)
                          : viewModel.messages.isEmpty
                          ? _buildEmptyState(theme)
                          : Container(
                              decoration: BoxDecoration(color: colors.surface),
                              child: _buildMessagesList(viewModel, theme),
                            ),
                    ),

                    // Bottom area with input
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: colors.onSurface.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Typing indicator
                          if (viewModel.typingUsers.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: TypingIndicator(
                                users: viewModel.typingUsers,
                              ),
                            ),

                          // Reply bar
                          if (viewModel.replyingTo != null)
                            ReplyBar(
                              message: viewModel.replyingTo!,
                              onCancel: () => viewModel.setReplyingTo(null),
                            ),

                          // Message input
                          MessageInput(
                            controller: viewModel.messageController,
                            onSend: viewModel.sendMessage,
                            onTextChanged: viewModel.onTextChanged,
                            onAttachmentTap: () =>
                                _showAttachmentOptions(viewModel),
                            onActivityCheckIn: () =>
                                _showActivityCheckIn(viewModel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(
    ChatViewModel viewModel,
    theme_utils.SquadUpTheme theme,
  ) {
    return ListView.builder(
      controller: viewModel.scrollController,
      reverse: true,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      itemCount: viewModel.messages.length + (viewModel.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading more indicator
        if (viewModel.isLoadingMore && index == viewModel.messages.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colors.primary,
                  ),
                ),
              ),
            ),
          );
        }

        final message = viewModel.messages[index];
        final previousMessage = index < viewModel.messages.length - 1
            ? viewModel.messages[index + 1]
            : null;

        // Check if we need a date separator
        final showDateSeparator = _shouldShowDateSeparator(
          message,
          previousMessage,
        );

        return Column(
          children: [
            if (showDateSeparator)
              _buildDateSeparator(message.createdAt, theme),
            MessageBubble(
              message: message,
              isCurrentUser: message.profileId == viewModel.currentUserId,
              onReply: () => viewModel.setReplyingTo(message),
              onEdit: (content) => viewModel.editMessage(message.id, content),
              onDelete: () => viewModel.deleteMessage(message.id),
              onReaction: (emoji) => viewModel.addReaction(message.id, emoji),
              onRemoveReaction: (emoji) =>
                  viewModel.removeReaction(message.id, emoji),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDateSeparator(Message message, Message? previousMessage) {
    if (previousMessage == null) return true;

    final messageDate = message.createdAt;
    final previousDate = previousMessage.createdAt;

    return messageDate.year != previousDate.year ||
        messageDate.month != previousDate.month ||
        messageDate.day != previousDate.day;
  }

  Widget _buildDateSeparator(DateTime date, theme_utils.SquadUpTheme theme) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String dateText;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      dateText = 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colors.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            dateText,
            style: theme.body2.copyWith(
              color: theme.colors.onSurface.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(theme_utils.SquadUpTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: theme.body1.copyWith(
              color: theme.colors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(theme_utils.SquadUpTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: theme.colors.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to ${widget.squadName}!',
              style: theme.h2.copyWith(
                color: theme.colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is where your squad\'s obsession comes alive.\nStart the conversation!',
              textAlign: TextAlign.center,
              style: theme.body1.copyWith(
                color: theme.colors.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colors.onSurface.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 20,
                    color: theme.colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Share your first run to break the ice!',
                    style: theme.body2.copyWith(
                      color: theme.colors.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(ChatViewModel viewModel) {
    final theme = theme_utils.SquadUpTheme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colors.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildAttachmentOption(
                icon: Icons.photo_camera_rounded,
                label: 'Photo',
                color: theme.colors.primary,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement photo picker
                },
              ),
              _buildAttachmentOption(
                icon: Icons.videocam_rounded,
                label: 'Video',
                color: theme.colors.primary,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement video picker
                },
              ),
              _buildAttachmentOption(
                icon: Icons.mic_rounded,
                label: 'Voice Note',
                color: theme.colors.primary,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement voice recording
                },
              ),
              _buildAttachmentOption(
                icon: Icons.poll_rounded,
                label: 'Poll',
                color: theme.colors.primary,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show poll creation dialog
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = theme_utils.SquadUpTheme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(label, style: theme.h3.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showActivityCheckIn(ChatViewModel viewModel) {
    // Navigate to activity check-in
    context.push('/activities/checkin');
  }
}
