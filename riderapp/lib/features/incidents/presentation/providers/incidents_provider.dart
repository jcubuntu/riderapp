import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/incidents_remote_datasource.dart';
import '../../data/repositories/incidents_repository_impl.dart';
import '../../domain/entities/incident.dart';
import '../../domain/repositories/incidents_repository.dart';
import 'incidents_state.dart';

/// Repository provider
final incidentsRepositoryProvider = Provider<IIncidentsRepository>((ref) {
  return IncidentsRepositoryImpl();
});

/// All incidents list provider (for volunteer+ roles)
final incidentsListProvider =
    StateNotifierProvider<IncidentsListNotifier, IncidentsListState>((ref) {
  final repository = ref.watch(incidentsRepositoryProvider);
  return IncidentsListNotifier(repository, isMyIncidents: false);
});

/// My incidents list provider (for all authenticated users)
final myIncidentsListProvider =
    StateNotifierProvider<IncidentsListNotifier, IncidentsListState>((ref) {
  final repository = ref.watch(incidentsRepositoryProvider);
  return IncidentsListNotifier(repository, isMyIncidents: true);
});

/// Single incident detail provider
final incidentDetailProvider = StateNotifierProvider.family<
    IncidentDetailNotifier, IncidentDetailState, String>((ref, incidentId) {
  final repository = ref.watch(incidentsRepositoryProvider);
  return IncidentDetailNotifier(repository, incidentId);
});

/// Create/Edit incident provider
final createIncidentProvider =
    StateNotifierProvider<CreateIncidentNotifier, CreateIncidentState>((ref) {
  final repository = ref.watch(incidentsRepositoryProvider);
  return CreateIncidentNotifier(repository);
});

/// Incident statistics provider
final incidentStatsProvider =
    StateNotifierProvider<IncidentStatsNotifier, IncidentStatsState>((ref) {
  final repository = ref.watch(incidentsRepositoryProvider);
  return IncidentStatsNotifier(repository);
});

/// Notifier for incidents list (all or my incidents)
class IncidentsListNotifier extends StateNotifier<IncidentsListState> {
  final IIncidentsRepository _repository;
  final bool isMyIncidents;

  IncidentsListNotifier(this._repository, {required this.isMyIncidents})
      : super(const IncidentsListInitial());

  /// Load incidents
  Future<void> loadIncidents({
    int page = 1,
    int limit = 10,
    String? search,
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? province,
    String? assignedTo,
    String? reportedBy,
  }) async {
    state = const IncidentsListLoading();

    try {
      final PaginatedIncidents result;

      if (isMyIncidents) {
        result = await _repository.getMyIncidents(
          page: page,
          limit: limit,
          search: search,
          category: category,
          status: status,
          priority: priority,
        );
      } else {
        result = await _repository.getIncidents(
          page: page,
          limit: limit,
          search: search,
          category: category,
          status: status,
          priority: priority,
          province: province,
          assignedTo: assignedTo,
          reportedBy: reportedBy,
        );
      }

      state = IncidentsListLoaded(
        incidents: result.incidents,
        total: result.total,
        page: result.page,
        limit: result.limit,
        totalPages: result.totalPages,
        filterCategory: category,
        filterStatus: status,
        filterPriority: priority,
        searchQuery: search,
      );
    } on IncidentsException catch (e) {
      state = IncidentsListError(e.message);
    } catch (e) {
      state = IncidentsListError(e.toString());
    }
  }

  /// Load more incidents (pagination)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! IncidentsListLoaded || !currentState.hasNextPage) {
      return;
    }

    state = currentState.copyWith(isLoadingMore: true);

    try {
      final PaginatedIncidents result;

      if (isMyIncidents) {
        result = await _repository.getMyIncidents(
          page: currentState.page + 1,
          limit: currentState.limit,
          search: currentState.searchQuery,
          category: currentState.filterCategory,
          status: currentState.filterStatus,
          priority: currentState.filterPriority,
        );
      } else {
        result = await _repository.getIncidents(
          page: currentState.page + 1,
          limit: currentState.limit,
          search: currentState.searchQuery,
          category: currentState.filterCategory,
          status: currentState.filterStatus,
          priority: currentState.filterPriority,
        );
      }

      state = currentState.copyWith(
        incidents: [...currentState.incidents, ...result.incidents],
        page: result.page,
        total: result.total,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } on IncidentsException {
      state = currentState.copyWith(isLoadingMore: false);
      // Could optionally show an error snackbar here
      rethrow;
    } catch (e) {
      state = currentState.copyWith(isLoadingMore: false);
      rethrow;
    }
  }

  /// Refresh incidents
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is IncidentsListLoaded) {
      await loadIncidents(
        search: currentState.searchQuery,
        category: currentState.filterCategory,
        status: currentState.filterStatus,
        priority: currentState.filterPriority,
        limit: currentState.limit,
      );
    } else {
      await loadIncidents();
    }
  }

  /// Apply filters
  Future<void> applyFilters({
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? search,
  }) async {
    await loadIncidents(
      search: search,
      category: category,
      status: status,
      priority: priority,
    );
  }

  /// Clear filters
  Future<void> clearFilters() async {
    await loadIncidents();
  }

  /// Update incident in list (after edit)
  void updateIncidentInList(Incident updatedIncident) {
    final currentState = state;
    if (currentState is IncidentsListLoaded) {
      final updatedList = currentState.incidents.map((incident) {
        return incident.id == updatedIncident.id ? updatedIncident : incident;
      }).toList();

      state = currentState.copyWith(incidents: updatedList);
    }
  }

  /// Remove incident from list (after delete)
  void removeIncidentFromList(String incidentId) {
    final currentState = state;
    if (currentState is IncidentsListLoaded) {
      final updatedList = currentState.incidents
          .where((incident) => incident.id != incidentId)
          .toList();

      state = currentState.copyWith(
        incidents: updatedList,
        total: currentState.total - 1,
      );
    }
  }

  /// Add incident to list (after create)
  void addIncidentToList(Incident incident) {
    final currentState = state;
    if (currentState is IncidentsListLoaded) {
      state = currentState.copyWith(
        incidents: [incident, ...currentState.incidents],
        total: currentState.total + 1,
      );
    }
  }
}

/// Notifier for single incident detail
class IncidentDetailNotifier extends StateNotifier<IncidentDetailState> {
  final IIncidentsRepository _repository;
  final String incidentId;

  IncidentDetailNotifier(this._repository, this.incidentId)
      : super(const IncidentDetailInitial()) {
    loadIncident();
  }

  /// Load incident detail
  Future<void> loadIncident() async {
    state = const IncidentDetailLoading();

    try {
      final incident = await _repository.getIncidentById(incidentId);
      state = IncidentDetailLoaded(incident: incident);
    } on IncidentsException catch (e) {
      state = IncidentDetailError(e.message);
    } catch (e) {
      state = IncidentDetailError(e.toString());
    }
  }

  /// Refresh incident
  Future<void> refresh() async {
    await loadIncident();
  }

  /// Update incident status
  Future<void> updateStatus(IncidentStatus status, {String? notes}) async {
    final currentState = state;
    if (currentState is! IncidentDetailLoaded) return;

    state = currentState.copyWith(isUpdating: true);

    try {
      final updatedIncident = await _repository.updateIncidentStatus(
        incidentId,
        status: status,
        notes: notes,
      );
      state = IncidentDetailLoaded(incident: updatedIncident);
    } on IncidentsException {
      state = currentState.copyWith(isUpdating: false);
      rethrow;
    } catch (e) {
      state = currentState.copyWith(isUpdating: false);
      rethrow;
    }
  }

  /// Assign incident
  Future<void> assignIncident(String assigneeId) async {
    final currentState = state;
    if (currentState is! IncidentDetailLoaded) return;

    state = currentState.copyWith(isUpdating: true);

    try {
      final updatedIncident = await _repository.assignIncident(
        incidentId,
        assigneeId: assigneeId,
      );
      state = IncidentDetailLoaded(incident: updatedIncident);
    } on IncidentsException {
      state = currentState.copyWith(isUpdating: false);
      rethrow;
    } catch (e) {
      state = currentState.copyWith(isUpdating: false);
      rethrow;
    }
  }

  /// Delete incident
  Future<void> deleteIncident() async {
    final currentState = state;
    if (currentState is! IncidentDetailLoaded) return;

    state = currentState.copyWith(isUpdating: true);

    try {
      await _repository.deleteIncident(incidentId);
      // State will be handled by navigation (pop screen)
    } on IncidentsException {
      state = currentState.copyWith(isUpdating: false);
      rethrow;
    } catch (e) {
      state = currentState.copyWith(isUpdating: false);
      rethrow;
    }
  }
}

/// Notifier for creating/editing incidents
class CreateIncidentNotifier extends StateNotifier<CreateIncidentState> {
  final IIncidentsRepository _repository;

  CreateIncidentNotifier(this._repository)
      : super(const CreateIncidentInitial());

  /// Create a new incident
  Future<void> createIncident({
    required String title,
    required String description,
    IncidentCategory category = IncidentCategory.general,
    IncidentPriority priority = IncidentPriority.medium,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
    String? locationProvince,
    String? locationDistrict,
    DateTime? incidentDate,
    bool isAnonymous = false,
  }) async {
    state = const CreateIncidentLoading();

    try {
      final incident = await _repository.createIncident(
        title: title,
        description: description,
        category: category,
        priority: priority,
        locationLat: locationLat,
        locationLng: locationLng,
        locationAddress: locationAddress,
        locationProvince: locationProvince,
        locationDistrict: locationDistrict,
        incidentDate: incidentDate,
        isAnonymous: isAnonymous,
      );

      state = CreateIncidentSuccess(incident: incident, isUpdate: false);
    } on IncidentsException catch (e) {
      state = CreateIncidentError(e.message);
    } catch (e) {
      state = CreateIncidentError(e.toString());
    }
  }

  /// Update an existing incident
  Future<void> updateIncident(
    String id, {
    String? title,
    String? description,
    IncidentCategory? category,
    IncidentPriority? priority,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
    String? locationProvince,
    String? locationDistrict,
    DateTime? incidentDate,
    bool? isAnonymous,
  }) async {
    state = const CreateIncidentLoading();

    try {
      final incident = await _repository.updateIncident(
        id,
        title: title,
        description: description,
        category: category,
        priority: priority,
        locationLat: locationLat,
        locationLng: locationLng,
        locationAddress: locationAddress,
        locationProvince: locationProvince,
        locationDistrict: locationDistrict,
        incidentDate: incidentDate,
        isAnonymous: isAnonymous,
      );

      state = CreateIncidentSuccess(incident: incident, isUpdate: true);
    } on IncidentsException catch (e) {
      state = CreateIncidentError(e.message);
    } catch (e) {
      state = CreateIncidentError(e.toString());
    }
  }

  /// Reset state
  void reset() {
    state = const CreateIncidentInitial();
  }
}

/// Notifier for incident statistics
class IncidentStatsNotifier extends StateNotifier<IncidentStatsState> {
  final IIncidentsRepository _repository;

  IncidentStatsNotifier(this._repository)
      : super(const IncidentStatsInitial());

  /// Load statistics
  Future<void> loadStats() async {
    state = const IncidentStatsLoading();

    try {
      final stats = await _repository.getIncidentStats();
      state = IncidentStatsLoaded(stats: stats);
    } on IncidentsException catch (e) {
      state = IncidentStatsError(e.message);
    } catch (e) {
      state = IncidentStatsError(e.toString());
    }
  }

  /// Refresh statistics
  Future<void> refresh() async {
    await loadStats();
  }
}

// ============================================================================
// ATTACHMENT MANAGEMENT
// ============================================================================

/// State for managing pending attachments during incident creation
class PendingAttachmentsState {
  final List<File> pendingFiles;
  final AttachmentUploadState uploadState;

  const PendingAttachmentsState({
    this.pendingFiles = const [],
    this.uploadState = const AttachmentUploadInitial(),
  });

  PendingAttachmentsState copyWith({
    List<File>? pendingFiles,
    AttachmentUploadState? uploadState,
  }) {
    return PendingAttachmentsState(
      pendingFiles: pendingFiles ?? this.pendingFiles,
      uploadState: uploadState ?? this.uploadState,
    );
  }

  bool get hasFiles => pendingFiles.isNotEmpty;
  int get fileCount => pendingFiles.length;
}

/// Notifier for managing pending attachments during incident creation
class PendingAttachmentsNotifier extends StateNotifier<PendingAttachmentsState> {
  PendingAttachmentsNotifier() : super(const PendingAttachmentsState());

  /// Maximum number of attachments allowed
  static const int maxAttachments = 5;

  /// Add files to pending list
  void addFiles(List<File> files) {
    final currentCount = state.pendingFiles.length;
    final allowedCount = maxAttachments - currentCount;
    if (allowedCount <= 0) return;

    final filesToAdd = files.take(allowedCount).toList();
    state = state.copyWith(
      pendingFiles: [...state.pendingFiles, ...filesToAdd],
    );
  }

  /// Remove a file from pending list
  void removeFile(File file) {
    state = state.copyWith(
      pendingFiles: state.pendingFiles.where((f) => f.path != file.path).toList(),
    );
  }

  /// Remove file at index
  void removeFileAt(int index) {
    if (index < 0 || index >= state.pendingFiles.length) return;
    final newFiles = List<File>.from(state.pendingFiles);
    newFiles.removeAt(index);
    state = state.copyWith(pendingFiles: newFiles);
  }

  /// Clear all pending files
  void clearFiles() {
    state = state.copyWith(pendingFiles: []);
  }

  /// Reset to initial state
  void reset() {
    state = const PendingAttachmentsState();
  }

  /// Check if can add more files
  bool get canAddMore => state.pendingFiles.length < maxAttachments;

  /// Get remaining slots
  int get remainingSlots => maxAttachments - state.pendingFiles.length;
}

/// Provider for pending attachments during incident creation
final pendingAttachmentsProvider =
    StateNotifierProvider<PendingAttachmentsNotifier, PendingAttachmentsState>(
        (ref) {
  return PendingAttachmentsNotifier();
});

/// Notifier for attachment upload operations
class AttachmentUploadNotifier extends StateNotifier<AttachmentUploadState> {
  final IIncidentsRepository _repository;

  AttachmentUploadNotifier(this._repository)
      : super(const AttachmentUploadInitial());

  /// Upload attachments to an incident
  Future<List<IncidentAttachment>?> uploadAttachments(
    String incidentId,
    List<File> files, {
    String? description,
  }) async {
    if (files.isEmpty) return null;

    state = const AttachmentUploadLoading(progress: 0);

    try {
      final filePaths = files.map((f) => f.path).toList();
      final attachments = await _repository.uploadAttachments(
        incidentId,
        filePaths: filePaths,
        description: description,
      );

      state = AttachmentUploadSuccess(attachments: attachments);
      return attachments;
    } on IncidentsException catch (e) {
      state = AttachmentUploadError(e.message);
      return null;
    } catch (e) {
      state = AttachmentUploadError(e.toString());
      return null;
    }
  }

  /// Delete an attachment from an incident
  Future<bool> deleteAttachment(String incidentId, String attachmentId) async {
    try {
      await _repository.deleteAttachment(incidentId, attachmentId);
      return true;
    } on IncidentsException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const AttachmentUploadInitial();
  }
}

/// Provider for attachment upload operations
final attachmentUploadProvider =
    StateNotifierProvider<AttachmentUploadNotifier, AttachmentUploadState>(
        (ref) {
  final repository = ref.watch(incidentsRepositoryProvider);
  return AttachmentUploadNotifier(repository);
});

/// Provider to get attachments for a specific incident
final incidentAttachmentsProvider =
    FutureProvider.family<List<IncidentAttachment>, String>(
        (ref, incidentId) async {
  final repository = ref.watch(incidentsRepositoryProvider);
  return repository.getAttachments(incidentId);
});
