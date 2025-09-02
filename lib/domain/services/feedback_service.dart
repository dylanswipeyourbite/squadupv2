// lib/domains/services/feedback_service.dart
import 'package:flutter/material.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/theme/squadup_theme.dart';

/// Interface for feedback service to enable testing
abstract class IFeedbackService {
  void show({
    required BuildContext context,
    required String message,
    required FeedbackLevel level,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  });

  void dismiss();
}

/// Levels of feedback severity
enum FeedbackLevel { success, error, warning, info }

/// Implementation of feedback service
class FeedbackServiceImpl implements IFeedbackService {
  ScaffoldFeatureController? _currentSnackBar;

  @override
  void show({
    required BuildContext context,
    required String message,
    required FeedbackLevel level,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // Check if context is still mounted
    if (!context.mounted) return;

    // Get theme and colors
    final theme = Theme.of(context);
    final squadTheme = context.squadUpTheme;

    // Get styling based on level
    final (backgroundColor, contentColor, icon) = _getStyleForLevel(
      level: level,
      theme: theme,
      squadTheme: squadTheme,
    );

    // Create and show SnackBar
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: contentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: contentColor),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: contentColor,
              onPressed: onAction,
            )
          : null,
    );

    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      // Hide current to avoid internal queue edge cases
      messenger.hideCurrentSnackBar();
      // Defer to next frame to avoid build-phase issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _currentSnackBar = messenger.showSnackBar(snackBar);
      });
    } catch (e) {
      debugPrint('FeedbackService: Unable to show SnackBar: $e');
    }
  }

  @override
  void dismiss() {
    _currentSnackBar?.close();
    _currentSnackBar = null;
  }

  (Color backgroundColor, Color contentColor, IconData icon) _getStyleForLevel({
    required FeedbackLevel level,
    required ThemeData theme,
    required SquadUpThemeExtension squadTheme,
  }) {
    final colors = theme.colorScheme;

    switch (level) {
      case FeedbackLevel.success:
        return (
          squadTheme.successColor,
          colors.onPrimary,
          Icons.check_circle_rounded,
        );
      case FeedbackLevel.error:
        return (colors.error, colors.onError, Icons.error_rounded);
      case FeedbackLevel.warning:
        return (
          squadTheme.warningColor,
          colors.onPrimary,
          Icons.warning_rounded,
        );
      case FeedbackLevel.info:
        return (colors.primary, colors.onPrimary, Icons.info_rounded);
    }
  }
}

/// Static API that matches your current usage
/// This class provides the static methods that are used throughout the app
class FeedbackService {
  // Private constructor to prevent instantiation
  FeedbackService._();

  /// Get the service instance from GetIt
  static IFeedbackService get _service => locator<IFeedbackService>();

  /// Show success feedback
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _service.show(
      context: context,
      message: message,
      level: FeedbackLevel.success,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  /// Show error feedback with optional retry action
  static void error(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    Duration? duration,
  }) {
    _service.show(
      context: context,
      message: message,
      level: FeedbackLevel.error,
      duration: duration ?? const Duration(seconds: 4),
      onAction: onRetry,
      actionLabel: onRetry != null ? 'RETRY' : null,
    );
  }

  /// Show warning feedback with optional action
  static void warning(
    BuildContext context,
    String message, {
    VoidCallback? onAction,
    String? actionLabel,
    Duration? duration,
  }) {
    _service.show(
      context: context,
      message: message,
      level: FeedbackLevel.warning,
      duration: duration ?? const Duration(seconds: 3),
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show info feedback
  static void info(BuildContext context, String message, {Duration? duration}) {
    _service.show(
      context: context,
      message: message,
      level: FeedbackLevel.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Show feedback with full control
  static void show({
    required BuildContext context,
    required String message,
    required FeedbackLevel level,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _service.show(
      context: context,
      message: message,
      level: level,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Dismiss current feedback
  static void dismiss() {
    _service.dismiss();
  }
}
