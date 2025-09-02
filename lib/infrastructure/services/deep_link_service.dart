import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/core/event_bus.dart';
import 'package:squadupv2/infrastructure/services/terra_service.dart';
import 'package:go_router/go_router.dart';
import 'package:squadupv2/core/router/app_router.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// Deep link events
class DeepLinkReceivedEvent extends AppEvent {
  final Uri uri;
  DeepLinkReceivedEvent(this.uri);
}

/// Deep link service for handling app links
class DeepLinkService {
  final EventBus _eventBus = locator<EventBus>();
  final TerraService _terraService = locator<TerraService>();

  StreamSubscription<Uri?>? _linkSubscription;

  /// Initialize deep link handling
  Future<void> initialize() async {
    // Handle initial link if app was launched via deep link
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      logger.error('Error handling initial deep link', e);
    }

    // Listen for subsequent deep links
    _linkSubscription = uriLinkStream.listen(
      (Uri? uri) async {
        if (uri != null) {
          await _handleDeepLink(uri);
        }
      },
      onError: (error) {
        logger.error('Error handling deep link', error);
      },
    );
  }

  /// Handle a deep link
  Future<void> _handleDeepLink(Uri uri) async {
    _eventBus.fire(DeepLinkReceivedEvent(uri));

    // Handle Terra callbacks
    if (uri.host == 'terra') {
      await _terraService.handleAuthCallback(uri);

      // Navigate to connect device screen to show status
      navigatorKey.currentContext?.go(AppRoutes.connectDevice);
    }

    // Handle other deep links (squad invites, etc.)
    // TODO: Add more deep link handlers as needed
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
