import 'package:equatable/equatable.dart';

import '../../domain/entities/incident.dart';

/// Incidents list states
sealed class IncidentsListState extends Equatable {
  const IncidentsListState();

  @override
  List<Object?> get props => [];
}

/// Initial state - not loaded yet
class IncidentsListInitial extends IncidentsListState {
  const IncidentsListInitial();
}

/// Loading state - fetching incidents
class IncidentsListLoading extends IncidentsListState {
  const IncidentsListLoading();
}

/// Loaded state - incidents fetched successfully
class IncidentsListLoaded extends IncidentsListState {
  final List<Incident> incidents;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool isLoadingMore;
  final IncidentCategory? filterCategory;
  final IncidentStatus? filterStatus;
  final IncidentPriority? filterPriority;
  final String? searchQuery;

  const IncidentsListLoaded({
    required this.incidents,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.isLoadingMore = false,
    this.filterCategory,
    this.filterStatus,
    this.filterPriority,
    this.searchQuery,
  });

  bool get hasNextPage => page < totalPages;
  bool get isEmpty => incidents.isEmpty;

  IncidentsListLoaded copyWith({
    List<Incident>? incidents,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    bool? isLoadingMore,
    IncidentCategory? filterCategory,
    IncidentStatus? filterStatus,
    IncidentPriority? filterPriority,
    String? searchQuery,
  }) {
    return IncidentsListLoaded(
      incidents: incidents ?? this.incidents,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterCategory: filterCategory ?? this.filterCategory,
      filterStatus: filterStatus ?? this.filterStatus,
      filterPriority: filterPriority ?? this.filterPriority,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        incidents,
        total,
        page,
        limit,
        totalPages,
        isLoadingMore,
        filterCategory,
        filterStatus,
        filterPriority,
        searchQuery,
      ];
}

/// Error state - failed to fetch incidents
class IncidentsListError extends IncidentsListState {
  final String message;

  const IncidentsListError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Single incident detail states
sealed class IncidentDetailState extends Equatable {
  const IncidentDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state - not loaded yet
class IncidentDetailInitial extends IncidentDetailState {
  const IncidentDetailInitial();
}

/// Loading state - fetching incident detail
class IncidentDetailLoading extends IncidentDetailState {
  const IncidentDetailLoading();
}

/// Loaded state - incident fetched successfully
class IncidentDetailLoaded extends IncidentDetailState {
  final Incident incident;
  final bool isUpdating;

  const IncidentDetailLoaded({
    required this.incident,
    this.isUpdating = false,
  });

  IncidentDetailLoaded copyWith({
    Incident? incident,
    bool? isUpdating,
  }) {
    return IncidentDetailLoaded(
      incident: incident ?? this.incident,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [incident, isUpdating];
}

/// Error state - failed to fetch incident
class IncidentDetailError extends IncidentDetailState {
  final String message;

  const IncidentDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Create/Edit incident states
sealed class CreateIncidentState extends Equatable {
  const CreateIncidentState();

  @override
  List<Object?> get props => [];
}

/// Initial state - ready to create
class CreateIncidentInitial extends CreateIncidentState {
  const CreateIncidentInitial();
}

/// Loading state - creating/updating incident
class CreateIncidentLoading extends CreateIncidentState {
  const CreateIncidentLoading();
}

/// Success state - incident created/updated
class CreateIncidentSuccess extends CreateIncidentState {
  final Incident incident;
  final bool isUpdate;

  const CreateIncidentSuccess({
    required this.incident,
    this.isUpdate = false,
  });

  @override
  List<Object?> get props => [incident, isUpdate];
}

/// Error state - failed to create/update
class CreateIncidentError extends CreateIncidentState {
  final String message;

  const CreateIncidentError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Incident statistics states
sealed class IncidentStatsState extends Equatable {
  const IncidentStatsState();

  @override
  List<Object?> get props => [];
}

/// Initial state - not loaded yet
class IncidentStatsInitial extends IncidentStatsState {
  const IncidentStatsInitial();
}

/// Loading state - fetching statistics
class IncidentStatsLoading extends IncidentStatsState {
  const IncidentStatsLoading();
}

/// Loaded state - statistics fetched successfully
class IncidentStatsLoaded extends IncidentStatsState {
  final IncidentStats stats;

  const IncidentStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

/// Error state - failed to fetch statistics
class IncidentStatsError extends IncidentStatsState {
  final String message;

  const IncidentStatsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Attachment upload states
sealed class AttachmentUploadState extends Equatable {
  const AttachmentUploadState();

  @override
  List<Object?> get props => [];
}

/// Initial state - ready to upload
class AttachmentUploadInitial extends AttachmentUploadState {
  const AttachmentUploadInitial();
}

/// Loading state - uploading attachments
class AttachmentUploadLoading extends AttachmentUploadState {
  final double progress;

  const AttachmentUploadLoading({this.progress = 0});

  @override
  List<Object?> get props => [progress];
}

/// Success state - attachments uploaded
class AttachmentUploadSuccess extends AttachmentUploadState {
  final List<IncidentAttachment> attachments;

  const AttachmentUploadSuccess({required this.attachments});

  @override
  List<Object?> get props => [attachments];
}

/// Error state - failed to upload
class AttachmentUploadError extends AttachmentUploadState {
  final String message;

  const AttachmentUploadError(this.message);

  @override
  List<Object?> get props => [message];
}
