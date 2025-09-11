import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/presentation/view_models/squad_list_view_model.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart';

/// Beautiful squad switcher drawer/sheet
class SquadSwitcher extends StatelessWidget {
  const SquadSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SquadListViewModel>();
    final theme = SquadUpTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: theme.colors.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Squads',
                  style: theme.h2.copyWith(
                    color: theme.colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: theme.colors.primary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/squads');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Squad list
          if (viewModel.isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (viewModel.squads.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 64,
                    color: theme.colors.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No squads yet',
                    style: theme.body1.copyWith(
                      color: theme.colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: viewModel.squads.length,
                itemBuilder: (context, index) {
                  final squad = viewModel.squads[index];
                  final isSelected = squad.id == viewModel.currentSquadId;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colors.primary.withOpacity(0.2),
                        backgroundImage: squad.avatarUrl != null
                            ? NetworkImage(squad.avatarUrl!)
                            : null,
                        child: squad.avatarUrl == null
                            ? Text(
                                squad.name.isNotEmpty
                                    ? squad.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colors.primary,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        squad.name,
                        style: theme.h3.copyWith(
                          color: theme.colors.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${squad.memberCount} members • ${squad.totalActivities} activities',
                        style: theme.body2.copyWith(
                          color: theme.colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colors.primary,
                            )
                          : null,
                      onTap: () {
                        if (!isSelected) {
                          viewModel.setCurrentSquad(squad.id);
                          Navigator.pop(context);
                          context.go(
                            '/squads/chat/${squad.id}',
                            extra: {'squadName': squad.name},
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SquadSwitcher(),
    );
  }
}
