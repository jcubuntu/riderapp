import '../entities/emergency_contact.dart';
import '../entities/sos_alert.dart';

/// Abstract repository interface for emergency features
abstract class EmergencyRepository {
  /// Get list of emergency contacts
  Future<List<EmergencyContact>> getEmergencyContacts();

  /// Trigger SOS alert
  Future<SosAlert> triggerSos({
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? notes,
  });

  /// Cancel SOS alert
  Future<void> cancelSos();

  /// Get current SOS status
  Future<SosAlert?> getSosStatus();
}
