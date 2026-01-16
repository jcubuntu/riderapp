import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Large SOS button widget with hold-to-activate functionality
class SosButton extends StatefulWidget {
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTrigger;
  final VoidCallback onCancel;

  const SosButton({
    super.key,
    this.isActive = false,
    this.isLoading = false,
    required this.onTrigger,
    required this.onCancel,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  bool _isHolding = false;

  static const _holdDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _holdDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isHolding) {
        HapticFeedback.heavyImpact();
        widget.onTrigger();
        _isHolding = false;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isActive || widget.isLoading) return;

    setState(() => _isHolding = true);
    HapticFeedback.mediumImpact();
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isHolding) return;

    setState(() => _isHolding = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    if (!_isHolding) return;

    setState(() => _isHolding = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.5;

    if (widget.isActive) {
      return _buildActiveState(size);
    }

    return _buildInactiveState(size);
  }

  Widget _buildInactiveState(double size) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring
                  if (_isHolding)
                    SizedBox(
                      width: size,
                      height: size,
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 8,
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),

                  // Main button
                  Container(
                    width: size - 20,
                    height: size - 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: widget.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'emergency.sos.activate'.tr(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveState(double size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing active indicator
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.1),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'emergency.sos.active'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'emergency.sos.helpOnWay'.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // Cancel button
        if (!widget.isLoading)
          OutlinedButton.icon(
            onPressed: () => _showCancelConfirmation(context),
            icon: const Icon(Icons.close),
            label: Text('emergency.sos.cancel'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('emergency.sos.cancel'.tr()),
        content: Text('emergency.sos.cancelConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.no'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('common.yes'.tr()),
          ),
        ],
      ),
    );
  }
}
