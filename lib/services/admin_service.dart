// Admin Service for AFO Chat Application
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/admin_models.dart';

class AdminService {
  factory AdminService() => _instance;

  AdminService._internal();

  static final AdminService _instance = AdminService._internal();

  final Map<String, ModerationAction> _actions = {};
  final StreamController<PlatformAnalytics> _analyticsController = 
      StreamController<PlatformAnalytics>.broadcast();

  // Current admin user
  AdminUser? _currentAdmin;

  final Map<String, AdminGroup> _groups = {};
  final Map<String, ContentReport> _reports = {};
  final StreamController<List<ContentReport>> _reportsController = 
      StreamController<List<ContentReport>>.broadcast();

  // Mock data storage
  final Map<String, AdminUser> _users = {};

  // Stream controllers
  final StreamController<List<AdminUser>> _usersController = 
      StreamController<List<AdminUser>>.broadcast();

  // Getters for streams
  Stream<List<AdminUser>> get usersStream => _usersController.stream;

  Stream<List<ContentReport>> get reportsStream => _reportsController.stream;

  Stream<PlatformAnalytics> get analyticsStream => _analyticsController.stream;

  // Current admin getter
  AdminUser? get currentAdmin => _currentAdmin;

  // Initialize admin service
  Future<bool> initialize({String? adminId}) async {
    try {
      await _initializeMockData();
      
      if (adminId != null) {
        _currentAdmin = _users[adminId];
      }
      
      // Start periodic analytics updates
      _startAnalyticsUpdates();
      
      print('AdminService: Initialized successfully');
      return true;
    } catch (e) {
      print('AdminService: Failed to initialize: $e');
      return false;
    }
  }

  // User management methods
  Future<List<AdminUser>> getUsers({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
    UserRole? roleFilter,
    UserStatus? statusFilter,
  }) async {
    var users = _users.values.toList();
    
    // Apply filters
    if (searchQuery != null && searchQuery.isNotEmpty) {
      users = users.where((user) =>
          user.username.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.displayName.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    
    if (roleFilter != null) {
      users = users.where((user) => user.role == roleFilter).toList();
    }
    
    if (statusFilter != null) {
      users = users.where((user) => user.status == statusFilter).toList();
    }
    
    // Sort by last login
    users.sort((a, b) => b.lastLoginAt.compareTo(a.lastLoginAt));
    
    // Paginate
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    
    if (startIndex >= users.length) return [];
    
    return users.sublist(
      startIndex,
      endIndex > users.length ? users.length : endIndex,
    );
  }

  Future<AdminUser?> getUser(String userId) async {
    return _users[userId];
  }

  Future<AdminActionResult> banUser({
    required String userId,
    required String reason,
    Duration? duration,
  }) async {
    if (_currentAdmin == null) {
      return AdminActionResult.failure('No admin authenticated');
    }

    final targetUser = _users[userId];
    if (targetUser == null) {
      return AdminActionResult.failure('User not found');
    }

    if (!_currentAdmin!.canModerateUser(targetUser)) {
      return AdminActionResult.failure('Insufficient permissions');
    }

    // Update user status
    final suspendedUntil = duration != null ? DateTime.now().add(duration) : null;
    _users[userId] = targetUser.copyWith(
      status: UserStatus.banned,
      suspendedUntil: suspendedUntil,
      suspensionReason: reason,
    );

    // Record moderation action
    final action = ModerationAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}',
      adminId: _currentAdmin!.id,
      adminName: _currentAdmin!.displayName,
      targetUserId: userId,
      targetUserName: targetUser.displayName,
      actionType: duration != null ? 'temporary_ban' : 'permanent_ban',
      reason: reason,
      timestamp: DateTime.now(),
      duration: duration,
    );
    _actions[action.id] = action;

    _notifyListeners();
    return AdminActionResult.success('User banned successfully');
  }

  Future<AdminActionResult> unbanUser(String userId, String reason) async {
    if (_currentAdmin == null) {
      return AdminActionResult.failure('No admin authenticated');
    }

    final targetUser = _users[userId];
    if (targetUser == null) {
      return AdminActionResult.failure('User not found');
    }

    if (!_currentAdmin!.canModerateUser(targetUser)) {
      return AdminActionResult.failure('Insufficient permissions');
    }

    _users[userId] = targetUser.copyWith(
      status: UserStatus.active,
      suspendedUntil: null,
      suspensionReason: null,
    );

    final action = ModerationAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}',
      adminId: _currentAdmin!.id,
      adminName: _currentAdmin!.displayName,
      targetUserId: userId,
      targetUserName: targetUser.displayName,
      actionType: 'unban',
      reason: reason,
      timestamp: DateTime.now(),
    );
    _actions[action.id] = action;

    _notifyListeners();
    return AdminActionResult.success('User unbanned successfully');
  }

  Future<AdminActionResult> changeUserRole(String userId, UserRole newRole) async {
    if (_currentAdmin == null) {
      return AdminActionResult.failure('No admin authenticated');
    }

    final targetUser = _users[userId];
    if (targetUser == null) {
      return AdminActionResult.failure('User not found');
    }

    if (!_currentAdmin!.canModerateUser(targetUser)) {
      return AdminActionResult.failure('Insufficient permissions');
    }

    // Check if current admin can assign this role
    if (AdminUser._roleLevel(newRole) >= AdminUser._roleLevel(_currentAdmin!.role)) {
      return AdminActionResult.failure('Cannot assign role equal to or higher than your own');
    }

    _users[userId] = targetUser.copyWith(role: newRole);

    final action = ModerationAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}',
      adminId: _currentAdmin!.id,
      adminName: _currentAdmin!.displayName,
      targetUserId: userId,
      targetUserName: targetUser.displayName,
      actionType: 'role_change',
      reason: 'Role changed to ${newRole.toString().split('.').last}',
      timestamp: DateTime.now(),
      actionData: {'oldRole': targetUser.role.toString(), 'newRole': newRole.toString()},
    );
    _actions[action.id] = action;

    _notifyListeners();
    return AdminActionResult.success('User role updated successfully');
  }

  // Group management methods
  Future<List<AdminGroup>> getGroups({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
    bool? activeOnly,
  }) async {
    var groups = _groups.values.toList();
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      groups = groups.where((group) =>
          group.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          group.description.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    
    if (activeOnly == true) {
      groups = groups.where((group) => group.isActive).toList();
    }
    
    groups.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    
    if (startIndex >= groups.length) return [];
    
    return groups.sublist(
      startIndex,
      endIndex > groups.length ? groups.length : endIndex,
    );
  }

  Future<AdminActionResult> deleteGroup(String groupId, String reason) async {
    if (_currentAdmin == null) {
      return AdminActionResult.failure('No admin authenticated');
    }

    if (!_currentAdmin!.hasPermission(Permission.deleteGroups)) {
      return AdminActionResult.failure('Insufficient permissions');
    }

    final group = _groups[groupId];
    if (group == null) {
      return AdminActionResult.failure('Group not found');
    }

    _groups[groupId] = AdminGroup(
      id: group.id,
      name: group.name,
      description: group.description,
      avatarUrl: group.avatarUrl,
      creatorId: group.creatorId,
      memberIds: group.memberIds,
      adminIds: group.adminIds,
      createdAt: group.createdAt,
      lastActivityAt: group.lastActivityAt,
      isPublic: group.isPublic,
      isActive: false, // Deactivate group
      messageCount: group.messageCount,
      reportCount: group.reportCount,
      settings: group.settings,
    );

    final action = ModerationAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}',
      adminId: _currentAdmin!.id,
      adminName: _currentAdmin!.displayName,
      targetUserId: group.creatorId,
      actionType: 'group_delete',
      reason: reason,
      timestamp: DateTime.now(),
      actionData: {'groupId': groupId, 'groupName': group.name},
    );
    _actions[action.id] = action;

    _notifyListeners();
    return AdminActionResult.success('Group deleted successfully');
  }

  // Report management methods
  Future<List<ContentReport>> getReports({
    int page = 1,
    int pageSize = 20,
    ReportStatus? statusFilter,
    ReportType? typeFilter,
    ActionSeverity? severityFilter,
  }) async {
    var reports = _reports.values.toList();
    
    if (statusFilter != null) {
      reports = reports.where((report) => report.status == statusFilter).toList();
    }
    
    if (typeFilter != null) {
      reports = reports.where((report) => report.type == typeFilter).toList();
    }
    
    if (severityFilter != null) {
      reports = reports.where((report) => report.severity == severityFilter).toList();
    }
    
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    
    if (startIndex >= reports.length) return [];
    
    return reports.sublist(
      startIndex,
      endIndex > reports.length ? reports.length : endIndex,
    );
  }

  Future<AdminActionResult> resolveReport({
    required String reportId,
    required String resolution,
    required ReportStatus newStatus,
  }) async {
    if (_currentAdmin == null) {
      return AdminActionResult.failure('No admin authenticated');
    }

    if (!_currentAdmin!.hasPermission(Permission.viewReports)) {
      return AdminActionResult.failure('Insufficient permissions');
    }

    final report = _reports[reportId];
    if (report == null) {
      return AdminActionResult.failure('Report not found');
    }

    _reports[reportId] = ContentReport(
      id: report.id,
      reporterId: report.reporterId,
      reporterName: report.reporterName,
      targetUserId: report.targetUserId,
      targetUserName: report.targetUserName,
      messageId: report.messageId,
      groupId: report.groupId,
      type: report.type,
      reason: report.reason,
      additionalInfo: report.additionalInfo,
      status: newStatus,
      severity: report.severity,
      createdAt: report.createdAt,
      resolvedAt: DateTime.now(),
      resolvedBy: _currentAdmin!.displayName,
      resolution: resolution,
      contentSnapshot: report.contentSnapshot,
      evidence: report.evidence,
      metadata: report.metadata,
    );

    _notifyListeners();
    return AdminActionResult.success('Report resolved successfully');
  }

  // Analytics methods
  Future<PlatformAnalytics> getAnalytics() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    final activeUsersToday = _users.values
        .where((user) => user.lastLoginAt.isAfter(today))
        .length;
    
    final activeUsersWeek = _users.values
        .where((user) => user.lastLoginAt.isAfter(weekAgo))
        .length;
        
    final activeUsersMonth = _users.values
        .where((user) => user.lastLoginAt.isAfter(monthAgo))
        .length;

    final pendingReports = _reports.values
        .where((report) => report.status == ReportStatus.pending)
        .length;
    
    final resolvedReports = _reports.values
        .where((report) => report.status == ReportStatus.resolved)
        .length;

    final bannedUsers = _users.values
        .where((user) => user.status == UserStatus.banned)
        .length;
    
    final suspendedUsers = _users.values
        .where((user) => user.status == UserStatus.suspended)
        .length;

    // User role distribution
    final usersByRole = <String, int>{};
    for (final role in UserRole.values) {
      usersByRole[role.toString().split('.').last] = _users.values
          .where((user) => user.role == role)
          .length;
    }

    // Report type distribution
    final reportsByType = <String, int>{};
    for (final type in ReportType.values) {
      reportsByType[type.toString().split('.').last] = _reports.values
          .where((report) => report.type == type)
          .length;
    }

    // User registrations by day (last 7 days)
    final userRegistrationsByDay = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      userRegistrationsByDay[dateKey] = _users.values
          .where((user) {
            final createdDate = DateTime(
              user.createdAt.year,
              user.createdAt.month,
              user.createdAt.day,
            );
            return createdDate == date;
          })
          .length;
    }

    return PlatformAnalytics(
      totalUsers: _users.length,
      activeUsersToday: activeUsersToday,
      activeUsersWeek: activeUsersWeek,
      activeUsersMonth: activeUsersMonth,
      totalGroups: _groups.length,
      totalMessages: _users.values
          .map((user) => user.metadata['messagesCount'] ?? 0)
          .fold<int>(0, (sum, count) => sum + count),
      messagestoday: Random().nextInt(500), // Mock data
      pendingReports: pendingReports,
      resolvedReports: resolvedReports,
      bannedUsers: bannedUsers,
      suspendedUsers: suspendedUsers,
      usersByRole: usersByRole,
      reportsByType: reportsByType,
      userRegistrationsByDay: userRegistrationsByDay,
      lastUpdated: DateTime.now(),
    );
  }

  // Authentication methods
  Future<AdminActionResult> authenticate(String username, String password) async {
    // Mock authentication
    final admin = _users.values
        .where((user) => user.username == username && user.role != UserRole.user)
        .firstOrNull;

    if (admin == null) {
      return AdminActionResult.failure('Invalid credentials');
    }

    if (admin.status != UserStatus.active) {
      return AdminActionResult.failure('Account is not active');
    }

    _currentAdmin = admin;
    
    // Update last login
    _users[admin.id] = admin.copyWith(lastLoginAt: DateTime.now());
    
    return AdminActionResult.success('Authentication successful', data: admin.toJson());
  }

  void logout() {
    _currentAdmin = null;
  }

  // Get moderation actions
  Future<List<ModerationAction>> getModerationActions({
    int page = 1,
    int pageSize = 20,
    String? targetUserId,
    String? adminId,
  }) async {
    var actions = _actions.values.toList();
    
    if (targetUserId != null) {
      actions = actions.where((action) => action.targetUserId == targetUserId).toList();
    }
    
    if (adminId != null) {
      actions = actions.where((action) => action.adminId == adminId).toList();
    }
    
    actions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    
    if (startIndex >= actions.length) return [];
    
    return actions.sublist(
      startIndex,
      endIndex > actions.length ? actions.length : endIndex,
    );
  }

  // Cleanup
  void dispose() {
    _usersController.close();
    _reportsController.close();
    _analyticsController.close();
  }

  // Initialize mock data
  Future<void> _initializeMockData() async {
    // Create sample admin users
    final sampleUsers = [
      AdminUser(
        id: 'admin_1',
        username: 'superadmin',
        email: 'superadmin@afo.com',
        displayName: 'Super Administrator',
        role: UserRole.superAdmin,
        status: UserStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)),
        isVerified: true,
        metadata: {'loginCount': 500, 'actionsCount': 150},
      ),
      AdminUser(
        id: 'admin_2',
        username: 'admin',
        email: 'admin@afo.com',
        displayName: 'System Administrator',
        role: UserRole.admin,
        status: UserStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 3)),
        isVerified: true,
        metadata: {'loginCount': 250, 'actionsCount': 80},
      ),
      AdminUser(
        id: 'mod_1',
        username: 'moderator1',
        email: 'mod1@afo.com',
        displayName: 'Content Moderator',
        role: UserRole.moderator,
        status: UserStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 8)),
        isVerified: true,
        metadata: {'loginCount': 120, 'actionsCount': 45},
      ),
    ];

    // Add regular users
    for (int i = 1; i <= 100; i++) {
      final user = AdminUser(
        id: 'user_$i',
        username: 'user$i',
        email: 'user$i@example.com',
        displayName: 'User $i',
        role: UserRole.user,
        status: _getRandomUserStatus(),
        createdAt: DateTime.now().subtract(Duration(days: Random().nextInt(365))),
        lastLoginAt: DateTime.now().subtract(Duration(hours: Random().nextInt(168))),
        isVerified: Random().nextBool(),
        reportCount: Random().nextInt(5),
        groupMemberships: _getRandomGroups(),
        metadata: {
          'loginCount': Random().nextInt(100),
          'messagesCount': Random().nextInt(1000),
        },
      );
      _users[user.id] = user;
    }

    // Add admin users
    for (final user in sampleUsers) {
      _users[user.id] = user;
    }

    // Create sample groups
    for (int i = 1; i <= 20; i++) {
      final group = AdminGroup(
        id: 'group_$i',
        name: 'Group $i',
        description: 'Sample group $i for testing',
        creatorId: 'user_${Random().nextInt(50) + 1}',
        memberIds: _getRandomMemberIds(),
        adminIds: ['user_${Random().nextInt(10) + 1}'],
        createdAt: DateTime.now().subtract(Duration(days: Random().nextInt(180))),
        lastActivityAt: DateTime.now().subtract(Duration(hours: Random().nextInt(24))),
        isPublic: Random().nextBool(),
        messageCount: Random().nextInt(500),
        reportCount: Random().nextInt(10),
      );
      _groups[group.id] = group;
    }

    // Create sample reports
    for (int i = 1; i <= 50; i++) {
      final report = ContentReport(
        id: 'report_$i',
        reporterId: 'user_${Random().nextInt(50) + 1}',
        reporterName: 'User ${Random().nextInt(50) + 1}',
        targetUserId: 'user_${Random().nextInt(50) + 51}',
        targetUserName: 'User ${Random().nextInt(50) + 51}',
        messageId: 'msg_${Random().nextInt(1000)}',
        groupId: Random().nextBool() ? 'group_${Random().nextInt(20) + 1}' : null,
        type: ReportType.values[Random().nextInt(ReportType.values.length)],
        reason: _getRandomReportReason(),
        status: ReportStatus.values[Random().nextInt(ReportStatus.values.length)],
        severity: ActionSeverity.values[Random().nextInt(ActionSeverity.values.length)],
        createdAt: DateTime.now().subtract(Duration(hours: Random().nextInt(168))),
        resolvedAt: Random().nextBool() 
            ? DateTime.now().subtract(Duration(hours: Random().nextInt(24)))
            : null,
        contentSnapshot: 'Sample content that was reported',
      );
      _reports[report.id] = report;
    }

    _notifyListeners();
  }

  // Helper methods for mock data
  UserStatus _getRandomUserStatus() {
    final statuses = [
      UserStatus.active,
      UserStatus.active,
      UserStatus.active, // More likely to be active
      UserStatus.inactive,
      UserStatus.suspended,
      UserStatus.banned,
    ];
    return statuses[Random().nextInt(statuses.length)];
  }

  List<String> _getRandomGroups() {
    final groupCount = Random().nextInt(5);
    final groups = <String>[];
    for (int i = 0; i < groupCount; i++) {
      groups.add('group_${Random().nextInt(20) + 1}');
    }
    return groups;
  }

  List<String> _getRandomMemberIds() {
    final memberCount = Random().nextInt(50) + 5;
    final members = <String>[];
    for (int i = 0; i < memberCount; i++) {
      members.add('user_${Random().nextInt(100) + 1}');
    }
    return members;
  }

  String _getRandomReportReason() {
    final reasons = [
      'Inappropriate language',
      'Spam messages',
      'Harassment',
      'Sharing inappropriate content',
      'Impersonation',
      'Hate speech',
      'Copyright violation',
      'Privacy violation',
      'Violence or threats',
      'Other violation',
    ];
    return reasons[Random().nextInt(reasons.length)];
  }

  // Periodic analytics updates
  void _startAnalyticsUpdates() {
    Timer.periodic(const Duration(minutes: 5), (_) async {
      final analytics = await getAnalytics();
      _analyticsController.add(analytics);
    });
  }

  // Notification helpers
  void _notifyListeners() {
    _usersController.add(_users.values.toList());
    _reportsController.add(_reports.values.toList());
  }
}

extension on Iterable {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first as T;
  }
}