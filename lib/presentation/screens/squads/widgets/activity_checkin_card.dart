import 'package:flutter/material.dart';
import 'package:squadupv2/domain/models/message.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart' as app_theme;

/// Card widget for displaying activity check-ins
class ActivityCheckInCard extends StatelessWidget {
  final ActivityCheckInMetadata metadata;
  final String? comment;
  final bool isCurrentUser;

  const ActivityCheckInCard({
    super.key,
    required this.metadata,
    this.comment,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _getActivityIcon(metadata.activityType),
                color: isCurrentUser ? theme.surface : theme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getActivityTitle(),
                style: theme.body1.copyWith(
                  color: isCurrentUser ? theme.surface : theme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (metadata.sufferScore != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getSufferColor(
                      metadata.sufferScore!,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Suffer ${metadata.sufferScore}',
                    style: theme.body2.copyWith(
                      color: isCurrentUser
                          ? theme.surface
                          : _getSufferColor(metadata.sufferScore!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Stats grid
          Row(
            children: [
              _buildStat(
                theme,
                'Distance',
                '${metadata.distanceKm.toStringAsFixed(2)} km',
                Icons.straighten,
              ),
              const SizedBox(width: 16),
              _buildStat(
                theme,
                'Duration',
                _formatDuration(metadata.durationSeconds),
                Icons.timer,
              ),
              if (metadata.paceMinPerKm != null) ...[
                const SizedBox(width: 16),
                _buildStat(
                  theme,
                  'Pace',
                  _formatPace(metadata.paceMinPerKm!),
                  Icons.speed,
                ),
              ],
            ],
          ),

          if (metadata.averageHeartRate != null ||
              metadata.elevationGainMeters != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (metadata.averageHeartRate != null)
                  _buildStat(
                    theme,
                    'Avg HR',
                    '${metadata.averageHeartRate} bpm',
                    Icons.favorite,
                  ),
                if (metadata.averageHeartRate != null &&
                    metadata.elevationGainMeters != null)
                  const SizedBox(width: 16),
                if (metadata.elevationGainMeters != null)
                  _buildStat(
                    theme,
                    'Elevation',
                    '${metadata.elevationGainMeters!.toStringAsFixed(0)}m',
                    Icons.terrain,
                  ),
              ],
            ),
          ],

          // Comment
          if (comment != null && comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? theme.surface.withOpacity(0.1)
                    : theme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comment!,
                style: theme.body2.copyWith(
                  color: isCurrentUser ? theme.surface : theme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(
    SquadUpTheme theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isCurrentUser
                    ? theme.surface.withOpacity(0.7)
                    : theme.onSurfaceSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.body2.copyWith(
                  color: isCurrentUser
                      ? theme.surface.withOpacity(0.7)
                      : theme.onSurfaceSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.body1.copyWith(
              color: isCurrentUser ? theme.surface : theme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'run':
      case 'running':
        return Icons.directions_run;
      case 'ride':
      case 'cycling':
        return Icons.directions_bike;
      case 'swim':
      case 'swimming':
        return Icons.pool;
      case 'walk':
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.fitness_center;
    }
  }

  String _getActivityTitle() {
    final typeLabel = metadata.runType ?? metadata.activityType;
    return typeLabel.substring(0, 1).toUpperCase() + typeLabel.substring(1);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
  }

  String _formatPace(double minPerKm) {
    final minutes = minPerKm.floor();
    final seconds = ((minPerKm - minutes) * 60).round();
    return "$minutes:${seconds.toString().padLeft(2, '0')}/km";
  }

  Color _getSufferColor(int score) {
    if (score <= 3) return Colors.green;
    if (score <= 6) return Colors.orange;
    return Colors.red;
  }
}
