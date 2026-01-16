import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/settings_tile.dart';

/// Provider for notification settings state.
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) {
  return NotificationSettingsNotifier();
});

/// Notification settings model.
class NotificationSettings {
  final bool pushEnabled;
  final bool incidentAlerts;
  final bool chatNotifications;
  final bool announcementAlerts;
  final bool sosAlerts;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettings({
    this.pushEnabled = true,
    this.incidentAlerts = true,
    this.chatNotifications = true,
    this.announcementAlerts = true,
    this.sosAlerts = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? incidentAlerts,
    bool? chatNotifications,
    bool? announcementAlerts,
    bool? sosAlerts,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      incidentAlerts: incidentAlerts ?? this.incidentAlerts,
      chatNotifications: chatNotifications ?? this.chatNotifications,
      announcementAlerts: announcementAlerts ?? this.announcementAlerts,
      sosAlerts: sosAlerts ?? this.sosAlerts,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

/// Notification settings state notifier.
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  void setPushEnabled(bool value) {
    state = state.copyWith(pushEnabled: value);
  }

  void setIncidentAlerts(bool value) {
    state = state.copyWith(incidentAlerts: value);
  }

  void setChatNotifications(bool value) {
    state = state.copyWith(chatNotifications: value);
  }

  void setAnnouncementAlerts(bool value) {
    state = state.copyWith(announcementAlerts: value);
  }

  void setSosAlerts(bool value) {
    state = state.copyWith(sosAlerts: value);
  }

  void setSoundEnabled(bool value) {
    state = state.copyWith(soundEnabled: value);
  }

  void setVibrationEnabled(bool value) {
    state = state.copyWith(vibrationEnabled: value);
  }
}

/// Screen that displays notification settings.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.notifications'.tr()),
      ),
      body: ListView(
        children: [
          // Push Notifications Section
          SettingsSectionHeader(title: 'settings.pushNotifications'.tr()),

          SettingsSwitchTile(
            icon: Icons.notifications,
            title: 'settings.enablePush'.tr(),
            subtitle: 'settings.enablePushDesc'.tr(),
            value: settings.pushEnabled,
            onChanged: notifier.setPushEnabled,
          ),

          // Notification Types Section
          SettingsSectionHeader(title: 'settings.notificationTypes'.tr()),

          SettingsSwitchTile(
            icon: Icons.warning_amber,
            title: 'settings.incidentAlerts'.tr(),
            subtitle: 'settings.incidentAlertsDesc'.tr(),
            value: settings.incidentAlerts,
            onChanged: settings.pushEnabled ? notifier.setIncidentAlerts : null,
            enabled: settings.pushEnabled,
          ),

          const Divider(height: 1),

          SettingsSwitchTile(
            icon: Icons.chat_bubble_outline,
            title: 'settings.chatNotifications'.tr(),
            subtitle: 'settings.chatNotificationsDesc'.tr(),
            value: settings.chatNotifications,
            onChanged:
                settings.pushEnabled ? notifier.setChatNotifications : null,
            enabled: settings.pushEnabled,
          ),

          const Divider(height: 1),

          SettingsSwitchTile(
            icon: Icons.campaign_outlined,
            title: 'settings.announcementAlerts'.tr(),
            subtitle: 'settings.announcementAlertsDesc'.tr(),
            value: settings.announcementAlerts,
            onChanged:
                settings.pushEnabled ? notifier.setAnnouncementAlerts : null,
            enabled: settings.pushEnabled,
          ),

          const Divider(height: 1),

          SettingsSwitchTile(
            icon: Icons.sos,
            title: 'settings.sosAlerts'.tr(),
            subtitle: 'settings.sosAlertsDesc'.tr(),
            value: settings.sosAlerts,
            onChanged: settings.pushEnabled ? notifier.setSosAlerts : null,
            enabled: settings.pushEnabled,
          ),

          // Sound & Vibration Section
          SettingsSectionHeader(title: 'settings.soundVibration'.tr()),

          SettingsSwitchTile(
            icon: Icons.volume_up,
            title: 'settings.sound'.tr(),
            subtitle: 'settings.soundDesc'.tr(),
            value: settings.soundEnabled,
            onChanged: settings.pushEnabled ? notifier.setSoundEnabled : null,
            enabled: settings.pushEnabled,
          ),

          const Divider(height: 1),

          SettingsSwitchTile(
            icon: Icons.vibration,
            title: 'settings.vibration'.tr(),
            subtitle: 'settings.vibrationDesc'.tr(),
            value: settings.vibrationEnabled,
            onChanged:
                settings.pushEnabled ? notifier.setVibrationEnabled : null,
            enabled: settings.pushEnabled,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
