import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/user_location.dart';
import '../providers/locations_provider.dart';
import '../providers/locations_state.dart';
import '../widgets/map_markers.dart';
import '../widgets/rider_map.dart';
import '../widgets/user_marker.dart';

/// View mode for the nearby users screen
enum NearbyUsersViewMode {
  list,
  map,
}

/// Screen for viewing nearby users on a map (police+ only)
class NearbyUsersScreen extends ConsumerStatefulWidget {
  /// Whether to show active users (police+ mode) or nearby users (volunteer+ mode)
  final bool showActiveUsers;

  const NearbyUsersScreen({
    super.key,
    this.showActiveUsers = false,
  });

  @override
  ConsumerState<NearbyUsersScreen> createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends ConsumerState<NearbyUsersScreen> {
  double _currentLatitude = 13.7563; // Bangkok default
  double _currentLongitude = 100.5018;
  double _selectedRadius = 5000; // 5km default
  bool _isLoadingLocation = true;
  String? _selectedUserId;
  NearbyUsersViewMode _viewMode = NearbyUsersViewMode.map;
  final GlobalKey<RiderMapState> _mapKey = GlobalKey<RiderMapState>();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _isLoadingLocation = false;
      });

      _loadUsers();
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      _loadUsers();
    }
  }

  void _loadUsers() {
    if (widget.showActiveUsers) {
      ref.read(nearbyUsersProvider.notifier).loadActiveUsers(
            latitude: _currentLatitude,
            longitude: _currentLongitude,
            radius: _selectedRadius,
          );
    } else {
      ref.read(nearbyUsersProvider.notifier).loadNearbyUsers(
            latitude: _currentLatitude,
            longitude: _currentLongitude,
            radius: _selectedRadius,
          );
    }
  }

  void _onUserSelected(UserLocation user) {
    setState(() {
      _selectedUserId = _selectedUserId == user.userId ? null : user.userId;
    });

    // If in map view, center on the selected user
    if (_viewMode == NearbyUsersViewMode.map && _selectedUserId != null) {
      _mapKey.currentState?.animateToPosition(
        LatLng(user.latitude, user.longitude),
        zoom: 16,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyUsersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showActiveUsers
              ? 'locations.activeUsers.title'.tr()
              : 'locations.nearbyUsers.title'.tr(),
        ),
        actions: [
          // View mode toggle
          IconButton(
            icon: Icon(
              _viewMode == NearbyUsersViewMode.map
                  ? Icons.list
                  : Icons.map,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == NearbyUsersViewMode.map
                    ? NearbyUsersViewMode.list
                    : NearbyUsersViewMode.map;
              });
            },
            tooltip: _viewMode == NearbyUsersViewMode.map
                ? 'locations.nearbyUsers.listView'.tr()
                : 'locations.nearbyUsers.mapView'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showRadiusFilter(context),
            tooltip: 'locations.nearbyUsers.filter'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'common.refresh'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(state, theme),

          // Main content area
          Expanded(
            child: _viewMode == NearbyUsersViewMode.map
                ? _buildMapView(state, theme)
                : _buildListView(state, theme),
          ),
        ],
      ),
      floatingActionButton: _viewMode == NearbyUsersViewMode.list
          ? FloatingActionButton(
              onPressed: () async {
                await _initializeLocation();
              },
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }

  Widget _buildStatsBar(NearbyUsersState state, ThemeData theme) {
    if (state is! NearbyUsersLoaded) {
      return const SizedBox.shrink();
    }

    final countByRole = state.countByRole;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${state.users.length} ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'locations.nearbyUsers.usersFound'.tr(),
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          if (countByRole.isNotEmpty)
            ...countByRole.entries.take(3).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildRoleBadge(theme, entry.key, entry.value),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme, String role, int count) {
    final color = RoleMarkerColors.getColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(NearbyUsersState state, ThemeData theme) {
    if (_isLoadingLocation || state is NearbyUsersLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (state is NearbyUsersError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    final users = state is NearbyUsersLoaded ? state.users : <UserLocation>[];
    final currentLocation = LatLng(_currentLatitude, _currentLongitude);

    return Stack(
      children: [
        // Google Map
        RiderMap(
          key: _mapKey,
          userLocations: users,
          currentLocation: currentLocation,
          selectedUserId: _selectedUserId,
          onMarkerTap: _onUserSelected,
          showMyLocationButton: true,
          myLocationEnabled: true,
          circles: {
            RadiusCircle.create(
              center: currentLocation,
              radiusInMeters: _selectedRadius,
            ),
          },
          initialCameraPosition: CameraPosition(
            target: currentLocation,
            zoom: _getZoomForRadius(_selectedRadius),
          ),
        ),

        // Selected user info card
        if (_selectedUserId != null && state is NearbyUsersLoaded)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildSelectedUserCard(
              theme,
              users.firstWhere(
                (u) => u.userId == _selectedUserId,
                orElse: () => users.first,
              ),
            ),
          ),

        // Radius indicator
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radar,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${(_selectedRadius / 1000).toStringAsFixed(1)} km',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Legend
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const MapMarkerLegend(
              horizontal: false,
            ),
          ),
        ),

        // Empty state overlay
        if (users.isEmpty && state is NearbyUsersLoaded)
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'locations.nearbyUsers.noUsers'.tr(),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'locations.nearbyUsers.noUsersDescription'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedUserCard(ThemeData theme, UserLocation user) {
    final distance = user.distanceFrom(_currentLatitude, _currentLongitude);
    final roleColor = RoleMarkerColors.getColor(user.userRole);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserMarker(
              role: user.userRole ?? 'rider',
              size: 56,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.userName ?? 'Unknown User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (user.userRole ?? 'rider').toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: roleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(user.recordedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDistance(distance),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'locations.nearbyUsers.away'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedUserId = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(NearbyUsersState state, ThemeData theme) {
    if (_isLoadingLocation || state is NearbyUsersLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (state is NearbyUsersError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is NearbyUsersLoaded) {
      if (state.users.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'locations.nearbyUsers.noUsers'.tr(),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'locations.nearbyUsers.noUsersDescription'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              final user = state.users[index];
              final isSelected = user.userId == _selectedUserId;

              return UserMarkerListItem(
                location: user,
                isSelected: isSelected,
                onTap: () => _onUserSelected(user),
                currentLatitude: _currentLatitude,
                currentLongitude: _currentLongitude,
              );
            },
          ),

          // Radius indicator
          Positioned(
            bottom: 80,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radar,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(_selectedRadius / 1000).toStringAsFixed(1)} km',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: ElevatedButton(
        onPressed: _loadUsers,
        child: Text('locations.nearbyUsers.load'.tr()),
      ),
    );
  }

  double _getZoomForRadius(double radiusInMeters) {
    // Approximate zoom level based on radius
    if (radiusInMeters <= 1000) return 15;
    if (radiusInMeters <= 2000) return 14;
    if (radiusInMeters <= 5000) return 13;
    if (radiusInMeters <= 10000) return 12;
    if (radiusInMeters <= 20000) return 11;
    if (radiusInMeters <= 50000) return 10;
    return 9;
  }

  void _showRadiusFilter(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'locations.nearbyUsers.selectRadius'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(_selectedRadius / 1000).toStringAsFixed(1)} km',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _selectedRadius,
                    min: 1000,
                    max: 50000,
                    divisions: 49,
                    label: '${(_selectedRadius / 1000).toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setModalState(() {
                        _selectedRadius = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('common.cancel'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                            _loadUsers();
                          },
                          child: Text('common.apply'.tr()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MM/dd HH:mm').format(time);
    }
  }
}

/// List item widget to display user location
class UserMarkerListItem extends StatelessWidget {
  final UserLocation location;
  final bool isSelected;
  final VoidCallback onTap;
  final double currentLatitude;
  final double currentLongitude;

  const UserMarkerListItem({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onTap,
    required this.currentLatitude,
    required this.currentLongitude,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = location.distanceFrom(currentLatitude, currentLongitude);
    final roleColor = RoleMarkerColors.getColor(location.userRole);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserMarker(
                role: location.userRole ?? 'rider',
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.userName ?? 'Unknown User',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildRoleChip(theme, location.userRole ?? 'rider', roleColor),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(location.recordedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDistance(distance),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'locations.nearbyUsers.away'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(ThemeData theme, String role, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MM/dd HH:mm').format(time);
    }
  }
}
