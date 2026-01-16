import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../navigation/app_router.dart';
import '../../shared/models/user_model.dart';
import '../notifications/notification_state.dart';
import 'deep_link_handler.dart';
import 'deep_link_state.dart';

/// Provider for the deep link handler singleton
final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  final handler = DeepLinkHandler();

  // Dispose handler when provider is disposed
  ref.onDispose(() {
    handler.dispose();
  });

  return handler;
});

/// Provider for deep link state - watches the handler's state stream
final deepLinkStateProvider = StreamProvider<DeepLinkState>((ref) {
  final handler = ref.watch(deepLinkHandlerProvider);
  return handler.stateStream;
});

/// Provider for the current deep link state (synchronous)
final currentDeepLinkStateProvider = Provider<DeepLinkState>((ref) {
  final asyncState = ref.watch(deepLinkStateProvider);
  return asyncState.when(
    data: (state) => state,
    loading: () => const DeepLinkInitial(),
    error: (e, s) => const DeepLinkInitial(),
  );
});

/// Provider for pending deep link count
final pendingDeepLinkCountProvider = Provider<int>((ref) {
  final handler = ref.watch(deepLinkHandlerProvider);
  return handler.pendingCount;
});

/// Notifier for managing deep link initialization and state
class DeepLinkNotifier extends StateNotifier<DeepLinkState> {
  final DeepLinkHandler _handler;
  final Ref _ref;
  StreamSubscription<DeepLinkState>? _subscription;
  bool _isInitialized = false;

  DeepLinkNotifier(this._handler, this._ref) : super(const DeepLinkInitial()) {
    _init();
  }

  void _init() {
    // Subscribe to handler state changes
    _subscription = _handler.stateStream.listen((handlerState) {
      state = handlerState;
    });

    // Watch auth state to update handler
    _ref.listen<AuthState>(authProvider, (previous, next) {
      _onAuthStateChanged(next);
    });
  }

  void _onAuthStateChanged(AuthState authState) {
    switch (authState) {
      case AuthAuthenticated(user: final user):
        // User is authenticated, update handler with user
        _handler.updateUser(user);

        // Initialize if not already done
        if (!_isInitialized) {
          _initializeWithRouter();
        }
        break;

      case AuthUnauthenticated():
      case AuthError():
      case AuthRejected():
        // User is not authenticated, clear user but keep handler ready
        // so deep links can be processed after login
        _handler.updateUser(null);
        break;

      case AuthInitial():
      case AuthLoading():
      case AuthPendingApproval():
        // No change needed
        break;
    }
  }

  void _initializeWithRouter() {
    try {
      final router = _ref.read(routerProvider);
      final authState = _ref.read(authProvider);

      UserModel? user;
      if (authState is AuthAuthenticated) {
        user = authState.user;
      }

      _handler.setReady(router: router, user: user);
      _isInitialized = true;

      debugPrint('DeepLinkNotifier: Initialized with router');
    } catch (e) {
      debugPrint('DeepLinkNotifier: Failed to initialize: $e');
    }
  }

  /// Initialize the deep link handler with router
  /// Call this from the app's main widget after router is ready
  void initialize(GoRouter router) {
    if (_isInitialized) {
      _handler.updateRouter(router);
      return;
    }

    final authState = _ref.read(authProvider);

    UserModel? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }

    _handler.setReady(router: router, user: user);
    _isInitialized = true;

    debugPrint('DeepLinkNotifier: Manually initialized with router');
  }

  /// Handle a notification tap
  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    await _handler.handleNotificationTap(data);
  }

  /// Handle a NotificationPayload from the notification system
  Future<void> handleNotificationPayload(NotificationPayload payload) async {
    await _handler.handleNotificationPayload(payload);
  }

  /// Handle a deep link with explicit type and target
  Future<void> handleDeepLink({
    required DeepLinkType type,
    String? targetId,
    String? action,
    Map<String, dynamic>? extra,
  }) async {
    final data = <String, dynamic>{
      'type': type.name,
      if (targetId != null) 'targetId': targetId,
      if (action != null) 'action': action,
      ...?extra,
    };

    await _handler.handleNotificationTap(data);
  }

  /// Navigate to a specific deep link type
  Future<void> navigateTo(DeepLinkType type, {String? targetId}) async {
    await handleDeepLink(type: type, targetId: targetId);
  }

  /// Clear the current deep link state
  void clearState() {
    _handler.clearState();
    state = const DeepLinkInitial();
  }

  /// Clear all pending deep links
  void clearPending() {
    _handler.clearPending();
  }

  /// Check if the handler is ready
  bool get isReady => _handler.isReady;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for the deep link notifier
final deepLinkNotifierProvider =
    StateNotifierProvider<DeepLinkNotifier, DeepLinkState>((ref) {
  final handler = ref.watch(deepLinkHandlerProvider);
  return DeepLinkNotifier(handler, ref);
});

/// Extension methods for easy deep link access
extension DeepLinkRefExtension on WidgetRef {
  /// Get the deep link notifier
  DeepLinkNotifier get deepLink => read(deepLinkNotifierProvider.notifier);

  /// Handle a notification tap
  Future<void> handleNotificationTap(Map<String, dynamic> data) {
    return deepLink.handleNotificationTap(data);
  }

  /// Handle a NotificationPayload
  Future<void> handleNotificationPayload(NotificationPayload payload) {
    return deepLink.handleNotificationPayload(payload);
  }

  /// Navigate to a deep link target
  Future<void> navigateToDeepLink(DeepLinkType type, {String? targetId}) {
    return deepLink.navigateTo(type, targetId: targetId);
  }
}

/// Extension methods for ProviderContainer
extension DeepLinkContainerExtension on ProviderContainer {
  /// Get the deep link handler
  DeepLinkHandler get deepLinkHandler => read(deepLinkHandlerProvider);

  /// Get the deep link notifier
  DeepLinkNotifier get deepLinkNotifier => read(deepLinkNotifierProvider.notifier);

  /// Handle a notification tap
  Future<void> handleNotificationTap(Map<String, dynamic> data) {
    return deepLinkNotifier.handleNotificationTap(data);
  }

  /// Handle a NotificationPayload
  Future<void> handleNotificationPayload(NotificationPayload payload) {
    return deepLinkNotifier.handleNotificationPayload(payload);
  }
}
