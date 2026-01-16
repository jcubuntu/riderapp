import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import 'socket_events.dart';
import 'socket_service.dart';

/// Provider for the socket service singleton
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for socket connection state
final socketConnectionStateProvider =
    StreamProvider<SocketConnectionState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.connectionStateStream;
});

/// Provider for checking if socket is connected
final isSocketConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(socketConnectionStateProvider);
  return connectionState.when(
    data: (state) =>
        state == SocketConnectionState.connected ||
        state == SocketConnectionState.authenticated,
    loading: () => false,
    error: (error, stack) => false,
  );
});

/// Provider for checking if socket is authenticated
final isSocketAuthenticatedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(socketConnectionStateProvider);
  return connectionState.when(
    data: (state) => state == SocketConnectionState.authenticated,
    loading: () => false,
    error: (error, stack) => false,
  );
});

/// Provider that manages socket connection based on auth state
final socketConnectionManagerProvider = Provider<SocketConnectionManager>((ref) {
  final manager = SocketConnectionManager(ref);

  // Listen to auth state changes
  ref.listen<AuthState>(authProvider, (previous, next) {
    manager._handleAuthStateChange(previous, next);
  });

  return manager;
});

/// Socket connection manager that handles auto-connect/disconnect
class SocketConnectionManager {
  final Ref _ref;
  Timer? _reconnectTimer;
  bool _isManuallyDisconnected = false;

  SocketConnectionManager(this._ref);

  SocketService get _socketService => _ref.read(socketServiceProvider);

  /// Handle auth state changes
  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    if (next is AuthAuthenticated) {
      // User authenticated - connect socket
      _connect();
    } else if (next is AuthUnauthenticated ||
        next is AuthError ||
        next is AuthRejected) {
      // User logged out or error - disconnect socket
      _disconnect();
    }
  }

  /// Connect to socket server
  Future<void> _connect() async {
    if (_isManuallyDisconnected) return;

    _log('Connecting socket...');
    try {
      await _socketService.connect();
    } catch (e) {
      _log('Socket connection error: $e');
      _scheduleReconnect();
    }
  }

  /// Disconnect from socket server
  void _disconnect() {
    _log('Disconnecting socket...');
    _cancelReconnect();
    _socketService.disconnect();
  }

  /// Manually connect (call when needed)
  Future<void> connect() async {
    _isManuallyDisconnected = false;
    await _connect();
  }

  /// Manually disconnect
  void disconnect() {
    _isManuallyDisconnected = true;
    _disconnect();
  }

  /// Reconnect to server
  Future<void> reconnect() async {
    _isManuallyDisconnected = false;
    await _socketService.reconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _cancelReconnect();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _connect();
    });
  }

  /// Cancel scheduled reconnection
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SocketConnectionManager] $message');
    }
  }

  void dispose() {
    _cancelReconnect();
  }
}

/// Provider for creating an event stream for specific socket events
final socketEventStreamProvider =
    Provider.family<Stream<dynamic>, String>((ref, eventName) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream(eventName);
});

/// Provider for new chat messages via socket
final socketNewMessageProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream<Map<String, dynamic>>(SocketEvents.newMessage);
});

/// Provider for typing indicators via socket
final socketTypingProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream<Map<String, dynamic>>(SocketEvents.userTyping);
});

/// Provider for location updates via socket
final socketLocationUpdateProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream<Map<String, dynamic>>(SocketEvents.locationUpdated);
});

/// Provider for new notifications via socket
final socketNewNotificationProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream<Map<String, dynamic>>(SocketEvents.newNotification);
});

/// Provider for notification badge count via socket
final socketBadgeCountProvider = StreamProvider<int>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream<int>(SocketEvents.badgeCountUpdate);
});

/// Provider for emergency alerts via socket
final socketEmergencyAlertProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream<Map<String, dynamic>>(SocketEvents.emergencyAlert);
});

/// Provider for incident updates via socket
final socketIncidentUpdateProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream<Map<String, dynamic>>(SocketEvents.incidentUpdated);
});

/// Provider for conversation updates via socket
final socketConversationUpdateProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.eventStream<Map<String, dynamic>>(SocketEvents.conversationUpdated);
});

// ============================================================================
// HELPER PROVIDERS FOR SPECIFIC FEATURES
// ============================================================================

/// Provider that initializes socket when the app starts (if authenticated)
final socketInitializerProvider = FutureProvider<void>((ref) async {
  final authState = ref.watch(authProvider);

  if (authState is AuthAuthenticated) {
    final socketService = ref.read(socketServiceProvider);
    await socketService.init();
    await socketService.connect();
  }
});

/// Provider for current user's online status
final userOnlineStatusProvider = StateProvider<bool>((ref) {
  final isConnected = ref.watch(isSocketAuthenticatedProvider);
  return isConnected;
});

/// Provider for tracking users who are typing in a conversation
final typingUsersProvider =
    StateNotifierProvider.family<TypingUsersNotifier, Set<String>, String>(
  (ref, conversationId) {
    return TypingUsersNotifier(ref, conversationId);
  },
);

/// Notifier for tracking typing users in a conversation
class TypingUsersNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;
  final String _conversationId;
  final Map<String, Timer> _typingTimers = {};

  TypingUsersNotifier(this._ref, this._conversationId) : super({}) {
    _setupListeners();
  }

  void _setupListeners() {
    final socketService = _ref.read(socketServiceProvider);

    // Listen for typing events
    socketService.on(SocketEvents.userTyping, (data) {
      final eventData = data as Map<String, dynamic>?;
      if (eventData == null) return;

      final conversationId = eventData['conversationId'] as String?;
      final userId = eventData['userId'] as String?;

      if (conversationId == _conversationId && userId != null) {
        _addTypingUser(userId);
      }
    });

    // Listen for stop typing events
    socketService.on(SocketEvents.userStoppedTyping, (data) {
      final eventData = data as Map<String, dynamic>?;
      if (eventData == null) return;

      final conversationId = eventData['conversationId'] as String?;
      final userId = eventData['userId'] as String?;

      if (conversationId == _conversationId && userId != null) {
        _removeTypingUser(userId);
      }
    });
  }

  void _addTypingUser(String userId) {
    // Cancel existing timer for this user
    _typingTimers[userId]?.cancel();

    // Add user to typing set
    state = {...state, userId};

    // Set timer to auto-remove after 5 seconds (in case stop event is missed)
    _typingTimers[userId] = Timer(const Duration(seconds: 5), () {
      _removeTypingUser(userId);
    });
  }

  void _removeTypingUser(String userId) {
    _typingTimers[userId]?.cancel();
    _typingTimers.remove(userId);

    state = {...state}..remove(userId);
  }

  @override
  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    super.dispose();
  }
}

/// Provider for tracking nearby users (for location feature)
final nearbySocketUsersProvider =
    StateNotifierProvider<NearbySocketUsersNotifier, List<Map<String, dynamic>>>(
  (ref) => NearbySocketUsersNotifier(ref),
);

/// Notifier for tracking nearby users via socket
class NearbySocketUsersNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref _ref;

  NearbySocketUsersNotifier(this._ref) : super([]) {
    _setupListeners();
  }

  void _setupListeners() {
    final socketService = _ref.read(socketServiceProvider);

    // Listen for nearby users response
    socketService.on(SocketEvents.nearbyUsers, (data) {
      final users = (data as List?)?.cast<Map<String, dynamic>>() ?? [];
      state = users;
    });

    // Listen for individual location updates
    socketService.on(SocketEvents.locationUpdated, (data) {
      final locationData = data as Map<String, dynamic>?;
      if (locationData == null) return;

      final userId = locationData['userId'] as String?;
      if (userId == null) return;

      // Update or add user location
      final existingIndex = state.indexWhere((u) => u['userId'] == userId);
      if (existingIndex >= 0) {
        state = [
          ...state.sublist(0, existingIndex),
          locationData,
          ...state.sublist(existingIndex + 1),
        ];
      } else {
        state = [...state, locationData];
      }
    });

    // Listen for users going offline
    socketService.on(SocketEvents.locationSharingStopped, (data) {
      final userId = (data as Map<String, dynamic>?)?['userId'] as String?;
      if (userId != null) {
        state = state.where((u) => u['userId'] != userId).toList();
      }
    });
  }

  /// Request nearby users update
  void requestNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
  }) {
    final socketService = _ref.read(socketServiceProvider);
    socketService.requestNearbyUsers(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  /// Subscribe to location updates for an area
  void subscribeToArea({
    required double latitude,
    required double longitude,
    double? radius,
  }) {
    final socketService = _ref.read(socketServiceProvider);
    socketService.subscribeToLocations(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  /// Unsubscribe from location updates
  void unsubscribe() {
    final socketService = _ref.read(socketServiceProvider);
    socketService.unsubscribeFromLocations();
  }
}
