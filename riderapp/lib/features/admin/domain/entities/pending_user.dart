import 'package:equatable/equatable.dart';

import '../../../../shared/models/user_model.dart';

/// Entity representing a user pending approval
class PendingUser extends Equatable {
  final String id;
  final String phone;
  final String fullName;
  final String? idCardNumber;
  final String? affiliation;
  final String? address;
  final UserRole role;
  final UserStatus status;
  final String? profileImageUrl;
  final DateTime createdAt;
  final String? rejectionReason;

  const PendingUser({
    required this.id,
    required this.phone,
    required this.fullName,
    this.idCardNumber,
    this.affiliation,
    this.address,
    required this.role,
    required this.status,
    this.profileImageUrl,
    required this.createdAt,
    this.rejectionReason,
  });

  /// Create from JSON
  factory PendingUser.fromJson(Map<String, dynamic> json) {
    return PendingUser(
      id: json['id'] as String,
      phone: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      idCardNumber: json['id_card_number'] as String? ?? json['idCardNumber'] as String?,
      affiliation: json['affiliation'] as String?,
      address: json['address'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'rider'),
      status: UserStatus.fromString(json['status'] as String? ?? 'pending'),
      profileImageUrl: json['profile_image_url'] as String? ?? json['profileImageUrl'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      rejectionReason: json['rejection_reason'] as String? ?? json['rejectionReason'] as String?,
    );
  }

  /// Convert to UserModel
  UserModel toUserModel() {
    return UserModel(
      id: id,
      phone: phone,
      fullName: fullName,
      idCardNumber: idCardNumber,
      affiliation: affiliation,
      address: address,
      role: role,
      status: status,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
    );
  }

  /// Create from UserModel
  factory PendingUser.fromUserModel(UserModel user) {
    return PendingUser(
      id: user.id,
      phone: user.phone,
      fullName: user.fullName,
      idCardNumber: user.idCardNumber,
      affiliation: user.affiliation,
      address: user.address,
      role: user.role,
      status: user.status,
      profileImageUrl: user.profileImageUrl,
      createdAt: user.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phone,
        fullName,
        idCardNumber,
        affiliation,
        address,
        role,
        status,
        profileImageUrl,
        createdAt,
        rejectionReason,
      ];
}

/// Response model for paginated user list
class PaginatedUsers extends Equatable {
  final List<UserModel> users;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedUsers({
    required this.users,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedUsers.fromJson(Map<String, dynamic> json) {
    final usersList = json['users'] as List<dynamic>? ?? [];
    return PaginatedUsers(
      users: usersList.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  factory PaginatedUsers.empty() {
    return const PaginatedUsers(
      users: [],
      total: 0,
      page: 1,
      limit: 20,
      totalPages: 1,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  @override
  List<Object?> get props => [users, total, page, limit, totalPages];
}

/// Filter options for user list
class UserFilter extends Equatable {
  final UserRole? role;
  final UserStatus? status;
  final String? search;
  final int page;
  final int limit;

  const UserFilter({
    this.role,
    this.status,
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  UserFilter copyWith({
    UserRole? role,
    UserStatus? status,
    String? search,
    int? page,
    int? limit,
    bool clearRole = false,
    bool clearStatus = false,
    bool clearSearch = false,
  }) {
    return UserFilter(
      role: clearRole ? null : role ?? this.role,
      status: clearStatus ? null : status ?? this.status,
      search: clearSearch ? null : search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      if (role != null) 'role': role == UserRole.superAdmin ? 'super_admin' : role!.name,
      if (status != null) 'status': status!.name,
      if (search != null && search!.isNotEmpty) 'search': search,
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }

  @override
  List<Object?> get props => [role, status, search, page, limit];
}
