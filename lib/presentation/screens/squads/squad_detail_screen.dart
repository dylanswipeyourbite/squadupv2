import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/presentation/view_models/squad_detail_view_model.dart';
import 'package:squadupv2/domain/models/squad.dart';
import 'package:squadupv2/core/router/app_router.dart';

/// Squad Detail screen showing members, stats, and management options
class SquadDetailScreen extends StatelessWidget {
  final String squadId;

  const SquadDetailScreen({super.key, required this.squadId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SquadDetailViewModel(squadId: squadId),
      child: const _SquadDetailView(),
    );
  }
}

class _SquadDetailView extends StatelessWidget {
  const _SquadDetailView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SquadDetailViewModel>();

    if (viewModel.isLoading) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final squad = viewModel.squad;
    if (squad == null) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text('Squad not found', style: context.textTheme.titleLarge),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text(squad.name),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.colors.onSurface),
            color: context.colors.surface,
            onSelected: (value) {
              switch (value) {
                case 'leave':
                  viewModel.showLeaveConfirmation(context);
                  break;
                case 'delete':
                  viewModel.showDeleteConfirmation(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              if (!viewModel.isCaptain)
                PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        color: context.colors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Leave Squad',
                        style: TextStyle(color: context.colors.error),
                      ),
                    ],
                  ),
                ),
              if (viewModel.isCaptain)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever,
                        color: context.colors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Squad',
                        style: TextStyle(color: context.colors.error),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Squad info card
            _buildSquadInfoCard(context, squad, viewModel),
            const SizedBox(height: 24),

            // Stats section
            _buildStatsSection(context, viewModel),
            const SizedBox(height: 24),

            // Members section
            _buildMembersSection(context, viewModel),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(context, squad, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadInfoCard(
    BuildContext context,
    Squad squad,
    SquadDetailViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.squadUpTheme.squadCardDecoration.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (squad.avatarUrl != null)
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(squad.avatarUrl!),
                )
              else
                CircleAvatar(
                  radius: 30,
                  backgroundColor: context.colors.primary,
                  child: Text(
                    squad.name.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: context.colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      squad.name,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (squad.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        squad.description!,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: context.colors.outline.withOpacity(0.3)),
          const SizedBox(height: 16),

          // Invite code section (captain only)
          if (viewModel.isCaptain) ...[
            Row(
              children: [
                Icon(Icons.vpn_key, size: 20, color: context.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Invite Code',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.colors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      squad.inviteCode,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: context.colors.primary),
                    onPressed: () => viewModel.copyInviteCode(context),
                    tooltip: 'Copy invite code',
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: context.colors.primary),
                    onPressed: () => viewModel.shareInviteCode(context),
                    tooltip: 'Share invite code',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    SquadDetailViewModel viewModel,
  ) {
    final stats = viewModel.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Squad Stats',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.directions_run,
                label: 'Total Distance',
                value: '${stats['totalDistance'] ?? 0} km',
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.event,
                label: 'Activities',
                value: '${stats['totalActivities'] ?? 0}',
                color: context.squadUpTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.timer,
                label: 'This Week',
                value: '${stats['weeklyDistance'] ?? 0} km',
                color: context.squadUpTheme.warningColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.people,
                label: 'Active Members',
                value: '${stats['activeMembers'] ?? 0}',
                color: context.squadUpTheme.sufferColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    SquadDetailViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${viewModel.members.length} members',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...viewModel.members.map(
          (member) => _buildMemberTile(context, member, viewModel),
        ),
      ],
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    SquadMember member,
    SquadDetailViewModel viewModel,
  ) {
    final isCaptain = member.role == SquadRole.captain;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outline.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCaptain
              ? context.colors.primary
              : context.colors.surfaceContainerHighest,
          child: member.avatarUrl != null
              ? null
              : Text(
                  member.displayName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: isCaptain
                        ? context.colors.onPrimary
                        : context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          backgroundImage: member.avatarUrl != null
              ? NetworkImage(member.avatarUrl!)
              : null,
        ),
        title: Row(
          children: [
            Text(member.displayName),
            if (isCaptain) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Captain',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${member.totalActivities} activities • ${member.totalDistanceKm.toStringAsFixed(1)} km',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        trailing: member.lastActivityAt != null
            ? Text(
                _formatLastActivity(member.lastActivityAt!),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Squad squad,
    SquadDetailViewModel viewModel,
  ) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: () => context.go('/squads/chat/${squad.id}'),
          icon: const Icon(Icons.chat),
          label: const Text('Open Squad Chat'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Icons.home),
          label: const Text('Back to Home'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }
}
