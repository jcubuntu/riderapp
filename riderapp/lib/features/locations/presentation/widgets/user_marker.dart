import 'package:flutter/material.dart';

/// A widget that displays a user marker icon based on their role
class UserMarker extends StatelessWidget {
  /// The user's role (rider, volunteer, police, admin, super_admin)
  final String role;

  /// Size of the marker
  final double size;

  /// Whether to show a pulse animation (for active users)
  final bool showPulse;

  const UserMarker({
    super.key,
    required this.role,
    this.size = 40,
    this.showPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);
    final icon = _getRoleIcon(role);

    if (showPulse) {
      return _PulsingMarker(
        color: color,
        icon: icon,
        size: size,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'rider':
        return Colors.blue;
      case 'volunteer':
        return Colors.orange;
      case 'police':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      case 'super_admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
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

/// A pulsing marker animation widget
class _PulsingMarker extends StatefulWidget {
  final Color color;
  final IconData icon;
  final double size;

  const _PulsingMarker({
    required this.color,
    required this.icon,
    required this.size,
  });

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
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
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            Container(
              width: widget.size * _animation.value,
              height: widget.size * _animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            // Main marker
            Container(
              width: widget.size * 0.8,
              height: widget.size * 0.8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: widget.size * 0.4,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A custom map marker pin widget
class MapMarkerPin extends StatelessWidget {
  /// The user's role
  final String role;

  /// Size of the marker
  final double size;

  /// Whether the marker is selected
  final bool isSelected;

  /// Callback when marker is tapped
  final VoidCallback? onTap;

  const MapMarkerPin({
    super.key,
    required this.role,
    this.size = 50,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);
    final icon = _getRoleIcon(role);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size * 1.3,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Pin shape
            CustomPaint(
              size: Size(size, size * 1.3),
              painter: _PinPainter(
                color: isSelected ? color : color.withValues(alpha: 0.8),
                isSelected: isSelected,
              ),
            ),
            // Icon
            Positioned(
              top: size * 0.15,
              child: Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: size * 0.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'rider':
        return Colors.blue;
      case 'volunteer':
        return Colors.orange;
      case 'police':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      case 'super_admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
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

/// Custom painter for pin shape
class _PinPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  _PinPainter({
    required this.color,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final centerX = size.width / 2;
    final radius = size.width / 2;
    final pointY = size.height;

    // Draw shadow
    final shadowPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(centerX, radius),
        width: radius * 2,
        height: radius * 2,
      ))
      ..moveTo(centerX - radius * 0.5, radius)
      ..lineTo(centerX, pointY)
      ..lineTo(centerX + radius * 0.5, radius);
    canvas.drawPath(shadowPath.shift(const Offset(2, 2)), shadowPaint);

    // Draw pin body
    path.addOval(Rect.fromCenter(
      center: Offset(centerX, radius),
      width: radius * 2,
      height: radius * 2,
    ));
    path.moveTo(centerX - radius * 0.5, radius);
    path.lineTo(centerX, pointY);
    path.lineTo(centerX + radius * 0.5, radius);
    canvas.drawPath(path, paint);

    // Draw border if selected
    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isSelected != isSelected;
  }
}
