import 'package:flutter/material.dart';

/// App color palette for RiderApp - Green & White theme for rider incident reporting.
///
/// The green color scheme represents safety, trust, and authority - appropriate
/// for an app that connects riders with police for incident reporting.
abstract final class AppColors {
  // ============================================================================
  // PRIMARY COLORS - Green Palette
  // ============================================================================

  /// Primary green - Main brand color
  /// Used for primary buttons, app bars, and key UI elements
  static const Color primary = Color(0xFF2E7D32);

  /// Primary light - For hover states and secondary elements
  static const Color primaryLight = Color(0xFF4CAF50);

  /// Primary dark - For pressed states and emphasis
  static const Color primaryDark = Color(0xFF1B5E20);

  /// Primary variant - Alternative primary shade
  static const Color primaryVariant = Color(0xFF388E3C);

  /// Primary container - Light background with primary hint
  static const Color primaryContainer = Color(0xFFC8E6C9);

  /// On primary - Text/icons on primary colored backgrounds
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// On primary container - Text/icons on primary container backgrounds
  static const Color onPrimaryContainer = Color(0xFF1B5E20);

  // ============================================================================
  // SECONDARY COLORS
  // ============================================================================

  /// Secondary color - Accent for complementary elements
  static const Color secondary = Color(0xFF66BB6A);

  /// Secondary light
  static const Color secondaryLight = Color(0xFF81C784);

  /// Secondary dark
  static const Color secondaryDark = Color(0xFF43A047);

  /// Secondary container
  static const Color secondaryContainer = Color(0xFFDCEDC8);

  /// On secondary
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// On secondary container
  static const Color onSecondaryContainer = Color(0xFF33691E);

  // ============================================================================
  // TERTIARY COLORS
  // ============================================================================

  /// Tertiary color - For additional accents
  static const Color tertiary = Color(0xFF00897B);

  /// Tertiary container
  static const Color tertiaryContainer = Color(0xFFB2DFDB);

  /// On tertiary
  static const Color onTertiary = Color(0xFFFFFFFF);

  /// On tertiary container
  static const Color onTertiaryContainer = Color(0xFF004D40);

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  /// Background - Main app background (white)
  static const Color background = Color(0xFFFFFFFF);

  /// Surface - Card and container surfaces
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface variant - Slightly tinted surface
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// Scaffold background - Near-white for better readability
  static const Color scaffoldBackground = Color(0xFFFAFAFA);

  /// On background - Text on background
  static const Color onBackground = Color(0xFF1C1B1F);

  /// On surface - Text on surface
  static const Color onSurface = Color(0xFF1C1B1F);

  /// On surface variant
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text - Main content text
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary text - Subtitles, captions
  static const Color textSecondary = Color(0xFF757575);

  /// Tertiary text - Hints, disabled text
  static const Color textTertiary = Color(0xFF9E9E9E);

  /// Text on dark - White text for dark backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Text disabled
  static const Color textDisabled = Color(0xFFBDBDBD);

  // ============================================================================
  // STATUS COLORS
  // ============================================================================

  /// Success - Positive actions, completed status
  static const Color success = Color(0xFF4CAF50);

  /// Success light
  static const Color successLight = Color(0xFFC8E6C9);

  /// On success
  static const Color onSuccess = Color(0xFFFFFFFF);

  /// Warning - Caution, pending status
  static const Color warning = Color(0xFFFF9800);

  /// Warning light
  static const Color warningLight = Color(0xFFFFE0B2);

  /// On warning
  static const Color onWarning = Color(0xFF000000);

  /// Error - Errors, destructive actions
  static const Color error = Color(0xFFD32F2F);

  /// Error light
  static const Color errorLight = Color(0xFFFFCDD2);

  /// On error
  static const Color onError = Color(0xFFFFFFFF);

  /// Info - Information, neutral status
  static const Color info = Color(0xFF1976D2);

  /// Info light
  static const Color infoLight = Color(0xFFBBDEFB);

  /// On info
  static const Color onInfo = Color(0xFFFFFFFF);

  // ============================================================================
  // INCIDENT CATEGORY COLORS
  // ============================================================================

  /// Accident category - Red tones
  static const Color incidentAccident = Color(0xFFE53935);

  /// Theft category - Orange tones
  static const Color incidentTheft = Color(0xFFFF7043);

  /// Harassment category - Purple tones
  static const Color incidentHarassment = Color(0xFF8E24AA);

  /// Traffic violation category - Amber tones
  static const Color incidentTrafficViolation = Color(0xFFFFB300);

  /// Vehicle damage category - Blue-grey tones
  static const Color incidentVehicleDamage = Color(0xFF546E7A);

  /// Suspicious activity category - Deep purple tones
  static const Color incidentSuspiciousActivity = Color(0xFF5E35B1);

  /// Emergency category - Deep red tones
  static const Color incidentEmergency = Color(0xFFB71C1C);

  /// Other category - Grey tones
  static const Color incidentOther = Color(0xFF78909C);

  // ============================================================================
  // INCIDENT STATUS COLORS
  // ============================================================================

  /// Status pending
  static const Color statusPending = Color(0xFFFF9800);

  /// Status in progress
  static const Color statusInProgress = Color(0xFF2196F3);

  /// Status resolved
  static const Color statusResolved = Color(0xFF4CAF50);

  /// Status closed
  static const Color statusClosed = Color(0xFF9E9E9E);

  /// Status rejected
  static const Color statusRejected = Color(0xFFF44336);

  // ============================================================================
  // BORDER & DIVIDER COLORS
  // ============================================================================

  /// Border - Default border color
  static const Color border = Color(0xFFE0E0E0);

  /// Border light
  static const Color borderLight = Color(0xFFF5F5F5);

  /// Border focused - When input is focused
  static const Color borderFocused = Color(0xFF2E7D32);

  /// Divider
  static const Color divider = Color(0xFFE0E0E0);

  /// Outline
  static const Color outline = Color(0xFF79747E);

  /// Outline variant
  static const Color outlineVariant = Color(0xFFCAC4D0);

  // ============================================================================
  // SHADOW & OVERLAY COLORS
  // ============================================================================

  /// Shadow color
  static const Color shadow = Color(0xFF000000);

  /// Overlay - For modal backgrounds
  static const Color overlay = Color(0x80000000);

  /// Scrim
  static const Color scrim = Color(0xFF000000);

  // ============================================================================
  // NAVIGATION COLORS
  // ============================================================================

  /// Navigation bar background
  static const Color navigationBarBackground = Color(0xFFFFFFFF);

  /// Navigation bar selected
  static const Color navigationBarSelected = Color(0xFF2E7D32);

  /// Navigation bar unselected
  static const Color navigationBarUnselected = Color(0xFF9E9E9E);

  // ============================================================================
  // SHIMMER COLORS (for loading states)
  // ============================================================================

  /// Shimmer base
  static const Color shimmerBase = Color(0xFFE0E0E0);

  /// Shimmer highlight
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get color for incident category
  static Color getIncidentCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'accident':
        return incidentAccident;
      case 'theft':
        return incidentTheft;
      case 'harassment':
        return incidentHarassment;
      case 'traffic_violation':
      case 'trafficviolation':
        return incidentTrafficViolation;
      case 'vehicle_damage':
      case 'vehicledamage':
        return incidentVehicleDamage;
      case 'suspicious_activity':
      case 'suspiciousactivity':
        return incidentSuspiciousActivity;
      case 'emergency':
        return incidentEmergency;
      default:
        return incidentOther;
    }
  }

  /// Get color for incident status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'in_progress':
      case 'inprogress':
      case 'investigating':
        return statusInProgress;
      case 'resolved':
        return statusResolved;
      case 'closed':
        return statusClosed;
      case 'rejected':
        return statusRejected;
      default:
        return statusPending;
    }
  }

  /// Create MaterialColor swatch from a color
  static MaterialColor createMaterialColor(Color color) {
    final strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    final swatch = <int, Color>{};
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();

    for (final strength in strengths) {
      final ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }

  /// Primary color as MaterialColor swatch
  static MaterialColor get primarySwatch => createMaterialColor(primary);
}
