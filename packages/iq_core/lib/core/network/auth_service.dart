import 'dart:async';

import 'package:dio/dio.dart';

/// Broadcast stream service for auth state changes.
/// 
/// When the API returns 401 (Unauthorized), the interceptor emits
/// an [UnauthorizedEvent] through this stream. The AuthBloc listens
/// to this stream and triggers logout.
///
/// This provides a clean separation: API layer → UI layer (BLoC)
/// without creating circular dependencies.
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Stream controller for auth events (broadcast so multiple listeners work)
  late final Stream<UnauthorizedEvent> unauthorizedStream =
      _unauthorizedStreamController.stream.asBroadcastStream();
  late final _unauthorizedStreamController =
      StreamController<UnauthorizedEvent>.broadcast();

  /// Queue to hold requests while token refresh is in progress.
  final List<RequestOptions> _requestQueue = [];
  bool _isRefreshing = false;

  /// Emit unauthorized event (called by interceptor on 401)
  void emitUnauthorized() {
    _unauthorizedStreamController.add(UnauthorizedEvent());
  }

  /// Check if a request is in the queue
  bool isRequestInQueue(RequestOptions options) {
    return _requestQueue.any((req) => req.path == options.path);
  }

  /// Add request to queue during token refresh
  void queueRequest(RequestOptions options) {
    _requestQueue.add(options);
  }

  /// Get all queued requests
  List<RequestOptions> getQueuedRequests() {
    return List.from(_requestQueue);
  }

  /// Clear the queue
  void clearQueue() {
    _requestQueue.clear();
  }

  /// Set refresh status
  void setRefreshing(bool value) {
    _isRefreshing = value;
  }

  /// Check if refresh is in progress
  bool get isRefreshing => _isRefreshing;

  /// Cleanup (call on app shutdown if needed)
  void dispose() {
    _unauthorizedStreamController.close();
  }
}

/// Event emitted when 401 is received
class UnauthorizedEvent {
  UnauthorizedEvent();
}
