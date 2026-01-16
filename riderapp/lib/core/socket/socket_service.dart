import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';
import 'socket_events.dart';

/// Connection state enum for socket
enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  authenticated,
  error,
}

/// Socket.io client service for real-time communication.
///
/// Provides:
/// - Connection management with JWT authentication
/// - Automatic reconnection handling
/// - Event emission and subscription
/// - Connection state management
class SocketService {
  /// Private constructor for singleton
  SocketService._internal();

  /// Singleton instance
  static final SocketService _instance = SocketService._internal();

  /// Factory constructor returns singleton
  factory SocketService() => _instance;

  /// Socket.io client instance
  io.Socket? _socket;

  /// Secure storage for tokens
  final SecureStorage _secureStorage = SecureStorage();

  /// Connection state
  SocketConnectionState _connectionState = SocketConnectionState.disconnected;

  /// Connection state stream controller
  final _connectionStateController =
      StreamController<SocketConnectionState>.broadcast();

  /// Event stream controllers by event name
  final Map<String, StreamController<dynamic>> _eventControllers = {};

  /// Pending event listeners to be registered after connection
  final Map<String, List<Function(dynamic)>> _pendingListeners = {};

  /// Current user ID (set after authentication)
  String? _currentUserId;

  /// Whether service has been initialized
  bool _isInitialized = false;

  /// Reconnection attempt count
  int _reconnectAttempts = 0;

  /// Maximum reconnection attempts
  static const int maxReconnectAttempts = 10;

  /// Reconnection delay in milliseconds
  static const int reconnectDelay = 1000;

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Get current connection state
  SocketConnectionState get connectionState => _connectionState;

  /// Stream of connection state changes
  Stream<SocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Check if connected
  bool get isConnected =>
      _connectionState == SocketConnectionState.connected ||
      _connectionState == SocketConnectionState.authenticated;

  /// Check if authenticated
  bool get isAuthenticated =>
      _connectionState == SocketConnectionState.authenticated;

  /// Get socket ID
  String? get socketId => _socket?.id;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  // ============================================================================
  // INITIALIZATION & CONNECTION
  // ============================================================================

  /// Initialize the socket service
  Future<void> init() async {
    if (_isInitialized) return;

    await _secureStorage.init();
    _isInitialized = true;
  }

  /// Connect to the socket server with authentication
  Future<void> connect({String? baseUrl}) async {
    if (!_isInitialized) {
      await init();
    }

    // Don't reconnect if already connected
    if (_socket != null && _socket!.connected) {
      _log('Already connected');
      return;
    }

    // Get auth token
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      _log('No auth token available');
      _updateConnectionState(SocketConnectionState.error);
      return;
    }

    // Build socket URL
    final socketUrl = baseUrl ?? _getSocketUrl();

    _log('Connecting to: $socketUrl');
    _updateConnectionState(SocketConnectionState.connecting);

    // Create socket with options
    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(maxReconnectAttempts)
          .setReconnectionDelay(reconnectDelay)
          .setReconnectionDelayMax(5000)
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    // Set up event handlers
    _setupEventHandlers();

    // Connect
    _socket!.connect();
  }

  /// Get socket URL from API endpoints
  String _getSocketUrl() {
    // Convert HTTP URL to WebSocket URL
    String url = ApiEndpoints.baseUrl;

    // Remove /api/v1 suffix to get base server URL
    url = url.replaceAll('/api/v1', '');
    url = url.replaceAll('/api', '');

    return url;
  }

  /// Setup core event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _log('Connected - Socket ID: ${_socket!.id}');
      _reconnectAttempts = 0;
      _updateConnectionState(SocketConnectionState.connected);

      // Authenticate after connection
      _authenticate();
    });

    _socket!.onDisconnect((_) {
      _log('Disconnected');
      _updateConnectionState(SocketConnectionState.disconnected);
    });

    _socket!.onConnectError((error) {
      _log('Connection error: $error');
      _updateConnectionState(SocketConnectionState.error);
    });

    _socket!.onError((error) {
      _log('Socket error: $error');
    });

    // Reconnection events
    _socket!.on(SocketEvents.reconnect, (_) {
      _log('Reconnected');
      _reconnectAttempts = 0;
      _authenticate();
    });

    _socket!.on(SocketEvents.reconnectAttempt, (attempt) {
      _reconnectAttempts = attempt as int? ?? _reconnectAttempts + 1;
      _log('Reconnection attempt: $_reconnectAttempts');
    });

    _socket!.on(SocketEvents.reconnectError, (error) {
      _log('Reconnection error: $error');
    });

    _socket!.on(SocketEvents.reconnectFailed, (_) {
      _log('Reconnection failed');
      _updateConnectionState(SocketConnectionState.error);
    });

    // Authentication response
    _socket!.on(SocketEvents.authenticated, (data) {
      _log('Authenticated successfully');
      _currentUserId = data?['userId'] as String?;
      _updateConnectionState(SocketConnectionState.authenticated);

      // Register pending listeners
      _registerPendingListeners();
    });

    _socket!.on(SocketEvents.authError, (data) {
      _log('Authentication error: $data');
      _updateConnectionState(SocketConnectionState.error);
    });
  }

  /// Authenticate with the server after connection
  Future<void> _authenticate() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      _log('No token for authentication');
      return;
    }

    _log('Sending authentication...');
    emit(SocketEvents.authenticate, {'token': token});
  }

  /// Register pending listeners after authentication
  void _registerPendingListeners() {
    _pendingListeners.forEach((event, listeners) {
      for (final listener in listeners) {
        _socket?.on(event, listener);
      }
    });
    _pendingListeners.clear();
  }

  /// Disconnect from the socket server
  void disconnect() {
    _log('Disconnecting...');

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _currentUserId = null;
    _reconnectAttempts = 0;

    _updateConnectionState(SocketConnectionState.disconnected);
  }

  /// Reconnect to the server
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }

  // ============================================================================
  // EVENT EMISSION
  // ============================================================================

  /// Emit an event to the server
  void emit(String event, [dynamic data]) {
    if (_socket == null || !_socket!.connected) {
      _log('Cannot emit - not connected');
      return;
    }

    _log('Emitting: $event');
    _socket!.emit(event, data);
  }

  /// Emit an event and wait for acknowledgement
  Future<T?> emitWithAck<T>(
    String event, [
    dynamic data,
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    if (_socket == null || !_socket!.connected) {
      _log('Cannot emit - not connected');
      return null;
    }

    _log('Emitting with ack: $event');

    final completer = Completer<T?>();

    _socket!.emitWithAck(event, data, ack: (response) {
      if (!completer.isCompleted) {
        completer.complete(response as T?);
      }
    });

    // Add timeout
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _log('Emit ack timeout: $event');
        return null;
      },
    );
  }

  // ============================================================================
  // EVENT SUBSCRIPTION
  // ============================================================================

  /// Listen to an event from the server
  void on(String event, void Function(dynamic) callback) {
    if (_socket != null && _socket!.connected) {
      _socket!.on(event, callback);
    } else {
      // Store for later registration
      _pendingListeners.putIfAbsent(event, () => []).add(callback);
    }
  }

  /// Listen to an event once
  void once(String event, void Function(dynamic) callback) {
    _socket?.once(event, callback);
  }

  /// Remove a specific listener for an event
  void off(String event, [void Function(dynamic)? callback]) {
    if (callback != null) {
      _socket?.off(event, callback);
      _pendingListeners[event]?.remove(callback);
    } else {
      _socket?.off(event);
      _pendingListeners.remove(event);
    }
  }

  /// Get a stream of events for a specific event name
  Stream<T> eventStream<T>(String event) {
    if (!_eventControllers.containsKey(event)) {
      _eventControllers[event] = StreamController<dynamic>.broadcast();

      // Register listener
      on(event, (data) {
        if (_eventControllers[event]?.isClosed == false) {
          _eventControllers[event]!.add(data);
        }
      });
    }

    return _eventControllers[event]!.stream.cast<T>();
  }

  // ============================================================================
  // ROOM MANAGEMENT
  // ============================================================================

  /// Join a room
  void joinRoom(String room) {
    emit(SocketEvents.joinRoom, {'room': room});
  }

  /// Leave a room
  void leaveRoom(String room) {
    emit(SocketEvents.leaveRoom, {'room': room});
  }

  /// Join a conversation room
  void joinConversation(String conversationId) {
    emit(SocketEvents.joinConversation, {'conversationId': conversationId});
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    emit(SocketEvents.leaveConversation, {'conversationId': conversationId});
  }

  // ============================================================================
  // CHAT METHODS
  // ============================================================================

  /// Send a chat message
  void sendMessage({
    required String conversationId,
    required String content,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    emit(SocketEvents.sendMessage, {
      'conversationId': conversationId,
      'content': content,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentType != null) 'attachmentType': attachmentType,
    });
  }

  /// Emit typing event
  void startTyping(String conversationId) {
    emit(SocketEvents.typing, {'conversationId': conversationId});
  }

  /// Emit stop typing event
  void stopTyping(String conversationId) {
    emit(SocketEvents.stopTyping, {'conversationId': conversationId});
  }

  /// Mark messages as read
  void markMessagesRead(String conversationId) {
    emit(SocketEvents.messagesRead, {'conversationId': conversationId});
  }

  // ============================================================================
  // LOCATION METHODS
  // ============================================================================

  /// Subscribe to location updates for a specific area or user
  void subscribeToLocations({
    double? latitude,
    double? longitude,
    double? radius,
    String? userId,
  }) {
    emit(SocketEvents.subscribeLocations, {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radius != null) 'radius': radius,
      if (userId != null) 'userId': userId,
    });
  }

  /// Unsubscribe from location updates
  void unsubscribeFromLocations() {
    emit(SocketEvents.unsubscribeLocations);
  }

  /// Send location update
  void updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) {
    emit(SocketEvents.updateLocation, {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Request nearby users
  void requestNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
  }) {
    emit(SocketEvents.requestNearbyUsers, {
      'latitude': latitude,
      'longitude': longitude,
      if (radius != null) 'radius': radius,
    });
  }

  // ============================================================================
  // INCIDENT METHODS
  // ============================================================================

  /// Subscribe to incident updates
  void subscribeToIncident(String incidentId) {
    emit(SocketEvents.subscribeIncident, {'incidentId': incidentId});
  }

  /// Unsubscribe from incident updates
  void unsubscribeFromIncident(String incidentId) {
    emit(SocketEvents.unsubscribeIncident, {'incidentId': incidentId});
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  /// Update connection state and notify listeners
  void _updateConnectionState(SocketConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(newState);
      }
    }
  }

  /// Log message in debug mode
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SocketService] $message');
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose all resources
  void dispose() {
    disconnect();

    _connectionStateController.close();

    for (final controller in _eventControllers.values) {
      controller.close();
    }
    _eventControllers.clear();

    _pendingListeners.clear();
  }
}
