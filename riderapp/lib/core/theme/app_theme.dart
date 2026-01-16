import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// App theme configuration for RiderApp.
///
/// Provides complete Material 3 theme with Green & White color scheme.
/// Includes light and dark themes with consistent styling across all components.
abstract final class AppTheme {
  // ============================================================================
  // COLOR SCHEME
  // ============================================================================

  /// Light color scheme based on green seed
  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      );

  /// Dark color scheme based on green seed
  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        onPrimary: AppColors.primaryDark,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.secondaryDark,
        tertiary: AppColors.tertiary,
        error: AppColors.errorLight,
      );

  // ============================================================================
  // LIGHT THEME
  // ============================================================================

  /// Light theme data
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: lightColorScheme,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        // AppBar Theme
        appBarTheme: _appBarTheme,
        // Card Theme
        cardTheme: _cardTheme,
        // Elevated Button Theme
        elevatedButtonTheme: _elevatedButtonTheme,
        // Outlined Button Theme
        outlinedButtonTheme: _outlinedButtonTheme,
        // Text Button Theme
        textButtonTheme: _textButtonTheme,
        // Floating Action Button Theme
        floatingActionButtonTheme: _floatingActionButtonTheme,
        // Input Decoration Theme
        inputDecorationTheme: _inputDecorationTheme,
        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: _bottomNavigationBarTheme,
        // Navigation Bar Theme (Material 3)
        navigationBarTheme: _navigationBarTheme,
        // Tab Bar Theme
        tabBarTheme: _tabBarTheme,
        // Chip Theme
        chipTheme: _chipTheme,
        // Dialog Theme
        dialogTheme: _dialogTheme,
        // Bottom Sheet Theme
        bottomSheetTheme: _bottomSheetTheme,
        // Snackbar Theme
        snackBarTheme: _snackBarTheme,
        // Divider Theme
        dividerTheme: _dividerTheme,
        // List Tile Theme
        listTileTheme: _listTileTheme,
        // Switch Theme
        switchTheme: _switchTheme,
        // Checkbox Theme
        checkboxTheme: _checkboxTheme,
        // Radio Theme
        radioTheme: _radioTheme,
        // Progress Indicator Theme
        progressIndicatorTheme: _progressIndicatorTheme,
        // Slider Theme
        sliderTheme: _sliderTheme,
        // Text Theme
        textTheme: _textTheme,
        // Icon Theme
        iconTheme: _iconTheme,
        // Page Transitions
        pageTransitionsTheme: _pageTransitionsTheme,
        // Visual Density
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  // ============================================================================
  // DARK THEME
  // ============================================================================

  /// Dark theme data
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: darkColorScheme,
        primaryColor: AppColors.primaryLight,
        scaffoldBackgroundColor: const Color(0xFF121212),
        // AppBar Theme
        appBarTheme: _darkAppBarTheme,
        // Card Theme
        cardTheme: _darkCardTheme,
        // Elevated Button Theme
        elevatedButtonTheme: _darkElevatedButtonTheme,
        // Outlined Button Theme
        outlinedButtonTheme: _darkOutlinedButtonTheme,
        // Text Button Theme
        textButtonTheme: _darkTextButtonTheme,
        // Floating Action Button Theme
        floatingActionButtonTheme: _darkFloatingActionButtonTheme,
        // Input Decoration Theme
        inputDecorationTheme: _darkInputDecorationTheme,
        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: _darkBottomNavigationBarTheme,
        // Navigation Bar Theme (Material 3)
        navigationBarTheme: _darkNavigationBarTheme,
        // Tab Bar Theme
        tabBarTheme: _darkTabBarTheme,
        // Chip Theme
        chipTheme: _darkChipTheme,
        // Dialog Theme
        dialogTheme: _darkDialogTheme,
        // Bottom Sheet Theme
        bottomSheetTheme: _darkBottomSheetTheme,
        // Snackbar Theme
        snackBarTheme: _darkSnackBarTheme,
        // Divider Theme
        dividerTheme: _darkDividerTheme,
        // List Tile Theme
        listTileTheme: _darkListTileTheme,
        // Switch Theme
        switchTheme: _darkSwitchTheme,
        // Checkbox Theme
        checkboxTheme: _darkCheckboxTheme,
        // Radio Theme
        radioTheme: _darkRadioTheme,
        // Progress Indicator Theme
        progressIndicatorTheme: _darkProgressIndicatorTheme,
        // Slider Theme
        sliderTheme: _darkSliderTheme,
        // Text Theme
        textTheme: _darkTextTheme,
        // Icon Theme
        iconTheme: _darkIconTheme,
        // Page Transitions
        pageTransitionsTheme: _pageTransitionsTheme,
        // Visual Density
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );

  // ============================================================================
  // APP BAR THEME
  // ============================================================================

  static AppBarTheme get _appBarTheme => const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: AppColors.onPrimary,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.onPrimary,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

  static AppBarTheme get _darkAppBarTheme => AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
      );

  // ============================================================================
  // CARD THEME
  // ============================================================================

  static CardThemeData get _cardTheme => CardThemeData(
        elevation: 1,
        shadowColor: AppColors.shadow.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      );

  static CardThemeData get _darkCardTheme => CardThemeData(
        elevation: 1,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        color: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      );

  // ============================================================================
  // ELEVATED BUTTON THEME
  // ============================================================================

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  static ElevatedButtonThemeData get _darkElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryDark,
          disabledBackgroundColor: const Color(0xFF404040),
          disabledForegroundColor: Colors.grey,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  // ============================================================================
  // OUTLINED BUTTON THEME
  // ============================================================================

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  static OutlinedButtonThemeData get _darkOutlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          disabledForegroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  // ============================================================================
  // TEXT BUTTON THEME
  // ============================================================================

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  static TextButtonThemeData get _darkTextButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          disabledForegroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  // ============================================================================
  // FLOATING ACTION BUTTON THEME
  // ============================================================================

  static FloatingActionButtonThemeData get _floatingActionButtonTheme =>
      const FloatingActionButtonThemeData(
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 6,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        splashColor: AppColors.primaryLight,
        shape: StadiumBorder(),
      );

  static FloatingActionButtonThemeData get _darkFloatingActionButtonTheme =>
      const FloatingActionButtonThemeData(
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 6,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.primaryDark,
        splashColor: AppColors.primary,
        shape: StadiumBorder(),
      );

  // ============================================================================
  // INPUT DECORATION THEME
  // ============================================================================

  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 16,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      );

  static InputDecorationTheme get _darkInputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorLight),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF303030)),
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(
          color: AppColors.errorLight,
          fontSize: 12,
        ),
        prefixIconColor: Colors.grey,
        suffixIconColor: Colors.grey,
      );

  // ============================================================================
  // BOTTOM NAVIGATION BAR THEME
  // ============================================================================

  static BottomNavigationBarThemeData get _bottomNavigationBarTheme =>
      const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: AppColors.navigationBarBackground,
        selectedItemColor: AppColors.navigationBarSelected,
        unselectedItemColor: AppColors.navigationBarUnselected,
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 24),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  static BottomNavigationBarThemeData get _darkBottomNavigationBarTheme =>
      const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 24),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  // ============================================================================
  // NAVIGATION BAR THEME (Material 3)
  // ============================================================================

  static NavigationBarThemeData get _navigationBarTheme =>
      NavigationBarThemeData(
        elevation: 3,
        backgroundColor: AppColors.navigationBarBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryContainer,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.navigationBarUnselected,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: AppColors.navigationBarUnselected,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          );
        }),
      );

  static NavigationBarThemeData get _darkNavigationBarTheme =>
      NavigationBarThemeData(
        elevation: 3,
        backgroundColor: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryDark.withValues(alpha: 0.5),
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primaryLight,
              size: 24,
            );
          }
          return const IconThemeData(
            color: Colors.grey,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          );
        }),
      );

  // ============================================================================
  // TAB BAR THEME
  // ============================================================================

  static TabBarThemeData get _tabBarTheme => const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      );

  static TabBarThemeData get _darkTabBarTheme => const TabBarThemeData(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      );

  // ============================================================================
  // CHIP THEME
  // ============================================================================

  static ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.borderLight,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      );

  static ChipThemeData get _darkChipTheme => ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedColor: AppColors.primaryDark.withValues(alpha: 0.5),
        disabledColor: const Color(0xFF303030),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      );

  // ============================================================================
  // DIALOG THEME
  // ============================================================================

  static DialogThemeData get _dialogTheme => DialogThemeData(
        elevation: 8,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
      );

  static DialogThemeData get _darkDialogTheme => DialogThemeData(
        elevation: 8,
        backgroundColor: const Color(0xFF2C2C2C),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      );

  // ============================================================================
  // BOTTOM SHEET THEME
  // ============================================================================

  static BottomSheetThemeData get _bottomSheetTheme =>
      const BottomSheetThemeData(
        elevation: 8,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalElevation: 8,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: AppColors.border,
        dragHandleSize: Size(32, 4),
        showDragHandle: true,
      );

  static BottomSheetThemeData get _darkBottomSheetTheme =>
      const BottomSheetThemeData(
        elevation: 8,
        backgroundColor: Color(0xFF2C2C2C),
        surfaceTintColor: Colors.transparent,
        modalElevation: 8,
        modalBackgroundColor: Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: Color(0xFF404040),
        dragHandleSize: Size(32, 4),
        showDragHandle: true,
      );

  // ============================================================================
  // SNACKBAR THEME
  // ============================================================================

  static SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
        elevation: 4,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.primaryLight,
      );

  static SnackBarThemeData get _darkSnackBarTheme => SnackBarThemeData(
        elevation: 4,
        backgroundColor: const Color(0xFF404040),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.primaryLight,
      );

  // ============================================================================
  // DIVIDER THEME
  // ============================================================================

  static DividerThemeData get _dividerTheme => const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      );

  static DividerThemeData get _darkDividerTheme => const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
        space: 1,
      );

  // ============================================================================
  // LIST TILE THEME
  // ============================================================================

  static ListTileThemeData get _listTileTheme => const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      );

  static ListTileThemeData get _darkListTileTheme => const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        iconColor: Colors.grey,
        textColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      );

  // ============================================================================
  // SWITCH THEME
  // ============================================================================

  static SwitchThemeData get _switchTheme => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryContainer;
          }
          return AppColors.border;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      );

  static SwitchThemeData get _darkSwitchTheme => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark.withValues(alpha: 0.5);
          }
          return const Color(0xFF404040);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      );

  // ============================================================================
  // CHECKBOX THEME
  // ============================================================================

  static CheckboxThemeData get _checkboxTheme => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      );

  static CheckboxThemeData get _darkCheckboxTheme => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.primaryDark),
        side: const BorderSide(color: Color(0xFF404040), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      );

  // ============================================================================
  // RADIO THEME
  // ============================================================================

  static RadioThemeData get _radioTheme => RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondary;
        }),
      );

  static RadioThemeData get _darkRadioTheme => RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return Colors.grey;
        }),
      );

  // ============================================================================
  // PROGRESS INDICATOR THEME
  // ============================================================================

  static ProgressIndicatorThemeData get _progressIndicatorTheme =>
      const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryContainer,
        circularTrackColor: AppColors.primaryContainer,
      );

  static ProgressIndicatorThemeData get _darkProgressIndicatorTheme =>
      ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.primaryDark.withValues(alpha: 0.3),
        circularTrackColor: AppColors.primaryDark.withValues(alpha: 0.3),
      );

  // ============================================================================
  // SLIDER THEME
  // ============================================================================

  static SliderThemeData get _sliderTheme => SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primaryContainer,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 14,
        ),
      );

  static SliderThemeData get _darkSliderTheme => SliderThemeData(
        activeTrackColor: AppColors.primaryLight,
        inactiveTrackColor: AppColors.primaryDark.withValues(alpha: 0.3),
        thumbColor: AppColors.primaryLight,
        overlayColor: AppColors.primaryLight.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.primaryLight,
        valueIndicatorTextStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 14,
        ),
      );

  // ============================================================================
  // TEXT THEME
  // ============================================================================

  static TextTheme get _textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  static TextTheme get _darkTextTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.grey,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      );

  // ============================================================================
  // ICON THEME
  // ============================================================================

  static IconThemeData get _iconTheme => const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      );

  static IconThemeData get _darkIconTheme => const IconThemeData(
        color: Colors.white,
        size: 24,
      );

  // ============================================================================
  // PAGE TRANSITIONS
  // ============================================================================

  static PageTransitionsTheme get _pageTransitionsTheme =>
      const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }

  /// Get color scheme based on brightness
  static ColorScheme getColorScheme(Brightness brightness) {
    return brightness == Brightness.light ? lightColorScheme : darkColorScheme;
  }
}
