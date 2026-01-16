import 'package:equatable/equatable.dart';

import '../../domain/entities/emergency_contact.dart';
import '../../domain/entities/sos_alert.dart';

/// Base state for emergency contacts
sealed class EmergencyContactsState extends Equatable {
  const EmergencyContactsState();

  @override
  List<Object?> get props => [];
}

class EmergencyContactsInitial extends EmergencyContactsState {
  const EmergencyContactsInitial();
}

class EmergencyContactsLoading extends EmergencyContactsState {
  const EmergencyContactsLoading();
}

class EmergencyContactsLoaded extends EmergencyContactsState {
  final List<EmergencyContact> contacts;

  const EmergencyContactsLoaded(this.contacts);

  /// Get contacts grouped by category
  Map<EmergencyContactCategory, List<EmergencyContact>> get groupedContacts {
    final grouped = <EmergencyContactCategory, List<EmergencyContact>>{};
    for (final contact in contacts) {
      grouped.putIfAbsent(contact.category, () => []).add(contact);
    }
    return grouped;
  }

  /// Get default contacts
  List<EmergencyContact> get defaultContacts =>
      contacts.where((c) => c.isDefault).toList();

  @override
  List<Object?> get props => [contacts];
}

class EmergencyContactsError extends EmergencyContactsState {
  final String message;

  const EmergencyContactsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Base state for SOS
sealed class SosState extends Equatable {
  const SosState();

  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {
  const SosInitial();
}

class SosLoading extends SosState {
  const SosLoading();
}

class SosInactive extends SosState {
  const SosInactive();
}

class SosActive extends SosState {
  final SosAlert alert;

  const SosActive(this.alert);

  @override
  List<Object?> get props => [alert];
}

class SosTriggering extends SosState {
  const SosTriggering();
}

class SosCancelling extends SosState {
  final SosAlert alert;

  const SosCancelling(this.alert);

  @override
  List<Object?> get props => [alert];
}

class SosError extends SosState {
  final String message;

  const SosError(this.message);

  @override
  List<Object?> get props => [message];
}
