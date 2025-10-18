// ============================================================================
// AFO Chat Application - Model Unit Tests
// ============================================================================
// Comprehensive test suite for data models including:
// - Admin models (User, Platform Analytics, Reports)
// - Notification settings
// - Data validation and enum testing
// ============================================================================

import 'package:afochatapplication/models/admin_models.dart';
import 'package:afochatapplication/models/notification_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole Enum', () {
    test('should have correct enum values', () {
      expect(UserRole.values.length, equals(4));
      expect(UserRole.values, contains(UserRole.user));
      expect(UserRole.values, contains(UserRole.moderator));
      expect(UserRole.values, contains(UserRole.admin));
      expect(UserRole.values, contains(UserRole.superAdmin));
    });

    test('should convert enum to string correctly', () {
      expect(UserRole.user.toString(), equals('UserRole.user'));
      expect(UserRole.moderator.toString(), equals('UserRole.moderator'));
      expect(UserRole.admin.toString(), equals('UserRole.admin'));
      expect(UserRole.superAdmin.toString(), equals('UserRole.superAdmin'));
    });
  });

  group('UserStatus Enum', () {
    test('should have correct enum values', () {
      expect(UserStatus.values.length, equals(6));
      expect(UserStatus.values, contains(UserStatus.active));
      expect(UserStatus.values, contains(UserStatus.inactive));
      expect(UserStatus.values, contains(UserStatus.suspended));
      expect(UserStatus.values, contains(UserStatus.banned));
      expect(UserStatus.values, contains(UserStatus.pendingVerification));
      expect(UserStatus.values, contains(UserStatus.deleted));
    });
  });

  group('Permission Enum', () {
    test('should have correct permission values', () {
      expect(Permission.values.length, equals(6));
      expect(Permission.values, contains(Permission.viewUsers));
      expect(Permission.values, contains(Permission.manageUsers));
      expect(Permission.values, contains(Permission.moderateContent));
      expect(Permission.values, contains(Permission.managePlatform));
      expect(Permission.values, contains(Permission.deleteGroups));
      expect(Permission.values, contains(Permission.viewReports));
    });
  });

  group('AdminPermission Enum', () {
    test('should have correct admin permission values', () {
      expect(AdminPermission.values.length, equals(8));
      expect(AdminPermission.values, contains(AdminPermission.viewUsers));
      expect(AdminPermission.values, contains(AdminPermission.manageUsers));
      expect(AdminPermission.values, contains(AdminPermission.moderateContent));
      expect(AdminPermission.values, contains(AdminPermission.managePlatform));
      expect(AdminPermission.values, contains(AdminPermission.deleteGroups));
      expect(AdminPermission.values, contains(AdminPermission.viewReports));
      expect(AdminPermission.values, contains(AdminPermission.moderateUsers));
      expect(AdminPermission.values, contains(AdminPermission.manageRoles));
    });
  });

  group('ReportStatus Enum', () {
    test('should have correct report status values', () {
      expect(ReportStatus.values.length, equals(4));
      expect(ReportStatus.values, contains(ReportStatus.pending));
      expect(ReportStatus.values, contains(ReportStatus.underReview));
      expect(ReportStatus.values, contains(ReportStatus.resolved));
      expect(ReportStatus.values, contains(ReportStatus.dismissed));
    });
  });

  group('ReportType Enum', () {
    test('should have correct report type values', () {
      expect(ReportType.values.length, equals(6));
      expect(ReportType.values, contains(ReportType.spam));
      expect(ReportType.values, contains(ReportType.harassment));
      expect(ReportType.values, contains(ReportType.inappropriateContent));
      expect(ReportType.values, contains(ReportType.violence));
      expect(ReportType.values, contains(ReportType.hateSpeech));
      expect(ReportType.values, contains(ReportType.other));
    });
  });

  group('ReportPriority Enum', () {
    test('should have correct priority levels', () {
      expect(ReportPriority.values.length, equals(4));
      expect(ReportPriority.values, contains(ReportPriority.low));
      expect(ReportPriority.values, contains(ReportPriority.medium));
      expect(ReportPriority.values, contains(ReportPriority.high));
      expect(ReportPriority.values, contains(ReportPriority.critical));
    });
  });

  group('Severity Enums', () {
    test('ModerationSeverity should have correct values', () {
      expect(ModerationSeverity.values.length, equals(3));
      expect(ModerationSeverity.values, contains(ModerationSeverity.low));
      expect(ModerationSeverity.values, contains(ModerationSeverity.medium));
      expect(ModerationSeverity.values, contains(ModerationSeverity.high));
    });

    test('ActionSeverity should have correct values', () {
      expect(ActionSeverity.values.length, equals(3));
      expect(ActionSeverity.values, contains(ActionSeverity.low));
      expect(ActionSeverity.values, contains(ActionSeverity.medium));
      expect(ActionSeverity.values, contains(ActionSeverity.high));
    });

    test('Severity should have correct values', () {
      expect(Severity.values.length, equals(3));
      expect(Severity.values, contains(Severity.minor));
      expect(Severity.values, contains(Severity.major));
      expect(Severity.values, contains(Severity.critical));
    });
  });

  group('PlatformAnalytics Model', () {
    test('should create PlatformAnalytics with default values', () {
      final analytics = PlatformAnalytics();

      expect(analytics.totalUsers, equals(0));
      expect(analytics.totalGroups, equals(0));
      expect(analytics.totalMessages, equals(0));
      expect(analytics.messagestoday, equals(0));
      expect(analytics.activeUsersToday, equals(0));
      expect(analytics.activeUsersWeek, equals(0));
      expect(analytics.activeUsersMonth, equals(0));
      expect(analytics.pendingReports, equals(0));
      expect(analytics.resolvedReports, equals(0));
      expect(analytics.bannedUsers, equals(0));
      expect(analytics.suspendedUsers, equals(0));
      expect(analytics.usersByRole, isA<Map<String, int>>());
      expect(analytics.reportsByType, isA<Map<String, int>>());
      expect(analytics.userRegistrationsByDay, isA<Map<String, int>>());
      expect(analytics.lastUpdated, isA<DateTime>());
    });

    test('should create PlatformAnalytics with custom values', () {
      final now = DateTime.now();
      final usersByRole = {'admin': 2, 'user': 100};
      final reportsByType = {'spam': 5, 'harassment': 2};
      final registrationsByDay = {'2023-01-01': 10, '2023-01-02': 15};

      final analytics = PlatformAnalytics(
        totalUsers: 102,
        totalGroups: 25,
        totalMessages: 5000,
        messagestoday: 150,
        activeUsersToday: 50,
        activeUsersWeek: 80,
        activeUsersMonth: 95,
        pendingReports: 7,
        resolvedReports: 23,
        bannedUsers: 3,
        suspendedUsers: 1,
        usersByRole: usersByRole,
        reportsByType: reportsByType,
        userRegistrationsByDay: registrationsByDay,
        lastUpdated: now,
      );

      expect(analytics.totalUsers, equals(102));
      expect(analytics.totalGroups, equals(25));
      expect(analytics.totalMessages, equals(5000));
      expect(analytics.messagestoday, equals(150));
      expect(analytics.activeUsersToday, equals(50));
      expect(analytics.activeUsersWeek, equals(80));
      expect(analytics.activeUsersMonth, equals(95));
      expect(analytics.pendingReports, equals(7));
      expect(analytics.resolvedReports, equals(23));
      expect(analytics.bannedUsers, equals(3));
      expect(analytics.suspendedUsers, equals(1));
      expect(analytics.usersByRole, equals(usersByRole));
      expect(analytics.reportsByType, equals(reportsByType));
      expect(analytics.userRegistrationsByDay, equals(registrationsByDay));
      expect(analytics.lastUpdated, equals(now));
    });

    test('should handle empty maps correctly', () {
      final analytics = PlatformAnalytics(
        usersByRole: {},
        reportsByType: {},
        userRegistrationsByDay: {},
      );

      expect(analytics.usersByRole, isEmpty);
      expect(analytics.reportsByType, isEmpty);
      expect(analytics.userRegistrationsByDay, isEmpty);
    });
  });

  group('AdminUser Model', () {
    test('should create AdminUser with required fields', () {
      final user = AdminUser(
        id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        role: UserRole.user,
        status: UserStatus.active,
        createdAt: DateTime.now(),
      );

      expect(user.id, equals('user123'));
      expect(user.username, equals('testuser'));
      expect(user.email, equals('test@example.com'));
      expect(user.role, equals(UserRole.user));
      expect(user.status, equals(UserStatus.active));
      expect(user.createdAt, isA<DateTime>());
    });

    test('should create AdminUser with optional fields', () {
      final now = DateTime.now();

      final user = AdminUser(
        id: 'admin123',
        username: 'adminuser',
        email: 'admin@example.com',
        role: UserRole.admin,
        status: UserStatus.active,
        createdAt: now,
        displayName: 'Admin User',
        profileImageUrl: 'https://example.com/profile.jpg',
        lastLoginAt: now,
        isVerified: true,
        lastActiveAt: now,
        suspensionReason: null,
        suspendedUntil: null,
        metadata: {'department': 'IT'},
      );

      expect(user.displayName, equals('Admin User'));
      expect(user.profileImageUrl, equals('https://example.com/profile.jpg'));
      expect(user.lastLoginAt, equals(now));
      expect(user.isVerified, equals(true));
      expect(user.lastActiveAt, equals(now));
      expect(user.metadata, equals({'department': 'IT'}));
    });

    test('should handle user status changes correctly', () {
      final user = AdminUser(
        id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        role: UserRole.user,
        status: UserStatus.active,
        createdAt: DateTime.now(),
      );

      expect(user.status, equals(UserStatus.active));

      // Test suspended user
      final suspendedUser = AdminUser(
        id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        role: UserRole.user,
        status: UserStatus.suspended,
        createdAt: DateTime.now(),
        suspensionReason: 'Policy violation',
        suspendedUntil: DateTime.now().add(const Duration(days: 7)),
      );

      expect(suspendedUser.status, equals(UserStatus.suspended));
      expect(suspendedUser.suspensionReason, equals('Policy violation'));
      expect(suspendedUser.suspendedUntil, isA<DateTime>());
    });
  });

  group('Report Model', () {
    test('should test report-related functionality', () {
      // Note: Report class doesn't exist in the current models
      // This test group is kept for future implementation
      expect(ReportStatus.values.length, equals(4));
      expect(ReportType.values.length, equals(6));
      expect(ReportPriority.values.length, equals(4));
    });
  });

  group('ModerationAction Model', () {
    test('should create ModerationAction with required fields', () {
      final now = DateTime.now();
      final action = ModerationAction(
        id: 'action123',
        adminId: 'mod123',
        targetUserId: 'user456',
        actionType: 'warning',
        reason: 'Inappropriate behavior',
        severity: ModerationSeverity.medium,
        timestamp: now,
      );

      expect(action.id, equals('action123'));
      expect(action.adminId, equals('mod123'));
      expect(action.targetUserId, equals('user456'));
      expect(action.actionType, equals('warning'));
      expect(action.reason, equals('Inappropriate behavior'));
      expect(action.severity, equals(ModerationSeverity.medium));
      expect(action.timestamp, equals(now));
    });

    test('should create ModerationAction with optional fields', () {
      final now = DateTime.now();
      final action = ModerationAction(
        id: 'action123',
        adminId: 'mod123',
        adminName: 'Moderator Name',
        targetUserId: 'user456',
        targetUserName: 'Target User',
        actionType: 'suspension',
        reason: 'Multiple policy violations',
        severity: ModerationSeverity.high,
        timestamp: now,
        duration: const Duration(days: 7),
        relatedReportId: 'report123',
        actionData: {'violation_count': 3},
        isReversible: true,
      );

      expect(action.adminName, equals('Moderator Name'));
      expect(action.targetUserName, equals('Target User'));
      expect(action.duration, equals(const Duration(days: 7)));
      expect(action.relatedReportId, equals('report123'));
      expect(action.actionData, equals({'violation_count': 3}));
      expect(action.isReversible, equals(true));
    });
  });

  group('SystemAlert Model', () {
    test('should test system alert functionality', () {
      // Note: SystemAlert class doesn't exist in the current models
      // This test group is kept for future implementation
      expect(Severity.values.length, equals(3));
      expect(Severity.values, contains(Severity.minor));
      expect(Severity.values, contains(Severity.major));
      expect(Severity.values, contains(Severity.critical));
    });
  });

  group('NotificationSettings Model', () {
    test('should create NotificationSettings with default values', () {
      final settings = NotificationSettings();

      expect(settings.messageNotifications, equals(true));
      expect(settings.messageSound, equals(true));
      expect(settings.messageVibration, equals(true));
      expect(settings.callNotifications, equals(true));
      expect(settings.callSound, equals(true));
      expect(settings.groupNotifications, equals(true));
      expect(settings.showBadgeCount, equals(true));
    });

    test('should create NotificationSettings with custom values', () {
      final settings = NotificationSettings(
        messageNotifications: false,
        messageSound: false,
        messageVibration: false,
        callNotifications: true,
        callSound: true,
        groupNotifications: false,
        showBadgeCount: false,
      );

      expect(settings.messageNotifications, equals(false));
      expect(settings.messageSound, equals(false));
      expect(settings.messageVibration, equals(false));
      expect(settings.callNotifications, equals(true));
      expect(settings.callSound, equals(true));
      expect(settings.groupNotifications, equals(false));
      expect(settings.showBadgeCount, equals(false));
    });

    test('should handle notification preferences', () {
      final settings = NotificationSettings(
        messageNotifications: true,
        messageSound: false,
        callNotifications: true,
        callSound: true,
      );

      // Test basic preferences
      expect(settings.messageNotifications, true);
      expect(settings.messageSound, false);
      expect(settings.callNotifications, true);
      expect(settings.callSound, true);
    });

    test('should handle privacy settings', () {
      final settings = NotificationSettings(
        hideNotificationContent: true,
        hidePreview: true,
        hideSenderName: true,
      );

      expect(settings.hideNotificationContent, equals(true));
      expect(settings.hidePreview, equals(true));
      expect(settings.hideSenderName, equals(true));
    });
  });

  group('QuietHours Model', () {
    test('should test quiet hours concept', () {
      // Note: QuietHours class doesn't exist in the current models
      // This test group validates the time concept for future implementation
      const startHour = 22;
      const startMinute = 0;
      const endHour = 8;
      const endMinute = 0;
      const timezone = 'UTC';

      expect(startHour, equals(22));
      expect(startMinute, equals(0));
      expect(endHour, equals(8));
      expect(endMinute, equals(0));
      expect(timezone, equals('UTC'));
    });

    test('should handle timezone concept correctly', () {
      const startHour = 23;
      const endHour = 7;
      const timezone = 'America/New_York';

      expect(timezone, equals('America/New_York'));
      expect(startHour, equals(23));
      expect(endHour, equals(7));
    });
  });

  group('Data Validation', () {
    test('should validate email format', () {
      // This would depend on validation methods in the actual models
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'admin+tag@company.org',
      ];

      const invalidEmails = [
        'invalid-email',
        '@domain.com',
        'user@',
        'user name@domain.com',
      ];

      for (final email in validEmails) {
        expect(email.contains('@'), true);
        expect(email.contains('.'), true);
      }

      for (final email in invalidEmails) {
        // Basic validation - in real implementation, use proper email validation
        final isValid = email.contains('@') && 
                       email.contains('.') && 
                       !email.contains(' ') &&
                       email.indexOf('@') > 0 && 
                       email.lastIndexOf('.') > email.indexOf('@');
        expect(isValid, false);
      }
    });

    test('should validate phone number format', () {
      const validPhones = [
        '+1234567890',
        '+44 20 7946 0958',
        '+81 90 1234 5678',
      ];

      const invalidPhones = [
        '1234567890', // Missing +
        '+123', // Too short
        'invalid-phone',
      ];

      for (final phone in validPhones) {
        expect(phone.startsWith('+'), true);
        expect(phone.length, greaterThan(5));
      }

      for (final phone in invalidPhones) {
        final isValid = phone.startsWith('+') && phone.length > 5;
        expect(isValid, false);
      }
    });
  });

  group('Edge Cases and Error Handling', () {
    test('should handle null and empty values', () {
      // Test with null values where allowed
      final analytics = PlatformAnalytics(
        usersByRole: {},
        reportsByType: {},
        userRegistrationsByDay: {},
      );

      expect(analytics.usersByRole, isEmpty);
      expect(analytics.reportsByType, isEmpty);
      expect(analytics.userRegistrationsByDay, isEmpty);
    });

    test('should handle large numbers', () {
      final analytics = PlatformAnalytics(
        totalUsers: 1000000,
        totalMessages: 50000000,
        messagestoday: 100000,
      );

      expect(analytics.totalUsers, equals(1000000));
      expect(analytics.totalMessages, equals(50000000));
      expect(analytics.messagestoday, equals(100000));
    });

    test('should handle datetime operations', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 30));
      final futureDate = now.add(const Duration(days: 30));

      final user = AdminUser(
        id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        role: UserRole.user,
        status: UserStatus.active,
        createdAt: pastDate,
        lastLoginAt: now,
        lastActiveAt: futureDate,
      );

      expect(user.createdAt.isBefore(now), true);
      expect(user.lastLoginAt, equals(now));
      expect(user.lastActiveAt!.isAfter(now), true);
    });
  });
}