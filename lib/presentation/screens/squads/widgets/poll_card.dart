import 'package:flutter/material.dart';
import 'package:squadupv2/domain/models/message.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart' as app_theme;

/// Card widget for displaying polls
class PollCard extends StatelessWidget {
  final PollMetadata metadata;
  final bool isCurrentUser;
  final Function(List<String>) onVote;

  const PollCard({
    super.key,
    required this.metadata,
    required this.isCurrentUser,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );
    final totalVotes = metadata.votes.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll icon and question
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.poll,
                color: isCurrentUser ? theme.surface : theme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metadata.question,
                  style: theme.body1.copyWith(
                    color: isCurrentUser ? theme.surface : theme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Options
          ...metadata.options.map((option) {
            final optionVotes = metadata.votes
                .where((vote) => vote.optionIds.contains(option.id))
                .length;
            final percentage = totalVotes > 0
                ? (optionVotes / totalVotes * 100).round()
                : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onVote([option.id]),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentUser
                          ? theme.surface.withOpacity(0.3)
                          : theme.onSurfaceSecondary.withOpacity(0.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Progress bar
                      FractionallySizedBox(
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                (isCurrentUser ? theme.surface : theme.primary)
                                    .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          height: 48,
                        ),
                      ),
                      // Content
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.text,
                                style: theme.body1.copyWith(
                                  color: isCurrentUser
                                      ? theme.surface
                                      : theme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: theme.body2.copyWith(
                                color: isCurrentUser
                                    ? theme.surface.withOpacity(0.7)
                                    : theme.onSurfaceSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($optionVotes)',
                              style: theme.body2.copyWith(
                                color: isCurrentUser
                                    ? theme.surface.withOpacity(0.5)
                                    : theme.onSurfaceSecondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          // Footer
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 14,
                color: isCurrentUser
                    ? theme.surface.withOpacity(0.5)
                    : theme.onSurfaceSecondary.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
                style: theme.body2.copyWith(
                  color: isCurrentUser
                      ? theme.surface.withOpacity(0.5)
                      : theme.onSurfaceSecondary.withOpacity(0.7),
                ),
              ),
              if (metadata.deadline != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.timer,
                  size: 14,
                  color: isCurrentUser
                      ? theme.surface.withOpacity(0.5)
                      : theme.onSurfaceSecondary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDeadline(metadata.deadline!),
                  style: theme.body2.copyWith(
                    color: isCurrentUser
                        ? theme.surface.withOpacity(0.5)
                        : theme.onSurfaceSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Ended';
    } else if (difference.inDays > 0) {
      return 'Ends in ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Ends in ${difference.inHours}h';
    } else {
      return 'Ends in ${difference.inMinutes}m';
    }
  }
}
