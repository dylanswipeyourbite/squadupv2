import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';
import 'package:squadupv2/presentation/view_models/squad_list_view_model.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart'
    as theme_utils;

/// Overview screen showing all user's squads
class SquadsOverviewScreen extends StatefulWidget {
  const SquadsOverviewScreen({super.key});

  @override
  State<SquadsOverviewScreen> createState() => _SquadsOverviewScreenState();
}

class _SquadsOverviewScreenState extends State<SquadsOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Load squads when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SquadListViewModel>().loadSquads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = theme_utils.SquadUpTheme.of(context);
    final viewModel = context.watch<SquadListViewModel>();

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: colors.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Squads',
                  style: theme.h2.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tap to enter your obsession stream',
                  style: theme.caption.copyWith(
                    color: colors.onSurface.withOpacity(0.6),
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
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add, color: colors.primary, size: 20),
                  ),
                  onPressed: () => context.go('/onboarding/squad-choice'),
                ),
              ),
            ],
          ),

          // Content
          SliverFillRemaining(
            child: viewModel.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  )
                : viewModel.squads.isEmpty
                ? _buildEmptyState(context, theme)
                : _buildSquadsList(context, theme, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    theme_utils.SquadUpTheme theme,
  ) {
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
                Icons.groups_outlined,
                size: 64,
                color: theme.colors.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Squads Yet',
              style: theme.h2.copyWith(
                color: theme.colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join or create a squad to start\nobsessing together',
              textAlign: TextAlign.center,
              style: theme.body1.copyWith(
                color: theme.colors.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/onboarding/squad-choice'),
              icon: const Icon(Icons.add),
              label: const Text('Get Started'),
              style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadsList(
    BuildContext context,
    theme_utils.SquadUpTheme theme,
    SquadListViewModel viewModel,
  ) {
    return RefreshIndicator(
      onRefresh: viewModel.refreshSquads,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.squads.length,
        itemBuilder: (context, index) {
          final squad = viewModel.squads[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colors.onSurface.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colors.onSurface.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                viewModel.setCurrentSquad(squad.id);
                context.go(
                  '/squads/chat/${squad.id}',
                  extra: {'squadName': squad.name},
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        image: squad.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(squad.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: squad.avatarUrl == null
                          ? Center(
                              child: Text(
                                squad.name.isNotEmpty
                                    ? squad.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            squad.name,
                            style: theme.h3.copyWith(
                              color: theme.colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${squad.memberCount} members • ${squad.totalActivities} activities',
                            style: theme.body2.copyWith(
                              color: theme.colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (squad.description != null &&
                              squad.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              squad.description!,
                              style: theme.body2.copyWith(
                                color: theme.colors.onSurface.withOpacity(0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colors.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
