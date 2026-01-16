import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/user_location.dart';
import 'map_markers.dart';

/// Default Bangkok, Thailand coordinates (fallback location)
const kDefaultLatitude = 13.7563;
const kDefaultLongitude = 100.5018;
const kDefaultZoom = 14.0;

/// A reusable Google Maps widget for displaying rider locations
class RiderMap extends StatefulWidget {
  /// List of user locations to display as markers
  final List<UserLocation> userLocations;

  /// Current user's location (will show a special marker)
  final LatLng? currentLocation;

  /// Callback when a marker is tapped
  final void Function(UserLocation user)? onMarkerTap;

  /// Callback when the map is tapped (on empty area)
  final void Function(LatLng position)? onMapTap;

  /// Callback when the map camera moves
  final void Function(CameraPosition position)? onCameraMove;

  /// Callback when map is created
  final void Function(GoogleMapController controller)? onMapCreated;

  /// Initial camera position
  final CameraPosition? initialCameraPosition;

  /// Whether to show zoom controls
  final bool showZoomControls;

  /// Whether to show the my location button
  final bool showMyLocationButton;

  /// Whether to enable my location layer
  final bool myLocationEnabled;

  /// Whether to show compass
  final bool showCompass;

  /// Whether to enable tilt gestures
  final bool tiltGesturesEnabled;

  /// Whether to enable rotate gestures
  final bool rotateGesturesEnabled;

  /// Custom markers to display (in addition to user markers)
  final Set<Marker>? customMarkers;

  /// Custom circles to display (e.g., radius indicator)
  final Set<Circle>? circles;

  /// Custom polylines to display (e.g., routes)
  final Set<Polyline>? polylines;

  /// Selected user ID (for highlighting)
  final String? selectedUserId;

  /// Map type (normal, satellite, hybrid, terrain)
  final MapType mapType;

  /// Padding for the map
  final EdgeInsets padding;

  const RiderMap({
    super.key,
    this.userLocations = const [],
    this.currentLocation,
    this.onMarkerTap,
    this.onMapTap,
    this.onCameraMove,
    this.onMapCreated,
    this.initialCameraPosition,
    this.showZoomControls = true,
    this.showMyLocationButton = true,
    this.myLocationEnabled = false,
    this.showCompass = true,
    this.tiltGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.customMarkers,
    this.circles,
    this.polylines,
    this.selectedUserId,
    this.mapType = MapType.normal,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<RiderMap> createState() => RiderMapState();
}

class RiderMapState extends State<RiderMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  bool _isLoadingMarkers = false;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
  }

  @override
  void didUpdateWidget(RiderMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userLocations != widget.userLocations ||
        oldWidget.selectedUserId != widget.selectedUserId ||
        oldWidget.currentLocation != widget.currentLocation) {
      _updateMarkers();
    }
  }

  Future<void> _loadMarkerIcons() async {
    setState(() {
      _isLoadingMarkers = true;
    });

    // Load marker icons for each role
    final roles = ['rider', 'volunteer', 'police', 'admin', 'super_admin'];
    for (final role in roles) {
      _markerIconCache[role] = await MapMarkerHelper.getMarkerIcon(role);
      _markerIconCache['${role}_selected'] =
          await MapMarkerHelper.getMarkerIcon(role, isSelected: true);
    }

    // Load current location marker
    _markerIconCache['current'] =
        await MapMarkerHelper.getCurrentLocationMarker();

    setState(() {
      _isLoadingMarkers = false;
    });

    _updateMarkers();
  }

  void _updateMarkers() {
    if (_isLoadingMarkers) return;

    final markers = <Marker>{};

    // Add current location marker
    if (widget.currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: widget.currentLocation!,
          icon: _markerIconCache['current'] ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 2,
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
        ),
      );
    }

    // Add user markers
    for (final user in widget.userLocations) {
      final isSelected = user.userId == widget.selectedUserId;
      final role = user.userRole?.toLowerCase() ?? 'rider';
      final iconKey = isSelected ? '${role}_selected' : role;

      markers.add(
        Marker(
          markerId: MarkerId(user.userId),
          position: LatLng(user.latitude, user.longitude),
          icon: _markerIconCache[iconKey] ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 1.0),
          zIndexInt: isSelected ? 1 : 0,
          infoWindow: InfoWindow(
            title: user.userName ?? 'Unknown User',
            snippet: _formatRole(role),
          ),
          onTap: () {
            widget.onMarkerTap?.call(user);
          },
        ),
      );
    }

    // Add custom markers
    if (widget.customMarkers != null) {
      markers.addAll(widget.customMarkers!);
    }

    setState(() {
      _markers = markers;
    });
  }

  String _formatRole(String role) {
    switch (role) {
      case 'rider':
        return 'Rider';
      case 'volunteer':
        return 'Volunteer';
      case 'police':
        return 'Police';
      case 'admin':
        return 'Admin';
      case 'super_admin':
        return 'Super Admin';
      default:
        return role;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    widget.onMapCreated?.call(controller);
  }

  /// Animate camera to a specific position
  Future<void> animateToPosition(LatLng position, {double? zoom}) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(position, zoom ?? kDefaultZoom),
    );
  }

  /// Animate camera to fit all markers
  Future<void> fitAllMarkers({EdgeInsets padding = const EdgeInsets.all(50)}) async {
    if (widget.userLocations.isEmpty && widget.currentLocation == null) return;

    final bounds = _calculateBounds();
    if (bounds != null) {
      await _controller?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  /// Move to current location
  Future<void> moveToCurrentLocation() async {
    if (widget.currentLocation != null) {
      await animateToPosition(widget.currentLocation!);
    }
  }

  LatLngBounds? _calculateBounds() {
    final points = <LatLng>[];

    if (widget.currentLocation != null) {
      points.add(widget.currentLocation!);
    }

    for (final user in widget.userLocations) {
      points.add(LatLng(user.latitude, user.longitude));
    }

    if (points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add some padding
    const padding = 0.01;
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.initialCameraPosition ??
        CameraPosition(
          target: widget.currentLocation ??
              const LatLng(kDefaultLatitude, kDefaultLongitude),
          zoom: kDefaultZoom,
        );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: initialPosition,
          markers: _markers,
          circles: widget.circles ?? {},
          polylines: widget.polylines ?? {},
          mapType: widget.mapType,
          myLocationEnabled: widget.myLocationEnabled,
          myLocationButtonEnabled: false, // We'll use custom button
          zoomControlsEnabled: false, // We'll use custom controls
          compassEnabled: widget.showCompass,
          tiltGesturesEnabled: widget.tiltGesturesEnabled,
          rotateGesturesEnabled: widget.rotateGesturesEnabled,
          padding: widget.padding,
          onMapCreated: _onMapCreated,
          onTap: widget.onMapTap,
          onCameraMove: widget.onCameraMove,
        ),
        // Custom zoom controls
        if (widget.showZoomControls)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildZoomButton(
                  icon: Icons.add,
                  onPressed: () {
                    _controller?.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const SizedBox(height: 8),
                _buildZoomButton(
                  icon: Icons.remove,
                  onPressed: () {
                    _controller?.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
              ],
            ),
          ),
        // Custom my location button
        if (widget.showMyLocationButton && widget.currentLocation != null)
          Positioned(
            right: 16,
            bottom: 180,
            child: _buildZoomButton(
              icon: Icons.my_location,
              onPressed: moveToCurrentLocation,
            ),
          ),
        // Loading indicator
        if (_isLoadingMarkers)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 24,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple map widget for displaying a single location
class SimpleLocationMap extends StatelessWidget {
  /// The location to display
  final LatLng location;

  /// Height of the map
  final double height;

  /// Whether the map is interactive
  final bool interactive;

  /// Zoom level
  final double zoom;

  const SimpleLocationMap({
    super.key,
    required this.location,
    this.height = 200,
    this.interactive = false,
    this.zoom = 15,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: location,
            zoom: zoom,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('location'),
              position: location,
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          scrollGesturesEnabled: interactive,
          zoomGesturesEnabled: interactive,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          liteModeEnabled: !interactive,
        ),
      ),
    );
  }
}
