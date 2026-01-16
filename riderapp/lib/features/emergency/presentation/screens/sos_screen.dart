import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/emergency_provider.dart';
import '../providers/emergency_state.dart';
import '../widgets/sos_button.dart';

/// Screen for SOS emergency alert
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  Position? _currentPosition;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isGettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sosProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _getBackgroundColor(state, theme),
      appBar: AppBar(
        backgroundColor: _isActiveState(state) ? Colors.red.shade900 : Colors.red,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('emergency.sos.title'.tr()),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SOS Button
              SosButton(
                isActive: _isActiveState(state),
                isLoading: state is SosLoading ||
                    state is SosTriggering ||
                    state is SosCancelling,
                onTrigger: _triggerSos,
                onCancel: _cancelSos,
              ),

              const SizedBox(height: 48),

              // Location status
              if (!_isActiveState(state)) _buildLocationStatus(theme),

              // Status message
              if (state is SosError)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Active state info
              if (state is SosActive) _buildActiveInfo(state, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStatus(ThemeData theme) {
    if (_isGettingLocation) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'emergency.sos.gettingLocation'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (_currentPosition != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 18,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'emergency.sos.locationReady'.tr(),
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _getCurrentLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 18,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'emergency.sos.tapToEnableLocation'.tr(),
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveInfo(SosActive state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          if (state.alert.hasLocation) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  'emergency.sos.shareLocation'.tr(),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Triggered at ${DateFormat('HH:mm').format(state.alert.triggeredAt)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(SosState state, ThemeData theme) {
    if (_isActiveState(state)) {
      return Colors.red.shade900;
    }
    return theme.scaffoldBackgroundColor;
  }

  bool _isActiveState(SosState state) {
    return state is SosActive || state is SosCancelling;
  }

  void _triggerSos() {
    ref.read(sosProvider.notifier).triggerSos(
          latitude: _currentPosition?.latitude,
          longitude: _currentPosition?.longitude,
        );
  }

  void _cancelSos() {
    ref.read(sosProvider.notifier).cancelSos();
  }
}
