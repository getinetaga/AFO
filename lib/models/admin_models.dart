// Admin models for AFO Chat Application
import 'package:flutter/material.dart';

// User roles and permissions
enum UserRole {
  user,
  moderator,
  admin,
  superAdmin
}

enum Permission {
  // User permissions
  viewUsers,
  createUsers,
  editUsers,
  deleteUsers,
  banUsers,
  unbanUsers,
  
  // Group permissions
  viewGroups,
  createGroups,
  editGroups,
  deleteGroups,
  moderateGroups,
  
  // Content permissions
  viewReports,
  moderateContent,
  deleteContent,
  
  // System permissions
  viewAnalytics,
  managePlatform,
  viewLogs,
  exportData,
}

// User status
enum UserStatus {
  active,
  inactive,
  suspended,
  banned,
  pendingVerification,
  deleted
}

// Report status
enum ReportStatus {
  pending,
  reviewing,
  resolved,
  dismissed,
  escalated
}

// Report type
enum ReportType {
  spam,
  harassment,
  inappropriateContent,
  violence,
  hateSpeech,
  impersonation,
  copyright,
  privacy,
  other
}

// Action severity
enum ActionSeverity {
  low,
  medium,
  high,
  critical
}

// Admin user model
class AdminUser {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final List<Permission> permissions;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime? suspendedUntil;
  final String? suspensionReason;
  final Map<String, dynamic> metadata;
  final List<String> groupMemberships;
  final int reportCount;
  final bool isVerified;
  final String? phoneNumber;
  final String? location;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    this.permissions = const [],
    required this.createdAt,
    required this.lastLoginAt,
    this.suspendedUntil,
    this.suspensionReason,
    this.metadata = const {},
    this.groupMemberships = const [],
    this.reportCount = 0,
    this.isVerified = false,
    this.phoneNumber,
    this.location,
  });

  // Check if user has specific permission
  bool hasPermission(Permission permission) {
    return permissions.contains(permission) || _roleHasPermission(role, permission);
  }

  // Check if user can perform action on target user
  bool canModerateUser(AdminUser targetUser) {
    if (id == targetUser.id) return false; // Can't moderate self
    
    // Role hierarchy check
    return _roleLevel(role) > _roleLevel(targetUser.role);
  }

  // Get role level for hierarchy
  static int _roleLevel(UserRole role) {
    switch (role) {
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

  // Check if role has permission by default
  static bool _roleHasPermission(UserRole role, Permission permission) {
    switch (role) {
      case UserRole.superAdmin:
        return true; // Super admin has all permissions
      case UserRole.admin:
        return permission != Permission.managePlatform; // Admin has all except platform management
      case UserRole.moderator:
        return [
          Permission.viewUsers,
          Permission.viewGroups,
          Permission.viewReports,
          Permission.moderateContent,
          Permission.moderateGroups,
        ].contains(permission);
      case UserRole.user:
        return false; // Regular users have no admin permissions
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role.toString(),
      'status': status.toString(),
      'permissions': permissions.map((p) => p.toString()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
      'suspendedUntil': suspendedUntil?.millisecondsSinceEpoch,
      'suspensionReason': suspensionReason,
      'metadata': metadata,
      'groupMemberships': groupMemberships,
      'reportCount': reportCount,
      'isVerified': isVerified,
      'phoneNumber': phoneNumber,
      'location': location,
    };
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      role: UserRole.values.firstWhere((r) => r.toString() == json['role']),
      status: UserStatus.values.firstWhere((s) => s.toString() == json['status']),
      permissions: (json['permissions'] as List<dynamic>)
          .map((p) => Permission.values.firstWhere((perm) => perm.toString() == p))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastLoginAt: DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt']),
      suspendedUntil: json['suspendedUntil'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['suspendedUntil'])
          : null,
      suspensionReason: json['suspensionReason'],
      metadata: json['metadata'] ?? {},
      groupMemberships: List<String>.from(json['groupMemberships'] ?? []),
      reportCount: json['reportCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      phoneNumber: json['phoneNumber'],
      location: json['location'],
    );
  }

  AdminUser copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
    List<Permission>? permissions,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? suspendedUntil,
    String? suspensionReason,
    Map<String, dynamic>? metadata,
    List<String>? groupMemberships,
    int? reportCount,
    bool? isVerified,
    String? phoneNumber,
    String? location,
  }) {
    return AdminUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      metadata: metadata ?? this.metadata,
      groupMemberships: groupMemberships ?? this.groupMemberships,
      reportCount: reportCount ?? this.reportCount,
      isVerified: isVerified ?? this.isVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
    );
  }
}

// Admin group model
class AdminGroup {
  final String id;
  final String name;
  final String description;
  final String? avatarUrl;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final bool isPublic;
  final bool isActive;
  final int messageCount;
  final int reportCount;
  final Map<String, dynamic> settings;

  AdminGroup({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.creatorId,
    this.memberIds = const [],
    this.adminIds = const [],
    required this.createdAt,
    required this.lastActivityAt,
    this.isPublic = false,
    this.isActive = true,
    this.messageCount = 0,
    this.reportCount = 0,
    this.settings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActivityAt': lastActivityAt.millisecondsSinceEpoch,
      'isPublic': isPublic,
      'isActive': isActive,
      'messageCount': messageCount,
      'reportCount': reportCount,
      'settings': settings,
    };
  }

  factory AdminGroup.fromJson(Map<String, dynamic> json) {
    return AdminGroup(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatarUrl'],
      creatorId: json['creatorId'],
      memberIds: List<String>.from(json['memberIds'] ?? []),
      adminIds: List<String>.from(json['adminIds'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastActivityAt: DateTime.fromMillisecondsSinceEpoch(json['lastActivityAt']),
      isPublic: json['isPublic'] ?? false,
      isActive: json['isActive'] ?? true,
      messageCount: json['messageCount'] ?? 0,
      reportCount: json['reportCount'] ?? 0,
      settings: json['settings'] ?? {},
    );
  }
}

// Content report model
class ContentReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetUserId;
  final String? targetUserName;
  final String? messageId;
  final String? groupId;
  final ReportType type;
  final String reason;
  final String? additionalInfo;
  final ReportStatus status;
  final ActionSeverity severity;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolution;
  final String? contentSnapshot;
  final List<String> evidence; // URLs or file paths
  final Map<String, dynamic> metadata;

  ContentReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetUserId,
    this.targetUserName,
    this.messageId,
    this.groupId,
    required this.type,
    required this.reason,
    this.additionalInfo,
    this.status = ReportStatus.pending,
    this.severity = ActionSeverity.medium,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
    this.contentSnapshot,
    this.evidence = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'messageId': messageId,
      'groupId': groupId,
      'type': type.toString(),
      'reason': reason,
      'additionalInfo': additionalInfo,
      'status': status.toString(),
      'severity': severity.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'resolvedBy': resolvedBy,
      'resolution': resolution,
      'contentSnapshot': contentSnapshot,
      'evidence': evidence,
      'metadata': metadata,
    };
  }

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      id: json['id'],
      reporterId: json['reporterId'],
      reporterName: json['reporterName'],
      targetUserId: json['targetUserId'],
      targetUserName: json['targetUserName'],
      messageId: json['messageId'],
      groupId: json['groupId'],
      type: ReportType.values.firstWhere((t) => t.toString() == json['type']),
      reason: json['reason'],
      additionalInfo: json['additionalInfo'],
      status: ReportStatus.values.firstWhere((s) => s.toString() == json['status']),
      severity: ActionSeverity.values.firstWhere((s) => s.toString() == json['severity']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['resolvedAt'])
          : null,
      resolvedBy: json['resolvedBy'],
      resolution: json['resolution'],
      contentSnapshot: json['contentSnapshot'],
      evidence: List<String>.from(json['evidence'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }
}

// Moderation action model
class ModerationAction {
  final String id;
  final String adminId;
  final String adminName;
  final String targetUserId;
  final String? targetUserName;
  final String actionType; // ban, warn, delete_content, etc.
  final String reason;
  final DateTime timestamp;
  final Duration? duration; // for temporary actions
  final String? relatedReportId;
  final Map<String, dynamic> actionData;
  final bool isReversible;

  ModerationAction({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.targetUserId,
    this.targetUserName,
    required this.actionType,
    required this.reason,
    required this.timestamp,
    this.duration,
    this.relatedReportId,
    this.actionData = const {},
    this.isReversible = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminId': adminId,
      'adminName': adminName,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'actionType': actionType,
      'reason': reason,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration?.inMilliseconds,
      'relatedReportId': relatedReportId,
      'actionData': actionData,
      'isReversible': isReversible,
    };
  }

  factory ModerationAction.fromJson(Map<String, dynamic> json) {
    return ModerationAction(
      id: json['id'],
      adminId: json['adminId'],
      adminName: json['adminName'],
      targetUserId: json['targetUserId'],
      targetUserName: json['targetUserName'],
      actionType: json['actionType'],
      reason: json['reason'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      relatedReportId: json['relatedReportId'],
      actionData: json['actionData'] ?? {},
      isReversible: json['isReversible'] ?? true,
    );
  }
}

// Platform analytics model
class PlatformAnalytics {
  final int totalUsers;
  final int activeUsersToday;
  final int activeUsersWeek;
  final int activeUsersMonth;
  final int totalGroups;
  final int totalMessages;
  final int messagestoday;
  final int pendingReports;
  final int resolvedReports;
  final int bannedUsers;
  final int suspendedUsers;
  final Map<String, int> usersByRole;
  final Map<String, int> reportsByType;
  final Map<String, int> userRegistrationsByDay; // last 7 days
  final DateTime lastUpdated;

  PlatformAnalytics({
    this.totalUsers = 0,
    this.activeUsersToday = 0,
    this.activeUsersWeek = 0,
    this.activeUsersMonth = 0,
    this.totalGroups = 0,
    this.totalMessages = 0,
    this.messagestoday = 0,
    this.pendingReports = 0,
    this.resolvedReports = 0,
    this.bannedUsers = 0,
    this.suspendedUsers = 0,
    this.usersByRole = const {},
    this.reportsByType = const {},
    this.userRegistrationsByDay = const {},
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsersToday': activeUsersToday,
      'activeUsersWeek': activeUsersWeek,
      'activeUsersMonth': activeUsersMonth,
      'totalGroups': totalGroups,
      'totalMessages': totalMessages,
      'messagestoday': messagestoday,
      'pendingReports': pendingReports,
      'resolvedReports': resolvedReports,
      'bannedUsers': bannedUsers,
      'suspendedUsers': suspendedUsers,
      'usersByRole': usersByRole,
      'reportsByType': reportsByType,
      'userRegistrationsByDay': userRegistrationsByDay,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory PlatformAnalytics.fromJson(Map<String, dynamic> json) {
    return PlatformAnalytics(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsersToday: json['activeUsersToday'] ?? 0,
      activeUsersWeek: json['activeUsersWeek'] ?? 0,
      activeUsersMonth: json['activeUsersMonth'] ?? 0,
      totalGroups: json['totalGroups'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      messagestoday: json['messagestoday'] ?? 0,
      pendingReports: json['pendingReports'] ?? 0,
      resolvedReports: json['resolvedReports'] ?? 0,
      bannedUsers: json['bannedUsers'] ?? 0,
      suspendedUsers: json['suspendedUsers'] ?? 0,
      usersByRole: Map<String, int>.from(json['usersByRole'] ?? {}),
      reportsByType: Map<String, int>.from(json['reportsByType'] ?? {}),
      userRegistrationsByDay: Map<String, int>.from(json['userRegistrationsByDay'] ?? {}),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
    );
  }
}

// Admin action result
class AdminActionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  AdminActionResult({
    required this.success,
    required this.message,
    this.data,
  });

  factory AdminActionResult.success(String message, {Map<String, dynamic>? data}) {
    return AdminActionResult(success: true, message: message, data: data);
  }

  factory AdminActionResult.failure(String message) {
    return AdminActionResult(success: false, message: message);
  }
}