import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/locations_provider.dart';
import '../providers/locations_state.dart';
import '../widgets/location_status_card.dart';
import '../widgets/rider_map.dart';

/// Screen for controlling live location sharing
class LocationSharingScreen extends ConsumerStatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  ConsumerState<LocationSharingScreen> createState() =>
      _LocationSharingScreenState();
}

class _LocationSharingScreenState extends ConsumerState<LocationSharingScreen> {
  int _selectedDuration = 60; // Default 1 hour
  final GlobalKey<RiderMapState> _mapKey = GlobalKey<RiderMapState>();
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    // Check current sharing status on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationSharingProvider.notifier).checkStatus();
      ref.read(deviceLocationProvider.notifier).getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharingState = ref.watch(locationSharingProvider);
    final deviceState = ref.watch(deviceLocationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('locations.sharing.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(locationSharingProvider.notifier).checkStatus();
              ref.read(deviceLocationProvider.notifier).getCurrentLocation();
            },
            tooltip: 'common.refresh'.tr(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(locationSharingProvider.notifier).checkStatus();
          ref.read(deviceLocationProvider.notifier).getCurrentLocation();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map view showing current location
              _buildMapSection(deviceState, sharingState, theme),

              const SizedBox(height: 16),

              // Current location status card
              LocationStatusCard(
                deviceState: deviceState,
                onRefresh: () {
                  ref.read(deviceLocationProvider.notifier).getCurrentLocation();
                },
              ),

              const SizedBox(height: 24),

              // Sharing status section
              _buildSharingSection(sharingState, theme),

              const SizedBox(height: 24),

              // Duration selector (when not sharing)
              if (sharingState is! LocationSharingActive)
                _buildDurationSelector(theme),

              const SizedBox(height: 24),

              // Share button
              _buildShareButton(sharingState, deviceState, theme),

              const SizedBox(height: 16),

              // Error message
              if (sharingState is LocationSharingError)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sharingState.message,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Info section
              _buildInfoSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(
    DeviceLocationState deviceState,
    LocationSharingState sharingState,
    ThemeData theme,
  ) {
    final isSharing = sharingState is LocationSharingActive;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map
            _buildMap(deviceState, isSharing),

            // Sharing indicator overlay
            if (isSharing)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _PulsingDot(color: Colors.white, size: 8),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading overlay
            if (deviceState is DeviceLocationLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Error/Permission denied overlay
            if (deviceState is DeviceLocationDenied ||
                deviceState is DeviceLocationError)
              Container(
                color: Colors.white.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        deviceState is DeviceLocationDenied
                            ? Icons.location_off
                            : Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        deviceState is DeviceLocationDenied
                            ? 'locations.permissionDenied'.tr()
                            : (deviceState as DeviceLocationError).message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(deviceLocationProvider.notifier).getCurrentLocation();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                ),
              ),

            // Recenter button
            if (deviceState is DeviceLocationLoaded)
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
                  onPressed: () {
                    _mapKey.currentState?.moveToCurrentLocation();
                  },
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(DeviceLocationState deviceState, bool isSharing) {
    LatLng? currentLocation;

    if (deviceState is DeviceLocationLoaded) {
      currentLocation = LatLng(deviceState.latitude, deviceState.longitude);
    }

    // Show map with current location or default Bangkok location
    return RiderMap(
      key: _mapKey,
      currentLocation: currentLocation,
      showZoomControls: false,
      showMyLocationButton: false,
      myLocationEnabled: false,
      showCompass: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
      initialCameraPosition: CameraPosition(
        target: currentLocation ?? const LatLng(kDefaultLatitude, kDefaultLongitude),
        zoom: 16,
      ),
      circles: currentLocation != null && isSharing
          ? {
              Circle(
                circleId: const CircleId('sharing_radius'),
                center: currentLocation,
                radius: 100,
                fillColor: Colors.blue.withValues(alpha: 0.1),
                strokeColor: Colors.blue.withValues(alpha: 0.3),
                strokeWidth: 2,
              ),
            }
          : {},
    );
  }

  Widget _buildSharingSection(LocationSharingState state, ThemeData theme) {
    final isActive = state is LocationSharingActive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.location_on : Icons.location_off,
                    color: isActive ? Colors.green : theme.colorScheme.outline,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive
                            ? 'locations.sharing.active'.tr()
                            : 'locations.sharing.inactive'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? 'locations.sharing.activeDescription'.tr()
                            : 'locations.sharing.inactiveDescription'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state is LocationSharingActive && state.lastUpdated != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'locations.sharing.lastUpdated'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    _formatTime(state.lastUpdated!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (state.sharingInfo.expiresAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'locations.sharing.expiresAt'.tr(),
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      _formatTime(state.sharingInfo.expiresAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'locations.sharing.duration'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDurationChip(15, '15 min'),
                _buildDurationChip(30, '30 min'),
                _buildDurationChip(60, '1 hour'),
                _buildDurationChip(120, '2 hours'),
                _buildDurationChip(480, '8 hours'),
                _buildDurationChip(0, 'Until stopped'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = _selectedDuration == minutes;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDuration = minutes;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }

  Widget _buildShareButton(
    LocationSharingState sharingState,
    DeviceLocationState deviceState,
    ThemeData theme,
  ) {
    final isLoading = sharingState is LocationSharingLoading ||
        sharingState is LocationSharingStarting ||
        sharingState is LocationSharingStopping;
    final isActive = sharingState is LocationSharingActive;
    final hasLocation = deviceState is DeviceLocationLoaded;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                if (isActive) {
                  ref.read(locationSharingProvider.notifier).stopSharing();
                } else {
                  if (!hasLocation) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('locations.sharing.noLocation'.tr()),
                      ),
                    );
                    return;
                  }
                  ref.read(locationSharingProvider.notifier).startSharing(
                        durationMinutes:
                            _selectedDuration > 0 ? _selectedDuration : null,
                      );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          foregroundColor: isActive
              ? theme.colorScheme.onError
              : theme.colorScheme.onPrimary,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isActive ? Icons.stop : Icons.share_location),
                  const SizedBox(width: 8),
                  Text(
                    isActive
                        ? 'locations.sharing.stop'.tr()
                        : 'locations.sharing.start'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'locations.sharing.info.title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              theme,
              Icons.visibility,
              'locations.sharing.info.visibility'.tr(),
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              theme,
              Icons.battery_saver,
              'locations.sharing.info.battery'.tr(),
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              theme,
              Icons.lock,
              'locations.sharing.info.privacy'.tr(),
            ),
            const SizedBox(height: 12),
            // TODO: Add Google Maps API key configuration instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.developer_mode,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Google Maps requires API key configuration in Android (AndroidManifest.xml) and iOS (AppDelegate.swift).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}

/// A pulsing dot animation for the LIVE indicator
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingDot({
    required this.color,
    required this.size,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.5),
                blurRadius: widget.size,
                spreadRadius: widget.size / 4 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
