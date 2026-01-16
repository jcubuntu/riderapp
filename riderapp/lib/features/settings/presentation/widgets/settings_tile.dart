import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// A reusable settings tile widget.
class SettingsTile extends StatelessWidget {
  /// The leading icon.
  final IconData icon;

  /// The icon color.
  final Color? iconColor;

  /// The title text.
  final String title;

  /// The subtitle text.
  final String? subtitle;

  /// The trailing widget.
  final Widget? trailing;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Whether to show a chevron icon at the end.
  final bool showChevron;

  /// Whether the tile is enabled.
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled
              ? (iconColor ?? AppColors.primary)
              : AppColors.textDisabled,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? null : AppColors.textDisabled,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
              ),
            )
          : null,
      trailing: trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right,
                  color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
                )
              : null),
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }
}

/// A settings tile with a switch.
class SettingsSwitchTile extends StatelessWidget {
  /// The leading icon.
  final IconData icon;

  /// The icon color.
  final Color? iconColor;

  /// The title text.
  final String title;

  /// The subtitle text.
  final String? subtitle;

  /// The current value of the switch.
  final bool value;

  /// Called when the switch value changes.
  final ValueChanged<bool>? onChanged;

  /// Whether the tile is enabled.
  final bool enabled;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      showChevron: false,
      enabled: enabled,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
      onTap: enabled && onChanged != null
          ? () => onChanged!(!value)
          : null,
    );
  }
}

/// A section header for settings.
class SettingsSectionHeader extends StatelessWidget {
  /// The section title.
  final String title;

  const SettingsSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
