/// App string keys for RiderApp.
///
/// Contains string keys used throughout the app.
/// Actual localized strings should be in i18n files (e.g., intl_en.arb, intl_th.arb).
/// This class provides type-safe keys to prevent typos and enable IDE autocomplete.
abstract final class AppStrings {
  // ============================================================================
  // APP GENERAL
  // ============================================================================

  /// App name
  static const String appName = 'RiderApp';

  /// App tagline
  static const String appTagline = 'app_tagline';

  /// App version key
  static const String appVersion = 'app_version';

  // ============================================================================
  // COMMON LABELS
  // ============================================================================

  static const String ok = 'ok';
  static const String cancel = 'cancel';
  static const String confirm = 'confirm';
  static const String save = 'save';
  static const String delete = 'delete';
  static const String edit = 'edit';
  static const String add = 'add';
  static const String remove = 'remove';
  static const String close = 'close';
  static const String back = 'back';
  static const String next = 'next';
  static const String previous = 'previous';
  static const String done = 'done';
  static const String submit = 'submit';
  static const String send = 'send';
  static const String retry = 'retry';
  static const String refresh = 'refresh';
  static const String search = 'search';
  static const String filter = 'filter';
  static const String sort = 'sort';
  static const String share = 'share';
  static const String copy = 'copy';
  static const String paste = 'paste';
  static const String clear = 'clear';
  static const String reset = 'reset';
  static const String apply = 'apply';
  static const String select = 'select';
  static const String selectAll = 'select_all';
  static const String deselectAll = 'deselect_all';
  static const String more = 'more';
  static const String less = 'less';
  static const String showMore = 'show_more';
  static const String showLess = 'show_less';
  static const String viewAll = 'view_all';
  static const String seeAll = 'see_all';
  static const String loading = 'loading';
  static const String pleaseWait = 'please_wait';
  static const String yes = 'yes';
  static const String no = 'no';
  static const String enable = 'enable';
  static const String disable = 'disable';
  static const String enabled = 'enabled';
  static const String disabled = 'disabled';
  static const String on = 'on';
  static const String off = 'off';
  static const String unknown = 'unknown';
  static const String notAvailable = 'not_available';
  static const String optional = 'optional';
  static const String required = 'required';

  // ============================================================================
  // NAVIGATION
  // ============================================================================

  static const String navHome = 'nav_home';
  static const String navIncidents = 'nav_incidents';
  static const String navChat = 'nav_chat';
  static const String navProfile = 'nav_profile';
  static const String navSettings = 'nav_settings';
  static const String navNotifications = 'nav_notifications';
  static const String navEmergency = 'nav_emergency';
  static const String navAnnouncements = 'nav_announcements';

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  static const String login = 'login';
  static const String logout = 'logout';
  static const String register = 'register';
  static const String signIn = 'sign_in';
  static const String signUp = 'sign_up';
  static const String signOut = 'sign_out';
  static const String createAccount = 'create_account';
  static const String forgotPassword = 'forgot_password';
  static const String resetPassword = 'reset_password';
  static const String changePassword = 'change_password';
  static const String email = 'email';
  static const String password = 'password';
  static const String confirmPassword = 'confirm_password';
  static const String currentPassword = 'current_password';
  static const String newPassword = 'new_password';
  static const String phone = 'phone';
  static const String phoneNumber = 'phone_number';
  static const String verifyEmail = 'verify_email';
  static const String verifyPhone = 'verify_phone';
  static const String enterOtp = 'enter_otp';
  static const String resendOtp = 'resend_otp';
  static const String otpSent = 'otp_sent';
  static const String otpExpired = 'otp_expired';
  static const String rememberMe = 'remember_me';
  static const String keepMeLoggedIn = 'keep_me_logged_in';
  static const String orContinueWith = 'or_continue_with';
  static const String continueWithGoogle = 'continue_with_google';
  static const String continueWithApple = 'continue_with_apple';
  static const String alreadyHaveAccount = 'already_have_account';
  static const String dontHaveAccount = 'dont_have_account';
  static const String agreeToTerms = 'agree_to_terms';
  static const String termsOfService = 'terms_of_service';
  static const String privacyPolicy = 'privacy_policy';
  static const String and = 'and';

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  static const String profile = 'profile';
  static const String editProfile = 'edit_profile';
  static const String firstName = 'first_name';
  static const String lastName = 'last_name';
  static const String fullName = 'full_name';
  static const String displayName = 'display_name';
  static const String dateOfBirth = 'date_of_birth';
  static const String gender = 'gender';
  static const String male = 'male';
  static const String female = 'female';
  static const String other = 'other';
  static const String preferNotToSay = 'prefer_not_to_say';
  static const String address = 'address';
  static const String city = 'city';
  static const String province = 'province';
  static const String postalCode = 'postal_code';
  static const String country = 'country';
  static const String idCardNumber = 'id_card_number';
  static const String drivingLicense = 'driving_license';
  static const String vehicleRegistration = 'vehicle_registration';
  static const String profilePicture = 'profile_picture';
  static const String changePhoto = 'change_photo';
  static const String removePhoto = 'remove_photo';
  static const String takePhoto = 'take_photo';
  static const String chooseFromGallery = 'choose_from_gallery';
  static const String accountSettings = 'account_settings';
  static const String deleteAccount = 'delete_account';
  static const String deleteAccountWarning = 'delete_account_warning';

  // ============================================================================
  // INCIDENTS
  // ============================================================================

  static const String incidents = 'incidents';
  static const String incident = 'incident';
  static const String reportIncident = 'report_incident';
  static const String newIncident = 'new_incident';
  static const String myIncidents = 'my_incidents';
  static const String incidentDetails = 'incident_details';
  static const String incidentHistory = 'incident_history';
  static const String incidentType = 'incident_type';
  static const String incidentCategory = 'incident_category';
  static const String incidentDescription = 'incident_description';
  static const String incidentLocation = 'incident_location';
  static const String incidentDate = 'incident_date';
  static const String incidentTime = 'incident_time';
  static const String incidentPhotos = 'incident_photos';
  static const String incidentVideos = 'incident_videos';
  static const String addPhotos = 'add_photos';
  static const String addVideos = 'add_videos';
  static const String incidentStatus = 'incident_status';
  static const String nearbyIncidents = 'nearby_incidents';

  // Incident categories
  static const String categoryAccident = 'category_accident';
  static const String categoryTheft = 'category_theft';
  static const String categoryHarassment = 'category_harassment';
  static const String categoryTrafficViolation = 'category_traffic_violation';
  static const String categoryVehicleDamage = 'category_vehicle_damage';
  static const String categorySuspiciousActivity = 'category_suspicious_activity';
  static const String categoryEmergency = 'category_emergency';
  static const String categoryOther = 'category_other';

  // Incident statuses
  static const String statusPending = 'status_pending';
  static const String statusInProgress = 'status_in_progress';
  static const String statusInvestigating = 'status_investigating';
  static const String statusResolved = 'status_resolved';
  static const String statusClosed = 'status_closed';
  static const String statusRejected = 'status_rejected';

  // ============================================================================
  // CHAT
  // ============================================================================

  static const String chat = 'chat';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String newMessage = 'new_message';
  static const String typeMessage = 'type_message';
  static const String noMessages = 'no_messages';
  static const String noConversations = 'no_conversations';
  static const String startConversation = 'start_conversation';
  static const String chatWithOfficer = 'chat_with_officer';
  static const String attachment = 'attachment';
  static const String sendPhoto = 'send_photo';
  static const String sendDocument = 'send_document';
  static const String sendLocation = 'send_location';
  static const String messageDelivered = 'message_delivered';
  static const String messageRead = 'message_read';
  static const String messageSent = 'message_sent';
  static const String online = 'online';
  static const String offline = 'offline';
  static const String lastSeen = 'last_seen';
  static const String typing = 'typing';

  // ============================================================================
  // EMERGENCY
  // ============================================================================

  static const String emergency = 'emergency';
  static const String sos = 'sos';
  static const String sosAlert = 'sos_alert';
  static const String triggerSos = 'trigger_sos';
  static const String cancelSos = 'cancel_sos';
  static const String sosActivated = 'sos_activated';
  static const String sosCancelled = 'sos_cancelled';
  static const String sosConfirmation = 'sos_confirmation';
  static const String emergencyContacts = 'emergency_contacts';
  static const String addEmergencyContact = 'add_emergency_contact';
  static const String policeStations = 'police_stations';
  static const String nearbyPoliceStations = 'nearby_police_stations';
  static const String callPolice = 'call_police';
  static const String emergencyHotlines = 'emergency_hotlines';
  static const String shareLocation = 'share_location';
  static const String shareLiveLocation = 'share_live_location';
  static const String stopSharingLocation = 'stop_sharing_location';

  // ============================================================================
  // ANNOUNCEMENTS
  // ============================================================================

  static const String announcements = 'announcements';
  static const String announcement = 'announcement';
  static const String noAnnouncements = 'no_announcements';
  static const String readMore = 'read_more';
  static const String postedOn = 'posted_on';
  static const String postedBy = 'posted_by';

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  static const String notifications = 'notifications';
  static const String noNotifications = 'no_notifications';
  static const String markAsRead = 'mark_as_read';
  static const String markAllAsRead = 'mark_all_as_read';
  static const String clearAll = 'clear_all';
  static const String notificationSettings = 'notification_settings';
  static const String pushNotifications = 'push_notifications';
  static const String emailNotifications = 'email_notifications';
  static const String smsNotifications = 'sms_notifications';

  // ============================================================================
  // SETTINGS
  // ============================================================================

  static const String settings = 'settings';
  static const String generalSettings = 'general_settings';
  static const String language = 'language';
  static const String theme = 'theme';
  static const String darkMode = 'dark_mode';
  static const String lightMode = 'light_mode';
  static const String systemDefault = 'system_default';
  static const String about = 'about';
  static const String aboutApp = 'about_app';
  static const String version = 'version';
  static const String buildNumber = 'build_number';
  static const String helpAndSupport = 'help_and_support';
  static const String faq = 'faq';
  static const String contactUs = 'contact_us';
  static const String reportBug = 'report_bug';
  static const String suggestFeature = 'suggest_feature';
  static const String rateApp = 'rate_app';
  static const String shareApp = 'share_app';
  static const String licenses = 'licenses';

  // ============================================================================
  // LOCATION
  // ============================================================================

  static const String location = 'location';
  static const String currentLocation = 'current_location';
  static const String selectLocation = 'select_location';
  static const String chooseOnMap = 'choose_on_map';
  static const String useCurrentLocation = 'use_current_location';
  static const String searchLocation = 'search_location';
  static const String locationPermission = 'location_permission';
  static const String locationPermissionDenied = 'location_permission_denied';
  static const String enableLocationServices = 'enable_location_services';

  // ============================================================================
  // MEDIA
  // ============================================================================

  static const String camera = 'camera';
  static const String gallery = 'gallery';
  static const String photos = 'photos';
  static const String videos = 'videos';
  static const String documents = 'documents';
  static const String cameraPermission = 'camera_permission';
  static const String galleryPermission = 'gallery_permission';
  static const String microphonePermission = 'microphone_permission';

  // ============================================================================
  // ERRORS
  // ============================================================================

  static const String error = 'error';
  static const String errorOccurred = 'error_occurred';
  static const String somethingWentWrong = 'something_went_wrong';
  static const String networkError = 'network_error';
  static const String noInternetConnection = 'no_internet_connection';
  static const String connectionTimeout = 'connection_timeout';
  static const String serverError = 'server_error';
  static const String sessionExpired = 'session_expired';
  static const String unauthorized = 'unauthorized';
  static const String forbidden = 'forbidden';
  static const String notFound = 'not_found';
  static const String badRequest = 'bad_request';
  static const String tooManyRequests = 'too_many_requests';
  static const String serviceUnavailable = 'service_unavailable';

  // ============================================================================
  // VALIDATION MESSAGES
  // ============================================================================

  static const String fieldRequired = 'field_required';
  static const String invalidEmail = 'invalid_email';
  static const String invalidPhone = 'invalid_phone';
  static const String invalidIdCard = 'invalid_id_card';
  static const String passwordTooShort = 'password_too_short';
  static const String passwordTooWeak = 'password_too_weak';
  static const String passwordsDoNotMatch = 'passwords_do_not_match';
  static const String invalidCredentials = 'invalid_credentials';
  static const String emailAlreadyInUse = 'email_already_in_use';
  static const String phoneAlreadyInUse = 'phone_already_in_use';
  static const String userNotFound = 'user_not_found';
  static const String wrongPassword = 'wrong_password';

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================

  static const String success = 'success';
  static const String saved = 'saved';
  static const String updated = 'updated';
  static const String deleted = 'deleted';
  static const String submitted = 'submitted';
  static const String sent = 'sent';
  static const String copied = 'copied';
  static const String profileUpdated = 'profile_updated';
  static const String passwordChanged = 'password_changed';
  static const String incidentReported = 'incident_reported';
  static const String incidentUpdated = 'incident_updated';
  static const String logoutSuccess = 'logout_success';

  // ============================================================================
  // CONFIRMATION DIALOGS
  // ============================================================================

  static const String confirmLogout = 'confirm_logout';
  static const String confirmDelete = 'confirm_delete';
  static const String confirmDiscard = 'confirm_discard';
  static const String discardChanges = 'discard_changes';
  static const String unsavedChanges = 'unsaved_changes';
  static const String areYouSure = 'are_you_sure';
  static const String cannotBeUndone = 'cannot_be_undone';

  // ============================================================================
  // EMPTY STATES
  // ============================================================================

  static const String noData = 'no_data';
  static const String noResults = 'no_results';
  static const String noIncidents = 'no_incidents';
  static const String noIncidentsYet = 'no_incidents_yet';
  static const String emptyInbox = 'empty_inbox';
  static const String nothingHere = 'nothing_here';

  // ============================================================================
  // TIME & DATE
  // ============================================================================

  static const String today = 'today';
  static const String yesterday = 'yesterday';
  static const String tomorrow = 'tomorrow';
  static const String now = 'now';
  static const String justNow = 'just_now';
  static const String minutesAgo = 'minutes_ago';
  static const String hoursAgo = 'hours_ago';
  static const String daysAgo = 'days_ago';
  static const String weeksAgo = 'weeks_ago';
  static const String monthsAgo = 'months_ago';
  static const String yearsAgo = 'years_ago';

  // ============================================================================
  // MISC
  // ============================================================================

  static const String welcomeBack = 'welcome_back';
  static const String welcome = 'welcome';
  static const String hello = 'hello';
  static const String hi = 'hi';
  static const String goodMorning = 'good_morning';
  static const String goodAfternoon = 'good_afternoon';
  static const String goodEvening = 'good_evening';
  static const String getStarted = 'get_started';
  static const String continueText = 'continue';
  static const String skip = 'skip';
  static const String finish = 'finish';
  static const String learnMore = 'learn_more';
}
