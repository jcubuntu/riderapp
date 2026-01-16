import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper class for creating custom map markers
class MapMarkerHelper {
  MapMarkerHelper._();

  /// Cache for marker icons
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Get marker icon for a specific role
  static Future<BitmapDescriptor> getMarkerIcon(
    String role, {
    bool isSelected = false,
    double size = 80,
  }) async {
    final cacheKey = '${role}_${isSelected}_$size';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final icon = await _createMarkerIcon(
      role: role,
      isSelected: isSelected,
      size: size,
    );

    _cache[cacheKey] = icon;
    return icon;
  }

  /// Get current location marker
  static Future<BitmapDescriptor> getCurrentLocationMarker({
    double size = 60,
  }) async {
    const cacheKey = 'current_location';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final icon = await _createCurrentLocationMarker(size: size);
    _cache[cacheKey] = icon;
    return icon;
  }

  /// Clear the marker cache
  static void clearCache() {
    _cache.clear();
  }

  static Future<BitmapDescriptor> _createMarkerIcon({
    required String role,
    required bool isSelected,
    required double size,
  }) async {
    final color = _getRoleColor(role);
    final icon = _getRoleIconData(role);

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final pinHeight = size * 1.3;
    final pinWidth = size;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowPath = Path();
    final shadowCenterX = pinWidth / 2 + 2;
    final shadowRadius = pinWidth / 2 - 4;
    shadowPath.addOval(Rect.fromCircle(
      center: Offset(shadowCenterX, shadowRadius + 2),
      radius: shadowRadius,
    ));
    shadowPath.moveTo(shadowCenterX - shadowRadius * 0.4, shadowRadius + 2);
    shadowPath.lineTo(shadowCenterX, pinHeight - 4);
    shadowPath.lineTo(shadowCenterX + shadowRadius * 0.4, shadowRadius + 2);
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw pin body
    final pinPaint = Paint()
      ..color = isSelected ? color : color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    final centerX = pinWidth / 2;
    final radius = pinWidth / 2 - 4;
    pinPath.addOval(Rect.fromCircle(
      center: Offset(centerX, radius + 2),
      radius: radius,
    ));
    pinPath.moveTo(centerX - radius * 0.4, radius + 2);
    pinPath.lineTo(centerX, pinHeight - 8);
    pinPath.lineTo(centerX + radius * 0.4, radius + 2);
    canvas.drawPath(pinPath, pinPaint);

    // Draw border if selected
    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(pinPath, borderPaint);
    }

    // Draw white circle background for icon
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX, radius + 2),
      radius * 0.65,
      circlePaint,
    );

    // Draw icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: radius * 0.8,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        centerX - iconPainter.width / 2,
        radius + 2 - iconPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(pinWidth.toInt(), pinHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _createCurrentLocationMarker({
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Outer pulsing circle (static for the icon)
    final outerPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      outerPaint,
    );

    // Middle ring
    final middlePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 3,
      middlePaint,
    );

    // Inner solid circle
    final innerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 5,
      innerPaint,
    );

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 5,
      borderPaint,
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Get the color for a specific role
  static Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'rider':
        return const Color(0xFF2196F3); // Blue
      case 'volunteer':
        return const Color(0xFFFF9800); // Orange
      case 'police':
        return const Color(0xFF4CAF50); // Green
      case 'admin':
        return const Color(0xFF9C27B0); // Purple
      case 'super_admin':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get the icon data for a specific role
  static IconData _getRoleIconData(String role) {
    switch (role.toLowerCase()) {
      case 'rider':
        return Icons.two_wheeler;
      case 'volunteer':
        return Icons.volunteer_activism;
      case 'police':
        return Icons.local_police;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'super_admin':
        return Icons.security;
      default:
        return Icons.person;
    }
  }
}

/// Role-based marker colors for UI components
class RoleMarkerColors {
  RoleMarkerColors._();

  static const Color rider = Color(0xFF2196F3);
  static const Color volunteer = Color(0xFFFF9800);
  static const Color police = Color(0xFF4CAF50);
  static const Color admin = Color(0xFF9C27B0);
  static const Color superAdmin = Color(0xFFF44336);
  static const Color unknown = Color(0xFF9E9E9E);

  /// Get color for a role
  static Color getColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'rider':
        return rider;
      case 'volunteer':
        return volunteer;
      case 'police':
        return police;
      case 'admin':
        return admin;
      case 'super_admin':
        return superAdmin;
      default:
        return unknown;
    }
  }
}

/// Widget to display a legend for map markers
class MapMarkerLegend extends StatelessWidget {
  /// Roles to display in the legend
  final List<String> roles;

  /// Whether to display horizontally
  final bool horizontal;

  const MapMarkerLegend({
    super.key,
    this.roles = const ['rider', 'volunteer', 'police', 'admin'],
    this.horizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = roles.map((role) {
      return _LegendItem(
        color: RoleMarkerColors.getColor(role),
        label: _formatRole(role),
      );
    }).toList();

    if (horizontal) {
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: items,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: item,
      )).toList(),
    );
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
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
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Widget to display a radius circle on the map
class RadiusCircle {
  /// Create a circle for displaying a radius on the map
  static Circle create({
    required LatLng center,
    required double radiusInMeters,
    Color fillColor = const Color(0x1A2196F3),
    Color strokeColor = const Color(0x662196F3),
    double strokeWidth = 2,
    String circleId = 'radius_circle',
  }) {
    return Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: radiusInMeters,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth.toInt(),
    );
  }
}
