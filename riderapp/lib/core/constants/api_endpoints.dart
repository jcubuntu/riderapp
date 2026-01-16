/// API endpoint constants for RiderApp.
///
/// Contains all API endpoints organized by feature modules.
/// Uses a base URL that should be configured based on environment.
abstract final class ApiEndpoints {
  // ============================================================================
  // BASE URL CONFIGURATION
  // ============================================================================

  /// Base URL for development environment
  static const String devBaseUrl = 'http://localhost:4000/api/v1';

  /// Base URL for staging environment
  static const String stagingBaseUrl = 'https://dev-rider.makerrobotics.co.th/api/v1';

  /// Base URL for production environment
  static const String prodBaseUrl = 'https://api.riderapp.com/api/v1';

  /// Current base URL - should be set based on environment
  /// This can be overridden at runtime using environment configuration
  static String baseUrl = devBaseUrl;

  /// API version
  static const String apiVersion = 'v1';

  /// WebSocket base URL for real-time features
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws');

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================

  static const String _authPrefix = '/auth';

  /// POST - Login with email/phone and password
  static const String login = '$_authPrefix/login';

  /// POST - Register new user account
  static const String register = '$_authPrefix/register';

  /// POST - Logout current user
  static const String logout = '$_authPrefix/logout';

  /// POST - Refresh access token
  static const String refreshToken = '$_authPrefix/refresh';

  /// GET - Check approval status (by userId)
  static const String checkStatus = '$_authPrefix/status';

  /// GET - Get current authenticated user
  static const String me = '$_authPrefix/me';

  /// GET - Check authenticated user's approval status
  static const String approvalStatus = '$_authPrefix/approval-status';

  /// POST - Request password reset
  static const String forgotPassword = '$_authPrefix/forgot-password';

  /// POST - Reset password with token
  static const String resetPassword = '$_authPrefix/reset-password';

  /// POST - Verify email with OTP
  static const String verifyEmail = '$_authPrefix/verify-email';

  /// POST - Verify phone with OTP
  static const String verifyPhone = '$_authPrefix/verify-phone';

  /// POST - Resend verification OTP
  static const String resendOtp = '$_authPrefix/resend-otp';

  /// POST - Change password (authenticated)
  static const String changePassword = '$_authPrefix/change-password';

  /// GET - Get current user session info
  static const String session = '$_authPrefix/session';

  /// POST - Login with social provider (Google, Apple, etc.)
  static const String socialLogin = '$_authPrefix/social-login';

  // ============================================================================
  // USER ENDPOINTS
  // ============================================================================

  static const String _usersPrefix = '/users';

  /// GET - Get current user profile
  static const String profile = '$_usersPrefix/me';

  /// PATCH - Update current user profile
  static const String updateProfile = '$_usersPrefix/me';

  /// DELETE - Delete current user account
  static const String deleteAccount = '$_usersPrefix/me';

  /// POST - Upload profile picture
  static const String uploadProfilePicture = '$_usersPrefix/me/picture';

  /// DELETE - Remove profile picture
  static const String deleteProfilePicture = '$_usersPrefix/me/picture';

  /// GET - Get user by ID
  static String getUserById(String userId) => '$_usersPrefix/$userId';

  /// GET - Get user's notification preferences
  static const String notificationPreferences = '$_usersPrefix/me/notifications';

  /// PATCH - Update notification preferences
  static const String updateNotificationPreferences = '$_usersPrefix/me/notifications';

  /// POST - Update FCM token for push notifications
  static const String updateFcmToken = '$_usersPrefix/me/fcm-token';

  /// GET - Get user's devices
  static const String devices = '$_usersPrefix/me/devices';

  /// DELETE - Remove a device
  static String removeDevice(String deviceId) => '$_usersPrefix/me/devices/$deviceId';

  // ============================================================================
  // INCIDENT ENDPOINTS
  // ============================================================================

  static const String _incidentsPrefix = '/incidents';

  /// GET - Get list of incidents (with pagination/filters)
  static const String incidents = _incidentsPrefix;

  /// POST - Create new incident report
  static const String createIncident = _incidentsPrefix;

  /// GET - Get incident by ID
  static String getIncident(String incidentId) => '$_incidentsPrefix/$incidentId';

  /// PATCH - Update incident
  static String updateIncident(String incidentId) => '$_incidentsPrefix/$incidentId';

  /// DELETE - Delete incident (soft delete)
  static String deleteIncident(String incidentId) => '$_incidentsPrefix/$incidentId';

  /// GET - Get user's own incidents
  static const String myIncidents = '$_incidentsPrefix/me';

  /// GET - Get incidents near location
  static const String nearbyIncidents = '$_incidentsPrefix/nearby';

  /// POST - Upload incident media (images, videos)
  static String uploadIncidentMedia(String incidentId) =>
      '$_incidentsPrefix/$incidentId/media';

  /// DELETE - Remove incident media
  static String deleteIncidentMedia(String incidentId, String mediaId) =>
      '$_incidentsPrefix/$incidentId/media/$mediaId';

  /// POST - Add comment/update to incident
  static String addIncidentComment(String incidentId) =>
      '$_incidentsPrefix/$incidentId/comments';

  /// GET - Get incident comments/timeline
  static String getIncidentComments(String incidentId) =>
      '$_incidentsPrefix/$incidentId/comments';

  /// GET - Get incident categories
  static const String incidentCategories = '$_incidentsPrefix/categories';

  /// GET - Get incident statistics (for dashboard)
  static const String incidentStats = '$_incidentsPrefix/stats';

  /// PATCH - Update incident status (for officers)
  static String updateIncidentStatus(String incidentId) =>
      '$_incidentsPrefix/$incidentId/status';

  /// POST - Assign incident to officer
  static String assignIncident(String incidentId) =>
      '$_incidentsPrefix/$incidentId/assign';

  // ============================================================================
  // CHAT ENDPOINTS
  // ============================================================================

  static const String _chatPrefix = '/chat';

  /// GET - Get list of chat conversations
  static const String conversations = '$_chatPrefix/conversations';

  /// POST - Create new conversation
  static const String createConversation = '$_chatPrefix/conversations';

  /// GET - Get conversation by ID
  static String getConversation(String conversationId) =>
      '$_chatPrefix/conversations/$conversationId';

  /// GET - Get messages in conversation
  static String getMessages(String conversationId) =>
      '$_chatPrefix/conversations/$conversationId/messages';

  /// POST - Send message in conversation
  static String sendMessage(String conversationId) =>
      '$_chatPrefix/conversations/$conversationId/messages';

  /// PATCH - Mark messages as read
  static String markAsRead(String conversationId) =>
      '$_chatPrefix/conversations/$conversationId/read';

  /// POST - Upload chat attachment
  static String uploadChatAttachment(String conversationId) =>
      '$_chatPrefix/conversations/$conversationId/attachments';

  /// GET - Get chat with incident
  static String getIncidentChat(String incidentId) =>
      '$_chatPrefix/incidents/$incidentId';

  /// DELETE - Delete conversation (for user)
  static String deleteConversation(String conversationId) =>
      '$_chatPrefix/conversations/$conversationId';

  /// GET - Get unread message count
  static const String unreadCount = '$_chatPrefix/unread-count';

  /// GET - Get role-based chat groups
  static const String chatGroups = '$_chatPrefix/groups';

  /// POST - Join a role-based chat group
  static String joinChatGroup(String groupId) => '$_chatPrefix/groups/$groupId/join';

  /// POST - Auto-join all accessible chat groups
  static const String autoJoinChatGroups = '$_chatPrefix/groups/auto-join';

  // ============================================================================
  // ANNOUNCEMENT ENDPOINTS
  // ============================================================================

  static const String _announcementsPrefix = '/announcements';

  /// GET - Get list of announcements
  static const String announcements = _announcementsPrefix;

  /// GET - Get announcement by ID
  static String getAnnouncement(String announcementId) =>
      '$_announcementsPrefix/$announcementId';

  /// POST - Create announcement (admin only)
  static const String createAnnouncement = _announcementsPrefix;

  /// PATCH - Update announcement (admin only)
  static String updateAnnouncement(String announcementId) =>
      '$_announcementsPrefix/$announcementId';

  /// DELETE - Delete announcement (admin only)
  static String deleteAnnouncement(String announcementId) =>
      '$_announcementsPrefix/$announcementId';

  /// PATCH - Mark announcement as read
  static String markAnnouncementRead(String announcementId) =>
      '$_announcementsPrefix/$announcementId/read';

  /// GET - Get unread announcements count
  static const String unreadAnnouncementsCount = '$_announcementsPrefix/unread-count';

  // ============================================================================
  // EMERGENCY ENDPOINTS
  // ============================================================================

  static const String _emergencyPrefix = '/emergency';

  /// POST - Trigger SOS emergency alert
  static const String triggerSos = '$_emergencyPrefix/sos';

  /// POST - Cancel SOS emergency
  static const String cancelSos = '$_emergencyPrefix/sos/cancel';

  /// GET - Get SOS status
  static const String sosStatus = '$_emergencyPrefix/sos/status';

  /// GET - Get emergency contacts
  static const String emergencyContacts = '$_emergencyPrefix/contacts';

  /// POST - Add emergency contact
  static const String addEmergencyContact = '$_emergencyPrefix/contacts';

  /// DELETE - Remove emergency contact
  static String removeEmergencyContact(String contactId) =>
      '$_emergencyPrefix/contacts/$contactId';

  /// GET - Get nearby police stations
  static const String nearbyPoliceStations = '$_emergencyPrefix/police-stations';

  /// GET - Get emergency hotlines
  static const String emergencyHotlines = '$_emergencyPrefix/hotlines';

  /// POST - Share live location
  static const String shareLiveLocation = '$_emergencyPrefix/share-location';

  /// DELETE - Stop sharing live location
  static const String stopShareLocation = '$_emergencyPrefix/share-location';

  // ============================================================================
  // LOCATION ENDPOINTS
  // ============================================================================

  static const String _locationPrefix = '/location';

  /// POST - Update user location
  static const String updateLocation = '$_locationPrefix/update';

  /// GET - Get location history
  static const String locationHistory = '$_locationPrefix/history';

  /// GET - Reverse geocode coordinates
  static const String reverseGeocode = '$_locationPrefix/reverse-geocode';

  /// GET - Search places
  static const String searchPlaces = '$_locationPrefix/search';

  // ============================================================================
  // NOTIFICATION ENDPOINTS
  // ============================================================================

  static const String _notificationsPrefix = '/notifications';

  /// GET - Get list of notifications
  static const String notifications = _notificationsPrefix;

  /// PATCH - Mark notification as read
  static String markNotificationRead(String notificationId) =>
      '$_notificationsPrefix/$notificationId/read';

  /// PATCH - Mark all notifications as read
  static const String markAllNotificationsRead = '$_notificationsPrefix/read-all';

  /// DELETE - Delete notification
  static String deleteNotification(String notificationId) =>
      '$_notificationsPrefix/$notificationId';

  /// DELETE - Clear all notifications
  static const String clearAllNotifications = _notificationsPrefix;

  // ============================================================================
  // SETTINGS ENDPOINTS
  // ============================================================================

  static const String _settingsPrefix = '/settings';

  /// GET - Get app settings
  static const String appSettings = '$_settingsPrefix/app';

  /// GET - Get feature flags
  static const String featureFlags = '$_settingsPrefix/features';

  /// GET - Get terms of service
  static const String termsOfService = '$_settingsPrefix/terms';

  /// GET - Get privacy policy
  static const String privacyPolicy = '$_settingsPrefix/privacy';

  /// GET - Check for app updates
  static const String appVersion = '$_settingsPrefix/version';

  // ============================================================================
  // FILE UPLOAD ENDPOINTS
  // ============================================================================

  static const String _uploadPrefix = '/upload';

  /// POST - Upload file
  static const String uploadFile = _uploadPrefix;

  /// POST - Upload multiple files
  static const String uploadMultipleFiles = '$_uploadPrefix/multiple';

  /// GET - Get signed URL for direct upload
  static const String getSignedUploadUrl = '$_uploadPrefix/signed-url';

  /// DELETE - Delete uploaded file
  static String deleteFile(String fileId) => '$_uploadPrefix/$fileId';

  /// POST - Upload image file
  static const String uploadImage = '$_uploadPrefix/image';

  /// POST - Upload profile picture
  static const String uploadProfile = '$_uploadPrefix/profile';

  /// GET - Get file by filename
  static String getFileByName(String filename) => '$_uploadPrefix/$filename';

  // ============================================================================
  // AFFILIATIONS ENDPOINTS
  // ============================================================================

  static const String _affiliationsPrefix = '/affiliations';

  /// GET - Get list of active affiliations (public)
  static const String affiliations = _affiliationsPrefix;

  /// GET - Get all affiliations including inactive (admin)
  static const String affiliationsAdmin = '$_affiliationsPrefix/admin';

  /// GET - Get affiliation by ID
  static String getAffiliation(String affiliationId) =>
      '$_affiliationsPrefix/$affiliationId';

  /// POST - Create affiliation (admin only)
  static const String createAffiliation = _affiliationsPrefix;

  /// PUT - Update affiliation (admin only)
  static String updateAffiliation(String affiliationId) =>
      '$_affiliationsPrefix/$affiliationId';

  /// DELETE - Delete affiliation (admin only)
  static String deleteAffiliation(String affiliationId) =>
      '$_affiliationsPrefix/$affiliationId';

  /// POST - Restore deleted affiliation (admin only)
  static String restoreAffiliation(String affiliationId) =>
      '$_affiliationsPrefix/$affiliationId/restore';

  // ============================================================================
  // STATISTICS ENDPOINTS
  // ============================================================================

  static const String _statsPrefix = '/stats';

  /// GET - Dashboard overview (volunteer+)
  static const String statsDashboard = '$_statsPrefix/dashboard';

  /// GET - Incident summary statistics (volunteer+)
  static const String incidentsSummary = '$_statsPrefix/incidents/summary';

  /// GET - Incidents by type (volunteer+)
  static const String incidentsByType = '$_statsPrefix/incidents/by-type';

  /// GET - Incidents by status (volunteer+)
  static const String incidentsByStatus = '$_statsPrefix/incidents/by-status';

  /// GET - Incidents by priority (volunteer+)
  static const String incidentsByPriority = '$_statsPrefix/incidents/by-priority';

  /// GET - Incident trend over time (volunteer+)
  static const String incidentsTrend = '$_statsPrefix/incidents/trend';

  /// GET - Incidents by province (volunteer+)
  static const String incidentsByProvince = '$_statsPrefix/incidents/by-province';

  /// GET - User summary (admin+)
  static const String usersSummary = '$_statsPrefix/users/summary';

  /// GET - Users by role (admin+)
  static const String usersByRole = '$_statsPrefix/users/by-role';

  /// GET - Users by status (admin+)
  static const String usersByStatus = '$_statsPrefix/users/by-status';

  /// GET - User registration trend (admin+)
  static const String usersTrend = '$_statsPrefix/users/trend';

  // ============================================================================
  // REPORT/FEEDBACK ENDPOINTS
  // ============================================================================

  static const String _feedbackPrefix = '/feedback';

  /// POST - Submit feedback
  static const String submitFeedback = _feedbackPrefix;

  /// POST - Report a bug
  static const String reportBug = '$_feedbackPrefix/bug';

  /// POST - Suggest a feature
  static const String suggestFeature = '$_feedbackPrefix/feature';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Build full URL from endpoint
  static String buildUrl(String endpoint) => '$baseUrl$endpoint';

  /// Build URL with query parameters
  static String buildUrlWithParams(
    String endpoint,
    Map<String, dynamic> params,
  ) {
    final uri = Uri.parse('$baseUrl$endpoint');
    final queryParams = params.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Build paginated URL
  static String buildPaginatedUrl(
    String endpoint, {
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? additionalParams,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      ...?additionalParams,
    };
    return buildUrlWithParams(endpoint, params);
  }
}
