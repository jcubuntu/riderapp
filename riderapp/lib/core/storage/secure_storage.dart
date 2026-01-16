import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for sensitive data.
///
/// Uses flutter_secure_storage to securely store:
/// - Authentication tokens
/// - User data
/// - Other sensitive information
///
/// Data is encrypted using platform-specific encryption:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences / Keystore
class SecureStorage {
  /// Private constructor
  SecureStorage._internal();

  /// Singleton instance
  static final SecureStorage _instance = SecureStorage._internal();

  /// Factory constructor returns singleton
  factory SecureStorage() => _instance;

  /// Flutter secure storage instance with configuration
  late final FlutterSecureStorage _storage;

  /// Whether storage has been initialized
  bool _isInitialized = false;

  // ============================================================================
  // STORAGE KEYS
  // ============================================================================

  /// Key for access token
  static const String _keyAccessToken = 'access_token';

  /// Key for refresh token
  static const String _keyRefreshToken = 'refresh_token';

  /// Key for token expiry
  static const String _keyTokenExpiry = 'token_expiry';

  /// Key for user data
  static const String _keyUserData = 'user_data';

  /// Key for user ID
  static const String _keyUserId = 'user_id';

  /// Key for user phone
  static const String _keyUserPhone = 'user_phone';

  /// Key for FCM token
  static const String _keyFcmToken = 'fcm_token';

  /// Key for device ID
  static const String _keyDeviceId = 'device_id';

  /// Key for biometric enabled flag
  static const String _keyBiometricEnabled = 'biometric_enabled';

  /// Key for first launch flag
  static const String _keyFirstLaunch = 'first_launch';

  /// Key for onboarding completed flag
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  /// Key for app lock PIN
  static const String _keyAppLockPin = 'app_lock_pin';

  /// Key for last login timestamp
  static const String _keyLastLogin = 'last_login';

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize secure storage with platform-specific options
  Future<void> init() async {
    if (_isInitialized) return;

    // Configure Android options
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'rider_app_secure_prefs',
      preferencesKeyPrefix: 'rider_',
    );

    // Configure iOS options
    const iosOptions = IOSOptions(
      groupId: null,
      accountName: 'RiderApp',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    // Configure macOS options
    const macOsOptions = MacOsOptions(
      accountName: 'RiderApp',
      groupId: null,
    );

    // Configure Linux options
    const linuxOptions = LinuxOptions();

    // Configure Windows options
    const windowsOptions = WindowsOptions();

    _storage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
      mOptions: macOsOptions,
      lOptions: linuxOptions,
      wOptions: windowsOptions,
    );

    _isInitialized = true;
  }

  /// Ensure storage is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'SecureStorage not initialized. Call SecureStorage().init() first.',
      );
    }
  }

  // ============================================================================
  // ACCESS TOKEN
  // ============================================================================

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    _ensureInitialized();
    await _storage.write(key: _keyAccessToken, value: token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    _ensureInitialized();
    return _storage.read(key: _keyAccessToken);
  }

  /// Delete access token
  Future<void> deleteAccessToken() async {
    _ensureInitialized();
    await _storage.delete(key: _keyAccessToken);
  }

  /// Check if access token exists
  Future<bool> hasAccessToken() async {
    _ensureInitialized();
    final token = await _storage.read(key: _keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  // ============================================================================
  // REFRESH TOKEN
  // ============================================================================

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    _ensureInitialized();
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    _ensureInitialized();
    return _storage.read(key: _keyRefreshToken);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    _ensureInitialized();
    await _storage.delete(key: _keyRefreshToken);
  }

  // ============================================================================
  // TOKEN EXPIRY
  // ============================================================================

  /// Save token expiry timestamp
  Future<void> saveTokenExpiry(DateTime expiry) async {
    _ensureInitialized();
    await _storage.write(
      key: _keyTokenExpiry,
      value: expiry.toIso8601String(),
    );
  }

  /// Get token expiry timestamp
  Future<DateTime?> getTokenExpiry() async {
    _ensureInitialized();
    final expiryString = await _storage.read(key: _keyTokenExpiry);
    if (expiryString == null) return null;
    return DateTime.tryParse(expiryString);
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  /// Delete token expiry
  Future<void> deleteTokenExpiry() async {
    _ensureInitialized();
    await _storage.delete(key: _keyTokenExpiry);
  }

  // ============================================================================
  // COMBINED TOKEN OPERATIONS
  // ============================================================================

  /// Save all authentication tokens
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiry,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      if (expiry != null) saveTokenExpiry(expiry),
    ]);
  }

  /// Clear all authentication tokens
  Future<void> clearAuthTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      deleteTokenExpiry(),
    ]);
  }

  // ============================================================================
  // USER DATA
  // ============================================================================

  /// Save user data as JSON
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    _ensureInitialized();
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _keyUserData, value: jsonString);
  }

  /// Get user data as Map
  Future<Map<String, dynamic>?> getUserData() async {
    _ensureInitialized();
    final jsonString = await _storage.read(key: _keyUserData);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Delete user data
  Future<void> deleteUserData() async {
    _ensureInitialized();
    await _storage.delete(key: _keyUserData);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    _ensureInitialized();
    await _storage.write(key: _keyUserId, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    _ensureInitialized();
    return _storage.read(key: _keyUserId);
  }

  /// Delete user ID
  Future<void> deleteUserId() async {
    _ensureInitialized();
    await _storage.delete(key: _keyUserId);
  }

  /// Save user phone
  Future<void> saveUserPhone(String phone) async {
    _ensureInitialized();
    await _storage.write(key: _keyUserPhone, value: phone);
  }

  /// Get user phone
  Future<String?> getUserPhone() async {
    _ensureInitialized();
    return _storage.read(key: _keyUserPhone);
  }

  /// Delete user phone
  Future<void> deleteUserPhone() async {
    _ensureInitialized();
    await _storage.delete(key: _keyUserPhone);
  }

  // ============================================================================
  // FCM TOKEN
  // ============================================================================

  /// Save FCM token
  Future<void> saveFcmToken(String token) async {
    _ensureInitialized();
    await _storage.write(key: _keyFcmToken, value: token);
  }

  /// Get FCM token
  Future<String?> getFcmToken() async {
    _ensureInitialized();
    return _storage.read(key: _keyFcmToken);
  }

  /// Delete FCM token
  Future<void> deleteFcmToken() async {
    _ensureInitialized();
    await _storage.delete(key: _keyFcmToken);
  }

  // ============================================================================
  // DEVICE ID
  // ============================================================================

  /// Save device ID
  Future<void> saveDeviceId(String deviceId) async {
    _ensureInitialized();
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  /// Get device ID
  Future<String?> getDeviceId() async {
    _ensureInitialized();
    return _storage.read(key: _keyDeviceId);
  }

  /// Delete device ID
  Future<void> deleteDeviceId() async {
    _ensureInitialized();
    await _storage.delete(key: _keyDeviceId);
  }

  // ============================================================================
  // BIOMETRIC / APP LOCK
  // ============================================================================

  /// Save biometric enabled status
  Future<void> setBiometricEnabled(bool enabled) async {
    _ensureInitialized();
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Get biometric enabled status
  Future<bool> isBiometricEnabled() async {
    _ensureInitialized();
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Save app lock PIN
  Future<void> saveAppLockPin(String pin) async {
    _ensureInitialized();
    await _storage.write(key: _keyAppLockPin, value: pin);
  }

  /// Get app lock PIN
  Future<String?> getAppLockPin() async {
    _ensureInitialized();
    return _storage.read(key: _keyAppLockPin);
  }

  /// Delete app lock PIN
  Future<void> deleteAppLockPin() async {
    _ensureInitialized();
    await _storage.delete(key: _keyAppLockPin);
  }

  /// Check if app lock is set
  Future<bool> hasAppLock() async {
    final pin = await getAppLockPin();
    return pin != null && pin.isNotEmpty;
  }

  /// Verify app lock PIN
  Future<bool> verifyAppLockPin(String pin) async {
    final storedPin = await getAppLockPin();
    return storedPin == pin;
  }

  // ============================================================================
  // APP STATE FLAGS
  // ============================================================================

  /// Check if this is first launch
  Future<bool> isFirstLaunch() async {
    _ensureInitialized();
    final value = await _storage.read(key: _keyFirstLaunch);
    return value != 'false';
  }

  /// Set first launch completed
  Future<void> setFirstLaunchCompleted() async {
    _ensureInitialized();
    await _storage.write(key: _keyFirstLaunch, value: 'false');
  }

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    _ensureInitialized();
    final value = await _storage.read(key: _keyOnboardingCompleted);
    return value == 'true';
  }

  /// Set onboarding completed
  Future<void> setOnboardingCompleted() async {
    _ensureInitialized();
    await _storage.write(key: _keyOnboardingCompleted, value: 'true');
  }

  // ============================================================================
  // LAST LOGIN
  // ============================================================================

  /// Save last login timestamp
  Future<void> saveLastLogin(DateTime timestamp) async {
    _ensureInitialized();
    await _storage.write(
      key: _keyLastLogin,
      value: timestamp.toIso8601String(),
    );
  }

  /// Get last login timestamp
  Future<DateTime?> getLastLogin() async {
    _ensureInitialized();
    final value = await _storage.read(key: _keyLastLogin);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  // ============================================================================
  // GENERIC OPERATIONS
  // ============================================================================

  /// Write a value with custom key
  Future<void> write(String key, String value) async {
    _ensureInitialized();
    await _storage.write(key: key, value: value);
  }

  /// Read a value with custom key
  Future<String?> read(String key) async {
    _ensureInitialized();
    return _storage.read(key: key);
  }

  /// Delete a value with custom key
  Future<void> delete(String key) async {
    _ensureInitialized();
    await _storage.delete(key: key);
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    _ensureInitialized();
    final value = await _storage.read(key: key);
    return value != null;
  }

  /// Get all keys
  Future<Map<String, String>> readAll() async {
    _ensureInitialized();
    return _storage.readAll();
  }

  // ============================================================================
  // CLEAR OPERATIONS
  // ============================================================================

  /// Clear all stored data (use with caution!)
  Future<void> clearAll() async {
    _ensureInitialized();
    await _storage.deleteAll();
  }

  /// Clear user-related data but keep device settings
  Future<void> clearUserData() async {
    await Future.wait([
      clearAuthTokens(),
      deleteUserData(),
      deleteUserId(),
      deleteUserPhone(),
    ]);
  }

  /// Clear auth data on logout
  Future<void> onLogout() async {
    await Future.wait([
      clearAuthTokens(),
      deleteUserData(),
      deleteUserId(),
      deleteUserPhone(),
      deleteFcmToken(),
    ]);
  }

  // ============================================================================
  // AUTHENTICATION STATE
  // ============================================================================

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final hasToken = await hasAccessToken();
    if (!hasToken) return false;

    final isExpired = await isTokenExpired();
    if (isExpired) {
      // Check if we have refresh token to potentially refresh
      final refreshToken = await getRefreshToken();
      return refreshToken != null && refreshToken.isNotEmpty;
    }
    return true;
  }
}
