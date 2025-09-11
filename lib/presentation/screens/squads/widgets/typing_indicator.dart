import 'package:flutter/material.dart';
import 'package:squadupv2/presentation/screens/squads/widgets/squadup_theme_utils.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart' as app_theme;

/// Widget showing typing indicators for users
class TypingIndicator extends StatefulWidget {
  final List<String> users;

  const TypingIndicator({super.key, required this.users});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = SquadUpTheme(
      colors: Theme.of(context).colorScheme,
      textTheme: Theme.of(context).textTheme,
    );

    if (widget.users.isEmpty) {
      return const SizedBox.shrink();
    }

    String text;
    if (widget.users.length == 1) {
      text = '${widget.users.first} is typing';
    } else if (widget.users.length == 2) {
      text = '${widget.users.join(' and ')} are typing';
    } else {
      text = '${widget.users.length} people are typing';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 16,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_animation.value - delay).clamp(0.0, 1.0);
                    final y = sin(value * pi) * 3;

                    return Transform.translate(
                      offset: Offset(0, -y),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.onSurfaceSecondary.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.body2.copyWith(
              color: theme.onSurfaceSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

double sin(double x) {
  // Simple sine approximation for animation
  x = x % 1.0;
  if (x < 0.5) {
    return 4 * x * (1 - x);
  } else {
    return -4 * (x - 0.5) * (x - 1.5);
  }
}

const double pi = 3.14159265359;
