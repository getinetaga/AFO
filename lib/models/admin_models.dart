// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

// ============================================================================
// AFO Chat Application - Admin System Models
// ============================================================================
// This file defines comprehensive models for the admin system of the AFO
// (Afaan Oromoo Chat Services) application. It includes user management,
// content moderation, permissions, analytics, and administrative operations.
//
// Key Components:
// - User roles and hierarchical permissions system  
// - Content reporting and moderation workflow
// - Admin user and group management models
// - Platform analytics and reporting structures
// - Audit trail and action logging
// ============================================================================


// ============================================================================
// ROLE-BASED ACCESS CONTROL (RBAC) SYSTEM
// ============================================================================

/// Hierarchical user roles for the AFO platform
/// 
/// Roles are ordered by permission level (lowest to highest):
/// - user: Regular chat users with basic permissions
/// - moderator: Can moderate content and manage community guidelines
/// - admin: Can manage users, groups, and platform settings
/// - superAdmin: Full system access including user role management
enum UserRole {
  /// Regular platform users - basic chat and communication features
  user,
  
  /// Community moderators - content moderation and user guidance
  moderator,
  
  /// Platform administrators - user management and system configuration
  admin,
  
  /// Super administrators - full system control and role management
  superAdmin
}

/// Granular permissions for fine-tuned access control
/// 
/// Permissions are grouped by functional area to enable flexible
/// role-based access control throughout the admin system
enum AdminPermission {
  // ========================================================================
  // USER MANAGEMENT PERMISSIONS
  // ========================================================================
  
  /// View user profiles and basic information
  viewUsers,
  
  /// Create new user accounts
  createUsers,
  
  /// Edit existing user profiles and settings  
  editUsers,
  
  /// Delete user accounts (soft delete recommended)
  deleteUsers,
  
  /// Ban users from the platform
  banUsers,
  
  /// Remove bans and reactivate users
  unbanUsers,
  
  /// Manage user roles (promote/demote)
  manageRoles,
  
  // ========================================================================
  // GROUP MANAGEMENT PERMISSIONS
  // ========================================================================
  
  /// View group information and membership
  viewGroups,
  
  /// Create new groups and communities
  createGroups,
  
  /// Edit group settings and configuration
  editGroups,
  
  /// Delete groups and communities
  deleteGroups,
  
  /// Moderate group content and membership
  moderateGroups,
  
  // ========================================================================
  // CONTENT MODERATION PERMISSIONS
  // ========================================================================
  
  /// View content reports and flagged material
  viewReports,
  
  /// Take moderation actions on reported content
  moderateContent,
  
  /// Remove violating content from platform
  deleteContent,
  
  /// Issue warnings to users
  warnUsers,
  
  /// Suspend users temporarily
  suspendUsers,
  
  // ========================================================================
  // SYSTEM ADMINISTRATION PERMISSIONS
  // ========================================================================
  
  /// View platform analytics and metrics
  viewAnalytics,
  
  /// Manage platform settings and configuration
  managePlatform,
  
  /// View system logs and audit trails
  viewLogs,
  
  /// Export data for reporting and backup
  exportData,
  
  /// Manage notification system settings
  manageNotifications,
}

// ============================================================================
// USER STATUS MANAGEMENT
// ============================================================================

/// Comprehensive user status tracking for account lifecycle management
enum UserStatus {
  /// Normal active user with full access
  active,
  
  /// Inactive user (not using platform)
  inactive,
  
  /// Temporarily suspended user
  suspended,
  
  /// Permanently banned user
  banned,
  
  /// New user awaiting email/phone verification
  pendingVerification,
  
  /// Soft-deleted user account (for data retention)
  deleted
}

// ============================================================================
// CONTENT MODERATION WORKFLOW
// ============================================================================

/// Report lifecycle status tracking for moderation workflow
enum ReportStatus {
  /// New report awaiting initial review
  pending,
  
  /// Report currently being investigated by moderators
  underReview,
  
  /// Report successfully resolved with appropriate action taken
  resolved,
  
  /// Report dismissed as invalid or not actionable
  dismissed,
  
  /// Report escalated to higher authority for complex cases
  escalated
}

/// Categories of content violations and report types
enum ReportType {
  /// Unsolicited bulk messages or promotional content
  spam,
  
  /// Targeted harassment, bullying, or abusive behavior
  harassment,
  
  /// Sexual, violent, or otherwise inappropriate content
  inappropriateContent,
  
  /// Content depicting or promoting violence
  violence,
  
  /// Discriminatory language or hate speech
  hateSpeech,
  
  /// False representation of identity
  impersonation,
  
  /// Copyright infringement or unauthorized content use
  copyright,
  
  /// Privacy violations or doxxing
  privacy,
  
  /// Reports that don't fit other categories
  other
}

/// Priority levels for reports and moderation actions
enum ReportPriority {
  /// Low priority - non-urgent community guideline issues
  low,
  
  /// Medium priority - standard policy violations
  medium,
  
  /// High priority - serious violations requiring prompt action
  high,
  
  /// Critical priority - immediate safety threats or legal issues
  critical
}

// ============================================================================
// ADMIN USER MODEL
// ============================================================================

/// Comprehensive admin user model with role-based permissions
/// 
/// Represents administrators, moderators, and super admins who can
/// access the admin dashboard and perform administrative actions.
class AdminUser {
  /// Unique identifier for the admin user
  final String userId;
  
  /// Unique username for admin login
  final String username;
  
  /// Email address for admin account
  final String email;
  
  /// Display name shown in admin interfaces
  final String displayName;
  
  /// Optional profile image URL
  final String? profileImageUrl;
  
  /// Admin role determining permission level
  final UserRole role;
  
  /// Current account status
  final UserStatus status;
  
  /// Granular permissions for this admin user
  final List<AdminPermission> permissions;
  
  /// Account creation timestamp
  final DateTime createdAt;
  
  /// Last login timestamp for activity tracking
  final DateTime? lastActiveAt;
  
  /// Suspension end date (if temporarily suspended)
  final DateTime? suspendedUntil;
  
  /// Reason for suspension (if applicable)
  final String? suspensionReason;
  
  /// Additional metadata for extensibility
  final Map<String, dynamic> metadata;
  
  /// List of group IDs this admin belongs to
  final List<String> groupMemberships;
  
  /// Number of reports filed against this user
  final int reportCount;
  
  /// Whether the admin account is verified
  final bool isVerified;
  
  /// Optional phone number for two-factor auth
  final String? phoneNumber;
  
  /// Optional location/timezone information
  final String? location;

  /// Constructor for AdminUser with comprehensive validation
  /// 
  /// Parameters:
  /// - [userId]: Unique identifier (required)
  /// - [username]: Login username (required)
  /// - [email]: Contact email (required)
  /// - [displayName]: Human-readable name (required)
  /// - [profileImageUrl]: Optional avatar URL
  /// - [role]: Admin role (defaults to user)
  /// - [status]: Account status (defaults to active)
  /// - [permissions]: Additional permissions beyond role
  /// - [createdAt]: Account creation date (required)
  /// - [lastActiveAt]: Last activity timestamp
  /// - [suspendedUntil]: Suspension end date
  /// - [suspensionReason]: Reason for suspension
  /// - [metadata]: Additional user data
  /// - [groupMemberships]: Group affiliations
  /// - [reportCount]: Violation count
  /// - [isVerified]: Verification status
  /// - [phoneNumber]: Contact phone
  /// - [location]: User location
  AdminUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    this.permissions = const [],
    required this.createdAt,
    this.lastActiveAt,
    this.suspendedUntil,
    this.suspensionReason,
    this.metadata = const {},
    this.groupMemberships = const [],
    this.reportCount = 0,
    this.isVerified = false,
    this.phoneNumber,
    this.location, required id, required avatarUrl, required DateTime lastLoginAt,
  });

  /// Check if admin user has specific permission
  /// 
  /// Combines role-based permissions with individual granted permissions.
  /// Returns true if user has the permission through role or individual grant.
  /// 
  /// Parameters:
  /// - [permission]: The permission to check
  /// 
  /// Returns: true if user has the permission
  bool hasPermission(AdminPermission permission) {
    return permissions.contains(permission) || 
           _roleHasPermission(role, permission);
  }

  /// Check if this admin can moderate the target user
  /// 
  /// Implements role hierarchy where higher roles can moderate lower roles.
  /// Prevents self-moderation and enforces organizational structure.
  /// 
  /// Parameters:
  /// - [targetUser]: The user to be moderated
  /// 
  /// Returns: true if moderation is allowed
  bool canModerateUser(AdminUser targetUser) {
    // Prevent self-moderation
    if (userId == targetUser.userId) return false;
    
    // Role hierarchy: higher numerical level can moderate lower
    return _roleLevel(role) > _roleLevel(targetUser.role);
  }

  /// Get numerical role level for hierarchy enforcement
  /// 
  /// Assigns numerical values to roles for easy comparison:
  /// - user: 0 (lowest)
  /// - moderator: 1
  /// - admin: 2  
  /// - superAdmin: 3 (highest)
  /// 
  /// Parameters:
  /// - [role]: The user role to evaluate
  /// 
  /// Returns: Numerical level for hierarchy comparison
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

  /// Check if a role has a specific permission by default
  /// 
  /// Implements the default permission matrix for each role:
  /// - superAdmin: All permissions
  /// - admin: All permissions except platform management
  /// - moderator: Content and group moderation permissions
  /// - user: No admin permissions
  /// 
  /// Parameters:
  /// - [role]: The user role to check
  /// - [permission]: The permission to verify
  /// 
  /// Returns: true if role has the permission by default
  static bool _roleHasPermission(UserRole role, AdminPermission permission) {
    switch (role) {
      case UserRole.superAdmin:
        return true; // Super admin has all permissions
        
      case UserRole.admin:
        // Admin has all permissions except platform management
        return permission != AdminPermission.managePlatform;
        
      case UserRole.moderator:
        // Moderator permissions focused on content and community management
        return [
          AdminPermission.viewUsers,
          AdminPermission.viewGroups,
          AdminPermission.viewReports,
          AdminPermission.moderateContent,
          AdminPermission.moderateGroups,
          AdminPermission.warnUsers,
          AdminPermission.suspendUsers,
        ].contains(permission);
        
      case UserRole.user:
        return false; // Regular users have no admin permissions
    }
  }

  /// Convert AdminUser to JSON for storage and transmission
  /// 
  /// Serializes all user data to a Map suitable for database storage
  /// or API transmission. Enums are converted to string representations.
  /// 
  /// Returns: JSON-serializable Map of user data
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
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
      location: json['location'], userId: '',
    );
  }

  Future<AdminUser> copyWith({
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
  }) async {
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

mixin lastLoginAt {
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

// ============================================================================
// CONTENT REPORT MODEL
// ============================================================================

/// Comprehensive content report model for moderation system
/// 
/// Represents user-submitted reports of inappropriate content, harassment,
/// spam, or policy violations. Includes all necessary information for
/// moderators to review and take appropriate action.
class ContentReport {
  /// Unique identifier for the report
  final String reportId;
  
  /// ID of the user who submitted the report
  final String reporterUserId;
  
  /// Display name of the user who submitted the report
  final String reporterName;
  
  /// ID of the user being reported (if applicable)
  final String? reportedUserId;
  
  /// Display name of the user being reported (if applicable)
  final String? reportedUserName;
  
  /// ID of the specific message/content being reported
  final String reportedContentId;
  
  /// ID of the group where violation occurred (if applicable)
  final String? groupId;
  
  /// Category of the violation being reported
  final ReportType type;
  
  /// Brief description of the violation
  final String reason;
  
  /// Detailed description and context provided by reporter
  final String description;
  
  /// Current status of the report in moderation workflow
  final ReportStatus status;
  
  /// Priority level assigned to the report
  final ReportPriority priority;
  
  /// Timestamp when report was submitted
  final DateTime createdAt;
  
  /// Timestamp when report was last updated
  final DateTime updatedAt;
  
  /// Timestamp when report was resolved (if resolved)
  final DateTime? resolvedAt;
  
  /// ID of admin/moderator who resolved the report
  final String? resolvedBy;
  
  /// Resolution notes explaining the action taken
  final String resolutionNotes;
  
  /// Snapshot of the reported content for reference
  final String contentSnapshot;
  
  /// URLs or paths to evidence files (screenshots, etc.)
  final List<String> evidence;
  
  /// Additional metadata and context information
  final Map<String, dynamic> metadata;

  /// Constructor for ContentReport with validation
  ContentReport({
    required this.reportId,
    required this.reporterUserId,
    required this.reporterName,
    this.reportedUserId,
    this.reportedUserName,
    required this.reportedContentId,
    this.groupId,
    required this.type,
    required this.reason,
    this.description = '',
    this.status = ReportStatus.pending,
    this.priority = ReportPriority.medium,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes = '',
    this.contentSnapshot = '',
    this.evidence = const [],
    this.metadata = const {},
  });

  /// Convert ContentReport to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reporterUserId': reporterUserId,
      'reporterName': reporterName,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'reportedContentId': reportedContentId,
      'groupId': groupId,
      'type': type.toString(),
      'reason': reason,
      'description': description,
      'status': status.toString(),
      'priority': priority.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'resolvedBy': resolvedBy,
      'resolutionNotes': resolutionNotes,
      'contentSnapshot': contentSnapshot,
      'evidence': evidence,
      'metadata': metadata,
    };
  }

  /// Create ContentReport from JSON data
  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      reportId: json['reportId'],
      reporterUserId: json['reporterUserId'],
      reporterName: json['reporterName'],
      reportedUserId: json['reportedUserId'],
      reportedUserName: json['reportedUserName'],
      reportedContentId: json['reportedContentId'],
      groupId: json['groupId'],
      type: ReportType.values.firstWhere((t) => t.toString() == json['type']),
      reason: json['reason'],
      description: json['description'] ?? '',
      status: ReportStatus.values.firstWhere((s) => s.toString() == json['status']),
      priority: ReportPriority.values.firstWhere((p) => p.toString() == json['priority']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['resolvedAt'])
          : null,
      resolvedBy: json['resolvedBy'],
      resolutionNotes: json['resolutionNotes'] ?? '',
      contentSnapshot: json['contentSnapshot'] ?? '',
      evidence: List<String>.from(json['evidence'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }
}

// ============================================================================
// MODERATION ACTION MODEL  
// ============================================================================

/// Model representing administrative/moderation actions taken on the platform
/// 
/// Provides audit trail and accountability for all moderation decisions,
/// including bans, warnings, content removal, and other administrative actions.
class ModerationAction {
  /// Unique identifier for the moderation action
  final String actionId;
  
  /// ID of the admin/moderator who took the action
  final String adminId;
  
  /// Display name of the admin/moderator
  final String adminName;
  
  /// ID of the user the action was taken against
  final String targetUserId;
  
  /// Display name of the target user
  final String? targetUserName;
  
  /// Type of action taken (ban, warn, delete_content, etc.)
  final String actionType;
  
  /// Reason/justification for the action
  final String reason;
  
  /// Timestamp when action was taken
  final DateTime timestamp;
  
  /// Duration for temporary actions (bans, suspensions)
  final Duration? duration;
  
  /// ID of the content affected by the action (if applicable)
  final String? contentId;
  
  /// Additional details about the action taken
  final String details;
  
  /// Whether the action was automated or manual
  final bool isAutomated;
  
  /// Severity level of the action taken
  final ModerationSeverity severity;
  
  /// ID of the report that triggered this action (if applicable)
  final String? relatedReportId;
  
  /// Additional metadata and context for the action
  final Map<String, dynamic> metadata;

  /// Constructor for ModerationAction
  ModerationAction({
    required this.actionId,
    required this.adminId,
    required this.adminName,
    required this.targetUserId,
    this.targetUserName,
    required this.actionType,
    required this.reason,
    required this.timestamp,
    this.duration,
    this.contentId,
    this.details = '',
    this.isAutomated = false,
    this.severity = ModerationSeverity.low,
    this.relatedReportId,
    this.metadata = const {},
  });

  /// Convert ModerationAction to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'adminId': adminId,
      'adminName': adminName,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'actionType': actionType,
      'reason': reason,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'contentId': contentId,
      'details': details,
      'isAutomated': isAutomated,
      'severity': severity.toString(),
      'relatedReportId': relatedReportId,
      'metadata': metadata,
    };
  }

  /// Create ModerationAction from JSON data
  factory ModerationAction.fromJson(Map<String, dynamic> json) {
    return ModerationAction(
      actionId: json['actionId'],
      adminId: json['adminId'],
      adminName: json['adminName'],
      targetUserId: json['targetUserId'],
      targetUserName: json['targetUserName'],
      actionType: json['actionType'],
      reason: json['reason'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      contentId: json['contentId'],
      details: json['details'] ?? '',
      isAutomated: json['isAutomated'] ?? false,
      severity: ModerationSeverity.values.firstWhere(
        (s) => s.toString() == json['severity'],
        orElse: () => ModerationSeverity.low,
      ),
      relatedReportId: json['relatedReportId'],
      metadata: json['metadata'] ?? {},
    );
  }

  ModerationAction copyWith({
    String? actionId,
    String? adminId,
    String? adminName,
    String? targetUserId,
    String? targetUserName,
    String? actionType,
    String? reason,
    DateTime? timestamp,
    Duration? duration,
    String? contentId,
    String? details,
    bool? isAutomated,
    ModerationSeverity? severity,
    String? relatedReportId,
    Map<String, dynamic>? metadata,
  }) {
    return ModerationAction(
      actionId: actionId ?? this.actionId,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      actionType: actionType ?? this.actionType,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      contentId: contentId ?? this.contentId,
      details: details ?? this.details,
      isAutomated: isAutomated ?? this.isAutomated,
      severity: severity ?? this.severity,
      relatedReportId: relatedReportId ?? this.relatedReportId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'actionId': actionId,
      'adminId': adminId,
      'adminName': adminName,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'actionType': actionType,
      'reason': reason,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration?.toMap(),
      'contentId': contentId,
      'details': details,
      'isAutomated': isAutomated,
      'severity': severity.toMap(),
      'relatedReportId': relatedReportId,
      'metadata': metadata,
    };
  }

  factory ModerationAction.fromMap(Map<String, dynamic> map) {
    return ModerationAction(
      actionId: map['actionId'] as String,
      adminId: map['adminId'] as String,
      adminName: map['adminName'] as String,
      targetUserId: map['targetUserId'] as String,
      targetUserName: map['targetUserName'] != null ? map['targetUserName'] as String : null,
      actionType: map['actionType'] as String,
      reason: map['reason'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      duration: map['duration'] != null ? Duration.fromMap(map['duration'] as Map<String,dynamic>) : null,
      contentId: map['contentId'] != null ? map['contentId'] as String : null,
      details: map['details'] as String,
      isAutomated: map['isAutomated'] as bool,
      severity: ModerationSeverity.fromMap(map['severity'] as Map<String,dynamic>),
      relatedReportId: map['relatedReportId'] != null ? map['relatedReportId'] as String : null,
      metadata: Map<String, dynamic>.from((map['metadata'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory ModerationAction.fromJson(String source) => ModerationAction.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ModerationAction(actionId: $actionId, adminId: $adminId, adminName: $adminName, targetUserId: $targetUserId, targetUserName: $targetUserName, actionType: $actionType, reason: $reason, timestamp: $timestamp, duration: $duration, contentId: $contentId, details: $details, isAutomated: $isAutomated, severity: $severity, relatedReportId: $relatedReportId, metadata: $metadata)';
  }

  @override
  bool operator ==(covariant ModerationAction other) {
    if (identical(this, other)) return true;
  
    return 
      other.actionId == actionId &&
      other.adminId == adminId &&
      other.adminName == adminName &&
      other.targetUserId == targetUserId &&
      other.targetUserName == targetUserName &&
      other.actionType == actionType &&
      other.reason == reason &&
      other.timestamp == timestamp &&
      other.duration == duration &&
      other.contentId == contentId &&
      other.details == details &&
      other.isAutomated == isAutomated &&
      other.severity == severity &&
      other.relatedReportId == relatedReportId &&
      mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return actionId.hashCode ^
      adminId.hashCode ^
      adminName.hashCode ^
      targetUserId.hashCode ^
      targetUserName.hashCode ^
      actionType.hashCode ^
      reason.hashCode ^
      timestamp.hashCode ^
      duration.hashCode ^
      contentId.hashCode ^
      details.hashCode ^
      isAutomated.hashCode ^
      severity.hashCode ^
      relatedReportId.hashCode ^
      metadata.hashCode;
  }
}

class ModerationSeverity {
}
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

  ContentReport.fromJson(Map<String, dynamic> json) {
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

// ============================================================================
// PLATFORM ANALYTICS MODEL
// ============================================================================

/// Comprehensive platform analytics and metrics model
/// 
/// Provides real-time statistics and insights for admin dashboard,
/// including user engagement, content activity, moderation metrics,
/// and trend analysis for platform health monitoring.
class PlatformAnalytics {
  /// Total number of registered users on the platform
  final int totalUsers;
  
  /// Number of users active today (last 24 hours)
  final int activeUsersToday;
  
  /// Number of users active this week (last 7 days)
  final int activeUsersWeek;
  
  /// Number of users active this month (last 30 days)
  final int activeUsersMonth;
  
  /// Total number of groups/channels created
  final int totalGroups;
  
  /// Total number of messages sent on the platform
  final int totalMessages;
  
  /// Number of messages sent today
  final int messagesToday;
  
  /// Number of unresolved content reports pending review
  final int pendingReports;
  
  /// Number of reports resolved in total
  final int resolvedReports;
  
  /// Number of currently banned users
  final int bannedUsers;
  
  /// Number of currently suspended users
  final int suspendedUsers;
  
  /// Breakdown of users by role (user, moderator, admin, etc.)
  final Map<String, int> usersByRole;
  
  /// Breakdown of reports by violation type (spam, harassment, etc.)
  final Map<String, int> reportsByType;
  
  /// Daily user registration counts for trend analysis (last 7 days)
  final Map<String, int> userRegistrationsByDay;
  
  /// Timestamp when analytics were last calculated/updated
  final DateTime lastUpdated;

  /// Constructor for PlatformAnalytics with default values
  PlatformAnalytics({
    this.totalUsers = 0,
    this.activeUsersToday = 0,
    this.activeUsersWeek = 0,
    this.activeUsersMonth = 0,
    this.totalGroups = 0,
    this.totalMessages = 0,
    this.messagesToday = 0,
    this.pendingReports = 0,
    this.resolvedReports = 0,
    this.bannedUsers = 0,
    this.suspendedUsers = 0,
    this.usersByRole = const {},
    this.reportsByType = const {},
    this.userRegistrationsByDay = const {},
    required this.lastUpdated,
  });

  /// Convert PlatformAnalytics to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsersToday': activeUsersToday,
      'activeUsersWeek': activeUsersWeek,
      'activeUsersMonth': activeUsersMonth,
      'totalGroups': totalGroups,
      'totalMessages': totalMessages,
      'messagesToday': messagesToday,
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

  /// Create PlatformAnalytics from JSON data
  factory PlatformAnalytics.fromJson(Map<String, dynamic> json) {
    return PlatformAnalytics(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsersToday: json['activeUsersToday'] ?? 0,
      activeUsersWeek: json['activeUsersWeek'] ?? 0,
      activeUsersMonth: json['activeUsersMonth'] ?? 0,
      totalGroups: json['totalGroups'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      messagesToday: json['messagesToday'] ?? 0,
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

// ============================================================================
// ADMIN ACTION RESULT MODEL
// ============================================================================

/// Result wrapper for administrative actions and operations
/// 
/// Provides standardized response format for admin operations,
/// including success/failure status, descriptive messages,
/// and optional data payload for additional context.
class AdminActionResult {
  /// Whether the administrative action succeeded
  final bool success;
  
  /// Descriptive message about the action result
  final String message;
  
  /// Optional additional data related to the action
  final Map<String, dynamic>? data;

  /// Constructor for AdminActionResult
  AdminActionResult({
    required this.success,
    required this.message,
    this.data,
  });

  /// Create a successful action result
  /// 
  /// Parameters:
  /// - [message]: Success message to display
  /// - [data]: Optional additional data
  /// 
  /// Returns: AdminActionResult with success = true
  factory AdminActionResult.success(String message, {Map<String, dynamic>? data}) {
    return AdminActionResult(success: true, message: message, data: data);
  }

  /// Create a failed action result
  /// 
  /// Parameters:
  /// - [message]: Error message describing the failure
  /// 
  /// Returns: AdminActionResult with success = false
  factory AdminActionResult.failure(String message) {
    return AdminActionResult(success: false, message: message);
  }
}