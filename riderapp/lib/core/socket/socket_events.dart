/// Socket.io event constants for RiderApp.
///
/// Contains all socket event names organized by feature.
/// These should match the server-side event names exactly.
abstract final class SocketEvents {
  // ============================================================================
  // CONNECTION EVENTS
  // ============================================================================

  /// Client connected to server
  static const String connect = 'connect';

  /// Client disconnected from server
  static const String disconnect = 'disconnect';

  /// Connection error occurred
  static const String connectError = 'connect_error';

  /// Reconnection attempt
  static const String reconnect = 'reconnect';

  /// Reconnection attempt
  static const String reconnectAttempt = 'reconnect_attempt';

  /// Reconnection error
  static const String reconnectError = 'reconnect_error';

  /// Reconnection failed after all attempts
  static const String reconnectFailed = 'reconnect_failed';

  /// Generic error
  static const String error = 'error';

  // ============================================================================
  // AUTHENTICATION EVENTS
  // ============================================================================

  /// Authenticate with token
  static const String authenticate = 'authenticate';

  /// Authentication successful
  static const String authenticated = 'authenticated';

  /// Authentication failed
  static const String authError = 'auth_error';

  /// User joined (broadcast to others)
  static const String userJoined = 'user:joined';

  /// User left (broadcast to others)
  static const String userLeft = 'user:left';

  // ============================================================================
  // CHAT EVENTS
  // ============================================================================

  /// Join a conversation room
  static const String joinConversation = 'conversation:join';

  /// Leave a conversation room
  static const String leaveConversation = 'conversation:leave';

  /// Send a new message
  static const String sendMessage = 'message:new';

  /// New message received
  static const String newMessage = 'message:new';

  /// User is typing in a conversation
  static const String typing = 'typing:start';

  /// User stopped typing
  static const String stopTyping = 'typing:stop';

  /// Someone is typing (received)
  static const String userTyping = 'typing:start';

  /// Someone stopped typing (received)
  static const String userStoppedTyping = 'typing:stop';

  /// Messages have been read
  static const String messagesRead = 'messages:read';

  /// Message read receipt received
  static const String messageReadReceipt = 'message:read';

  /// Conversation updated (new message, etc.)
  static const String conversationUpdated = 'chat:conversation_updated';

  /// New conversation created
  static const String newConversation = 'chat:new_conversation';

  // ============================================================================
  // LOCATION EVENTS
  // ============================================================================

  /// Subscribe to location updates
  static const String subscribeLocations = 'location:subscribe';

  /// Unsubscribe from location updates
  static const String unsubscribeLocations = 'location:unsubscribe';

  /// Send location update
  static const String updateLocation = 'location:update';

  /// Location update received from another user
  static const String locationUpdated = 'location:updated';

  /// User started sharing location
  static const String locationSharingStarted = 'location:sharing_started';

  /// User stopped sharing location
  static const String locationSharingStopped = 'location:sharing_stopped';

  /// Request nearby users
  static const String requestNearbyUsers = 'location:nearby';

  /// Nearby users response
  static const String nearbyUsers = 'location:nearby_users';

  // ============================================================================
  // NOTIFICATION EVENTS
  // ============================================================================

  /// New notification received
  static const String newNotification = 'notification:new';

  /// Notification read
  static const String notificationRead = 'notification:read';

  /// All notifications read
  static const String allNotificationsRead = 'notification:all_read';

  /// Notification badge count update
  static const String badgeCountUpdate = 'notification:badge_count';

  // ============================================================================
  // INCIDENT EVENTS
  // ============================================================================

  /// New incident reported
  static const String newIncident = 'incident:new';

  /// Incident updated
  static const String incidentUpdated = 'incident:updated';

  /// Incident status changed
  static const String incidentStatusChanged = 'incident:status_changed';

  /// Incident assigned to user
  static const String incidentAssigned = 'incident:assigned';

  /// Subscribe to incident updates
  static const String subscribeIncident = 'incident:subscribe';

  /// Unsubscribe from incident updates
  static const String unsubscribeIncident = 'incident:unsubscribe';

  // ============================================================================
  // EMERGENCY EVENTS
  // ============================================================================

  /// SOS triggered
  static const String sosTriggered = 'emergency:sos';

  /// SOS cancelled
  static const String sosCancelled = 'emergency:sos_cancelled';

  /// SOS response received
  static const String sosResponse = 'emergency:sos_response';

  /// Emergency alert (broadcast to nearby users)
  static const String emergencyAlert = 'emergency:alert';

  // ============================================================================
  // ANNOUNCEMENT EVENTS
  // ============================================================================

  /// New announcement
  static const String newAnnouncement = 'announcement:new';

  /// Announcement updated
  static const String announcementUpdated = 'announcement:updated';

  // ============================================================================
  // PRESENCE EVENTS
  // ============================================================================

  /// User online
  static const String userOnline = 'presence:online';

  /// User offline
  static const String userOffline = 'presence:offline';

  /// Request online users
  static const String requestOnlineUsers = 'presence:request';

  /// Online users response
  static const String onlineUsers = 'presence:online_users';

  // ============================================================================
  // ROOM EVENTS
  // ============================================================================

  /// Join a room
  static const String joinRoom = 'room:join';

  /// Leave a room
  static const String leaveRoom = 'room:leave';

  /// Room joined confirmation
  static const String roomJoined = 'room:joined';

  /// Room left confirmation
  static const String roomLeft = 'room:left';
}
