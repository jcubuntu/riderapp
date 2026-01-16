import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/app_router.dart';
import '../../shared/models/user_model.dart';
import '../notifications/notification_state.dart';
import 'deep_link_state.dart';

/// Handler for processing deep links and navigation from notifications
class DeepLinkHandler {
  /// Queue of pending deep links waiting to be processed
  final List<PendingDeepLink> _pendingQueue = [];

  /// Whether the app is ready to handle deep links
  bool _isReady = false;

  /// Current authenticated user (for role-based routing)
  UserModel? _currentUser;

  /// GoRouter instance for navigation
  GoRouter? _router;

  /// Stream controller for deep link state changes
  final _stateController = StreamController<DeepLinkState>.broadcast();

  /// Current state
  DeepLinkState _state = const DeepLinkInitial();

  /// Stream of deep link state changes
  Stream<DeepLinkState> get stateStream => _stateController.stream;

  /// Current state
  DeepLinkState get state => _state;

  /// Whether the handler is ready to process deep links
  bool get isReady => _isReady;

  /// Number of pending deep links in queue
  int get pendingCount => _pendingQueue.length;

  /// Set the app as ready to handle deep links
  void setReady({
    required GoRouter router,
    UserModel? user,
  }) {
    _router = router;
    _currentUser = user;
    _isReady = true;

    // Process any queued deep links
    _processQueue();
  }

  /// Update the current user (call when auth state changes)
  void updateUser(UserModel? user) {
    _currentUser = user;

    // If user just logged in and we have pending deep links, process them
    if (user != null && _isReady) {
      _processQueue();
    }
  }

  /// Update the router instance
  void updateRouter(GoRouter router) {
    _router = router;
  }

  /// Set the app as not ready (e.g., during logout)
  void setNotReady() {
    _isReady = false;
    _currentUser = null;
  }

  /// Handle a notification tap by parsing data and navigating
  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    if (data.isEmpty) {
      debugPrint('DeepLinkHandler: Received empty notification data');
      return;
    }

    debugPrint('DeepLinkHandler: Handling notification tap: $data');

    final deepLink = PendingDeepLink.fromNotificationData(data);

    if (deepLink.type == DeepLinkType.unknown) {
      debugPrint('DeepLinkHandler: Unknown deep link type');
      _updateState(DeepLinkFailed(deepLink, 'Unknown deep link type'));
      return;
    }

    if (_isReady && _currentUser != null) {
      // App is ready, process immediately
      await _processDeepLink(deepLink);
    } else {
      // Queue for later processing
      _queueDeepLink(deepLink);
    }
  }

  /// Handle a NotificationPayload from the notification system
  Future<void> handleNotificationPayload(NotificationPayload payload) async {
    debugPrint('DeepLinkHandler: Handling notification payload: ${payload.type}');

    final deepLink = PendingDeepLink.fromNotificationPayload(payload);

    if (deepLink.type == DeepLinkType.unknown) {
      debugPrint('DeepLinkHandler: Unknown deep link type from payload');
      _updateState(DeepLinkFailed(deepLink, 'Unknown deep link type'));
      return;
    }

    if (_isReady && _currentUser != null) {
      // App is ready, process immediately
      await _processDeepLink(deepLink);
    } else {
      // Queue for later processing
      _queueDeepLink(deepLink);
    }
  }

  /// Queue a deep link for later processing
  void _queueDeepLink(PendingDeepLink deepLink) {
    // Remove any existing deep links of the same type to avoid duplicates
    _pendingQueue.removeWhere((link) => link.type == deepLink.type);

    _pendingQueue.add(deepLink);
    _updateState(DeepLinkPending(deepLink));

    debugPrint('DeepLinkHandler: Queued deep link: $deepLink');
    debugPrint('DeepLinkHandler: Queue size: ${_pendingQueue.length}');
  }

  /// Process all queued deep links
  Future<void> _processQueue() async {
    if (_pendingQueue.isEmpty) return;

    debugPrint('DeepLinkHandler: Processing queue with ${_pendingQueue.length} items');

    // Remove expired deep links
    _pendingQueue.removeWhere((link) => !link.isValid);

    if (_pendingQueue.isEmpty) {
      debugPrint('DeepLinkHandler: All queued deep links expired');
      return;
    }

    // Process the most recent deep link (last in queue)
    final deepLink = _pendingQueue.removeLast();

    // Clear the rest of the queue
    _pendingQueue.clear();

    await _processDeepLink(deepLink);
  }

  /// Process a single deep link
  Future<void> _processDeepLink(PendingDeepLink deepLink) async {
    if (_router == null) {
      debugPrint('DeepLinkHandler: Router not available');
      _updateState(DeepLinkFailed(deepLink, 'Router not available'));
      return;
    }

    _updateState(DeepLinkProcessing(deepLink));

    try {
      final route = _getRouteForDeepLink(deepLink);

      if (route == null) {
        debugPrint('DeepLinkHandler: No route found for deep link: $deepLink');
        _updateState(DeepLinkFailed(deepLink, 'No route found'));
        return;
      }

      debugPrint('DeepLinkHandler: Navigating to: $route');

      // Use go() for full navigation with redirect handling
      _router!.go(route);

      _updateState(DeepLinkProcessed(deepLink, navigatedTo: route));
    } catch (e) {
      debugPrint('DeepLinkHandler: Error processing deep link: $e');
      _updateState(DeepLinkFailed(deepLink, e.toString()));
    }
  }

  /// Get the route path for a deep link
  String? _getRouteForDeepLink(PendingDeepLink deepLink) {
    switch (deepLink.type) {
      case DeepLinkType.chat:
        if (deepLink.hasTargetId) {
          return '${AppRoutes.chat}/${deepLink.targetId}';
        }
        return AppRoutes.chat;

      case DeepLinkType.incident:
        if (deepLink.hasTargetId) {
          return '${AppRoutes.incidents}/${deepLink.targetId}';
        }
        return AppRoutes.incidents;

      case DeepLinkType.announcement:
        if (deepLink.hasTargetId) {
          return '${AppRoutes.announcements}/${deepLink.targetId}';
        }
        return AppRoutes.announcements;

      case DeepLinkType.sos:
        return '${AppRoutes.emergency}/sos';

      case DeepLinkType.approval:
        return _getApprovalRoute();

      case DeepLinkType.unknown:
        return null;
    }
  }

  /// Get the appropriate approval route based on user role
  String _getApprovalRoute() {
    if (_currentUser == null) {
      return AppRoutes.profile;
    }

    // Admins and users with approval permissions go to pending approvals
    if (_currentUser!.canApproveUsers) {
      return AppRoutes.pendingApprovals;
    }

    // Regular users go to their profile
    return AppRoutes.profile;
  }

  /// Clear the current state
  void clearState() {
    _updateState(const DeepLinkInitial());
  }

  /// Clear all pending deep links
  void clearPending() {
    _pendingQueue.clear();
    if (_state is DeepLinkPending) {
      _updateState(const DeepLinkInitial());
    }
  }

  /// Update internal state and notify listeners
  void _updateState(DeepLinkState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Dispose of resources
  void dispose() {
    _stateController.close();
    _pendingQueue.clear();
  }
}
