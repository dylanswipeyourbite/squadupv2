import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/presentation/view_models/chat_view_model.dart';
import 'package:squadupv2/presentation/view_models/squad_list_view_model.dart';
import 'package:squadupv2/presentation/screens/squads/obsession_stream_screen.dart';

/// Squad Main screen - wrapper for chat with view model
class SquadMainScreen extends StatefulWidget {
  final String squadId;
  final String squadName;

  const SquadMainScreen({
    super.key,
    required this.squadId,
    required this.squadName,
  });

  @override
  State<SquadMainScreen> createState() => _SquadMainScreenState();
}

class _SquadMainScreenState extends State<SquadMainScreen> {
  late ChatViewModel _chatViewModel;

  @override
  void initState() {
    super.initState();
    // Get ChatViewModel from service locator
    _chatViewModel = locator<ChatViewModel>(
      param1: widget.squadId,
      param2: widget.squadName,
    );

    // Load squads and set current squad using the global provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final squadListViewModel = context.read<SquadListViewModel>();
      squadListViewModel.loadSquads().then((_) {
        squadListViewModel.setCurrentSquad(widget.squadId);
      });
    });
  }

  @override
  void dispose() {
    _chatViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only provide ChatViewModel since SquadListViewModel is global
    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _chatViewModel,
      child: ObsessionStreamScreen(
        squadId: widget.squadId,
        squadName: widget.squadName,
      ),
    );
  }
}
