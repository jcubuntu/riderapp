import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/emergency_remote_datasource.dart';
import '../../data/repositories/emergency_repository_impl.dart';
import '../../domain/repositories/emergency_repository.dart';
import 'emergency_state.dart';

/// Provider for EmergencyRepository
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final apiClient = ApiClient();
  final dataSource = EmergencyRemoteDataSource(apiClient);
  return EmergencyRepositoryImpl(dataSource);
});

/// Provider for emergency contacts state
final emergencyContactsProvider =
    StateNotifierProvider<EmergencyContactsNotifier, EmergencyContactsState>(
        (ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return EmergencyContactsNotifier(repository);
});

/// Provider for SOS state
final sosProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return SosNotifier(repository);
});

/// Notifier for emergency contacts
class EmergencyContactsNotifier extends StateNotifier<EmergencyContactsState> {
  final EmergencyRepository _repository;

  EmergencyContactsNotifier(this._repository)
      : super(const EmergencyContactsInitial());

  /// Load emergency contacts
  Future<void> loadContacts({bool refresh = false}) async {
    if (!refresh && state is EmergencyContactsLoaded) return;

    state = const EmergencyContactsLoading();

    try {
      final contacts = await _repository.getEmergencyContacts();
      state = EmergencyContactsLoaded(contacts);
    } catch (e) {
      state = EmergencyContactsError(e.toString());
    }
  }
}

/// Notifier for SOS
class SosNotifier extends StateNotifier<SosState> {
  final EmergencyRepository _repository;

  SosNotifier(this._repository) : super(const SosInitial()) {
    checkStatus();
  }

  /// Check current SOS status
  Future<void> checkStatus() async {
    state = const SosLoading();

    try {
      final alert = await _repository.getSosStatus();
      if (alert != null && alert.isActive) {
        state = SosActive(alert);
      } else {
        state = const SosInactive();
      }
    } catch (e) {
      state = const SosInactive();
    }
  }

  /// Trigger SOS alert
  Future<void> triggerSos({
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? notes,
  }) async {
    state = const SosTriggering();

    try {
      final alert = await _repository.triggerSos(
        latitude: latitude,
        longitude: longitude,
        locationAddress: locationAddress,
        notes: notes,
      );
      state = SosActive(alert);
    } catch (e) {
      state = SosError(e.toString());
    }
  }

  /// Cancel SOS alert
  Future<void> cancelSos() async {
    final currentState = state;
    if (currentState is! SosActive) return;

    state = SosCancelling(currentState.alert);

    try {
      await _repository.cancelSos();
      state = const SosInactive();
    } catch (e) {
      state = SosActive(currentState.alert);
      rethrow;
    }
  }
}
