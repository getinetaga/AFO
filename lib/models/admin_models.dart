// Expanded admin models compatibility stubs.
// These provide the shapes and helper APIs referenced by admin services and
// UI screens so the project can analyze and build. Replace with full
// implementations when ready.

enum UserRole { user, moderator, admin, superAdmin }

enum UserStatus { active, inactive, suspended, banned, pendingVerification, deleted }

enum Permission { viewUsers, manageUsers, moderateContent, managePlatform, deleteGroups, viewReports }

// Legacy enum name used throughout the UI — keep for compatibility.
enum AdminPermission { viewUsers, manageUsers, moderateContent, managePlatform, deleteGroups, viewReports, moderateUsers, manageRoles }

enum ReportStatus { pending, underReview, resolved, dismissed }

enum ReportType { spam, harassment, inappropriateContent, violence, hateSpeech, other }

enum ReportPriority { low, medium, high, critical }

enum ModerationSeverity { low, medium, high }

enum ActionSeverity { low, medium, high }

enum Severity { minor, major, critical }

class PlatformAnalytics {
  final int totalUsers;
  final int totalGroups;
  final int totalMessages;
  final int messagestoday; // legacy name used in service
  final int activeUsersToday;
  final int activeUsersWeek;
  final int activeUsersMonth;
  final int pendingReports;
  final int resolvedReports;
  final int bannedUsers;
  final int suspendedUsers;
  final Map<String, int> usersByRole;
  final Map<String, int> reportsByType;
  final Map<String, int> userRegistrationsByDay;
  final DateTime lastUpdated;

  PlatformAnalytics({
    this.totalUsers = 0,
    this.totalGroups = 0,
    this.totalMessages = 0,
    this.messagestoday = 0,
    this.activeUsersToday = 0,
    this.activeUsersWeek = 0,
    this.activeUsersMonth = 0,
    this.pendingReports = 0,
    this.resolvedReports = 0,
    this.bannedUsers = 0,
    this.suspendedUsers = 0,
    Map<String, int>? usersByRole,
    Map<String, int>? reportsByType,
    Map<String, int>? userRegistrationsByDay,
    DateTime? lastUpdated,
  })  : usersByRole = usersByRole ?? {},
        reportsByType = reportsByType ?? {},
        userRegistrationsByDay = userRegistrationsByDay ?? {},
        lastUpdated = lastUpdated ?? DateTime.now();
}

class ContentReport {
  // Support both legacy and current field names used across the codebase.
  final String id;
  final String? reporterId;
  final String? reporterName;
  final String? targetUserId;
  final String? targetUserName;
  final String? messageId;
  final String? groupId;
  final String? reportedContentId;
  final ReportType type;
  final String reason;
  final String description;
  final ReportStatus status;
  final ReportPriority priority;
  final dynamic severity;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolution;
  final String? contentSnapshot;
  final List<String> evidence;
  final Map<String, dynamic> metadata;

  ContentReport({
    required this.id,
    this.reporterId,
    this.reporterName,
    this.targetUserId,
    this.targetUserName,
    this.messageId,
    this.groupId,
    this.reportedContentId,
    this.type = ReportType.other,
    this.reason = '',
    this.description = '',
    this.status = ReportStatus.pending,
    this.priority = ReportPriority.medium,
    this.severity,
    DateTime? createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
    this.contentSnapshot,
    this.evidence = const [],
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  // Legacy getters for older code paths
  String get reportId => id;
  String get reporterUserId => reporterId ?? '';
  String? get reportedUserId => targetUserId;
  String get resolutionNotes => resolution ?? '';
  String? get additionalInfo => description.isNotEmpty ? description : null;
}

class ModerationAction {
  final String id;
  final String adminId;
  final String? adminName;
  final String targetUserId;
  final String? targetUserName;
  final String actionType;
  final String reason;
  final DateTime timestamp;
  final Duration? duration;
  final String? relatedReportId;
  final Map<String, dynamic>? actionData;
  final bool? isReversible;
  final ModerationSeverity? severity;

  ModerationAction({
    required this.id,
    required this.adminId,
    this.adminName,
    required this.targetUserId,
    this.targetUserName,
    required this.actionType,
    required this.reason,
    DateTime? timestamp,
    this.duration,
    this.relatedReportId,
    this.actionData,
    this.isReversible,
    this.severity,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AdminUser {
  final String userId; // legacy name used in many UIs
  final String username;
  final String displayName;
  final String email;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime? lastActiveAt;
  final bool? isVerified;
  final String? profileImageUrl;
  final Map<String, dynamic>? metadata;
  final List<String>? groupMemberships;
  final int? reportCount;
  final DateTime? suspendedUntil;
  final String? suspensionReason;

  AdminUser({
    String? id,
    String? userId,
    String? username,
    String? displayName,
    String? email,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    this.lastActiveAt,
    this.isVerified,
    this.profileImageUrl,
    this.metadata,
    this.groupMemberships,
    this.reportCount,
    this.suspendedUntil,
    this.suspensionReason,
  })  : userId = userId ?? id ?? username ?? '',
        username = username ?? id ?? userId ?? '',
        displayName = displayName ?? '',
        email = email ?? '',
        createdAt = createdAt ?? DateTime.now(),
        lastLoginAt = lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  String get id => userId;

  bool hasPermission(Permission permission) {
    if (role == UserRole.superAdmin || role == UserRole.admin) return true;
    if (permission == Permission.viewUsers && role == UserRole.moderator) return true;
    return false;
  }

  bool canModerateUser(AdminUser target) {
    return roleLevel(role) > roleLevel(target.role);
  }

  static int roleLevel(UserRole r) {
    switch (r) {
      case UserRole.user:
        return 0;
      case UserRole.moderator:
        return 1;
      case UserRole.admin:
        return 2;
      case UserRole.superAdmin:
        return 3;
    }
  }


  AdminUser copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? email,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? lastActiveAt,
    bool? isVerified,
    String? profileImageUrl,
    Map<String, dynamic>? metadata,
    List<String>? groupMemberships,
    int? reportCount,
    DateTime? suspendedUntil,
    String? suspensionReason,
  }) {
    return AdminUser(
      id: userId ?? this.userId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isVerified: isVerified ?? this.isVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      metadata: metadata ?? this.metadata,
      groupMemberships: groupMemberships ?? this.groupMemberships,
      reportCount: reportCount ?? this.reportCount,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      suspensionReason: suspensionReason ?? this.suspensionReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'email': email,
        'role': role.toString(),
        'status': status.toString(),
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
    'reportCount': reportCount ?? 0,
    'suspendedUntil': suspendedUntil?.toIso8601String(),
    'suspensionReason': suspensionReason,
      };
}

class AdminGroup {
  final String id;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final String? creatorId;
  final List<String>? memberIds;
  final List<String>? adminIds;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  final bool? isPublic;
  final bool? isActive;
  final int? messageCount;
  final int? reportCount;
  final Map<String, dynamic>? settings;

  AdminGroup({
    required this.id,
    this.name,
    this.description,
    this.avatarUrl,
    this.creatorId,
    this.memberIds,
    this.adminIds,
    this.createdAt,
    this.lastActivityAt,
    this.isPublic,
    this.isActive,
    this.messageCount,
    this.reportCount,
    this.settings,
  });
}

class AdminActionResult {
  final bool success;
  final String? message;
  final dynamic data;

  AdminActionResult({required this.success, this.message, this.data});

  factory AdminActionResult.success(String message, {dynamic data}) =>
      AdminActionResult(success: true, message: message, data: data);

  factory AdminActionResult.failure(String message, {dynamic data}) =>
      AdminActionResult(success: false, message: message, data: data);
}