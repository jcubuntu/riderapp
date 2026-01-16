import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/settings_tile.dart';

/// Provider for theme mode state.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Screen that displays app settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = context.locale;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
      ),
      body: ListView(
        children: [
          // General Section
          SettingsSectionHeader(title: 'settings.general'.tr()),

          // Notifications
          SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'settings.notifications'.tr(),
            subtitle: 'settings.notificationsDesc'.tr(),
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),

          const Divider(height: 1),

          // Language
          SettingsTile(
            icon: Icons.language,
            title: 'settings.language'.tr(),
            subtitle: _getLanguageName(currentLocale),
            onTap: () => _showLanguageDialog(context),
          ),

          const Divider(height: 1),

          // Theme
          SettingsTile(
            icon: Icons.palette_outlined,
            title: 'settings.theme'.tr(),
            subtitle: _getThemeModeName(themeMode),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),

          // App Info Section
          SettingsSectionHeader(title: 'settings.appInfo'.tr()),

          // About
          SettingsTile(
            icon: Icons.info_outline,
            title: 'settings.about'.tr(),
            subtitle: 'RiderApp v1.0.0',
            onTap: () => _showAboutDialog(context),
          ),

          const Divider(height: 1),

          // Terms of Service
          SettingsTile(
            icon: Icons.description_outlined,
            title: 'settings.termsOfService'.tr(),
            onTap: () {
              // TODO: Open terms of service
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('settings.comingSoon'.tr())),
              );
            },
          ),

          const Divider(height: 1),

          // Privacy Policy
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'settings.privacyPolicy'.tr(),
            onTap: () {
              // TODO: Open privacy policy
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('settings.comingSoon'.tr())),
              );
            },
          ),

          // Account Section
          SettingsSectionHeader(title: 'settings.account'.tr()),

          // Logout
          SettingsTile(
            icon: Icons.logout,
            iconColor: AppColors.error,
            title: 'auth.logout'.tr(),
            showChevron: false,
            onTap: () => _showLogoutDialog(context, ref),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'th':
        return 'ไทย';
      case 'en':
      default:
        return 'English';
    }
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'settings.themeSystem'.tr();
      case ThemeMode.light:
        return 'settings.themeLight'.tr();
      case ThemeMode.dark:
        return 'settings.themeDark'.tr();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: context.locale.languageCode == 'en'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.of(dialogContext).pop();
              },
            ),
            ListTile(
              leading: const Text('🇹🇭', style: TextStyle(fontSize: 24)),
              title: const Text('ไทย'),
              trailing: context.locale.languageCode == 'th'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                context.setLocale(const Locale('th'));
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('settings.theme'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: Text('settings.themeSystem'.tr()),
              trailing: currentMode == ThemeMode.system
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                Navigator.of(dialogContext).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text('settings.themeLight'.tr()),
              trailing: currentMode == ThemeMode.light
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).state = ThemeMode.light;
                Navigator.of(dialogContext).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text('settings.themeDark'.tr()),
              trailing: currentMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RiderApp',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.two_wheeler,
          color: Colors.white,
          size: 40,
        ),
      ),
      applicationLegalese: 'settings.copyright'.tr(),
      children: [
        const SizedBox(height: 16),
        Text(
          'app.tagline'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('auth.logout'.tr()),
        content: Text('settings.logoutConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text('auth.logout'.tr()),
          ),
        ],
      ),
    );
  }
}
