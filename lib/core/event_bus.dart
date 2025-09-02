import 'dart:async';

/// Simple event bus for decoupled communication between components
class EventBus {
  final _streamController = StreamController.broadcast();

  /// Stream of all events
  Stream<dynamic> get stream => _streamController.stream;

  /// Stream of events of a specific type
  Stream<T> on<T>() =>
      _streamController.stream.where((event) => event is T).cast<T>();

  /// Fire an event
  void fire(dynamic event) {
    _streamController.add(event);
  }

  /// Dispose the event bus
  void dispose() {
    _streamController.close();
  }
}

/// Base class for all events
abstract class AppEvent {
  final DateTime timestamp;

  AppEvent() : timestamp = DateTime.now();
}
