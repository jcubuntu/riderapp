import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/locations_state.dart';

/// A card widget displaying the current device location status
class LocationStatusCard extends StatelessWidget {
  /// The current device location state
  final DeviceLocationState deviceState;

  /// Callback when refresh button is tapped
  final VoidCallback? onRefresh;

  /// Callback when settings button is tapped (for denied permissions)
  final VoidCallback? onOpenSettings;

  const LocationStatusCard({
    super.key,
    required this.deviceState,
    this.onRefresh,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'locations.currentLocation'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (deviceState is! DeviceLocationLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContent(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    switch (deviceState) {
      case DeviceLocationInitial():
        return _buildInitialState(theme);

      case DeviceLocationLoading():
        return _buildLoadingState(theme);

      case DeviceLocationLoaded(
          latitude: final lat,
          longitude: final lng,
          accuracy: final accuracy,
          timestamp: final timestamp,
        ):
        return _buildLoadedState(theme, lat, lng, accuracy, timestamp);

      case DeviceLocationDenied(isPermanentlyDenied: final isPermanent):
        return _buildDeniedState(theme, isPermanent);

      case DeviceLocationError(message: final message):
        return _buildErrorState(theme, message);
    }
  }

  Widget _buildInitialState(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.location_searching,
          color: theme.colorScheme.outline,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          'locations.tapToGetLocation'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'locations.gettingLocation'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedState(
    ThemeData theme,
    double latitude,
    double longitude,
    double? accuracy,
    DateTime timestamp,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'locations.locationReady'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildCoordinateRow(
                theme,
                'Lat',
                latitude.toStringAsFixed(6),
              ),
              const SizedBox(height: 4),
              _buildCoordinateRow(
                theme,
                'Lng',
                longitude.toStringAsFixed(6),
              ),
              if (accuracy != null) ...[
                const SizedBox(height: 4),
                _buildCoordinateRow(
                  theme,
                  'locations.accuracy'.tr(),
                  '${accuracy.round()} m',
                ),
              ],
              const SizedBox(height: 4),
              _buildCoordinateRow(
                theme,
                'locations.updated'.tr(),
                _formatTimestamp(timestamp),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinateRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildDeniedState(ThemeData theme, bool isPermanent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_off,
              color: theme.colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isPermanent
                  ? 'locations.permissionDeniedPermanent'.tr()
                  : 'locations.permissionDenied'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        if (isPermanent) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings, size: 16),
              label: Text('locations.openSettings'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: theme.colorScheme.error,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('HH:mm:ss').format(timestamp);
  }
}

/// A compact location status indicator
class LocationStatusIndicator extends StatelessWidget {
  /// The current device location state
  final DeviceLocationState deviceState;

  /// Size of the indicator
  final double size;

  const LocationStatusIndicator({
    super.key,
    required this.deviceState,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (deviceState) {
      case DeviceLocationInitial():
        icon = Icons.location_searching;
        color = Colors.grey;
        break;

      case DeviceLocationLoading():
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        );

      case DeviceLocationLoaded():
        icon = Icons.location_on;
        color = Colors.green;
        break;

      case DeviceLocationDenied():
        icon = Icons.location_off;
        color = Colors.red;
        break;

      case DeviceLocationError():
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}

/// A widget showing sharing status with animation
class SharingStatusIndicator extends StatefulWidget {
  /// Whether sharing is active
  final bool isActive;

  /// Size of the indicator
  final double size;

  const SharingStatusIndicator({
    super.key,
    required this.isActive,
    this.size = 12,
  });

  @override
  State<SharingStatusIndicator> createState() => _SharingStatusIndicatorState();
}

class _SharingStatusIndicatorState extends State<SharingStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SharingStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? Colors.green : Colors.grey;

    if (widget.isActive) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: _animation.value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: _animation.value * 0.5),
                  blurRadius: widget.size / 2,
                  spreadRadius: widget.size / 4 * _animation.value,
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
