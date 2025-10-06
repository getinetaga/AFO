import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../models/notification_settings.dart';
import 'notification_service.dart';

// Notification manager handles scheduling, batching, and management of notifications
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  NotificationSettings? _settings;
  
  // Notification queues for batching
  final Map<String, List<PendingNotification>> _messageQueue = {};
  final Map<String, Timer> _batchTimers = {};
  
  // Active notifications tracking
  final Map<int, ActiveNotification> _activeNotifications = {};
  int _nextNotificationId = 1000;
  
  // Do Not Disturb tracking
  Timer? _dndTimer;
  
  // Badge count
  int _badgeCount = 0;

  // Initialize notification manager
  Future<bool> initialize() async {
    // Initialize notification service
    final serviceInitialized = await _notificationService.initialize();
    if (!serviceInitialized) {
      return false;
    }

    // Load notification settings
    await _loadSettings();
    
    // Set up Do Not Disturb monitoring
    _setupDoNotDisturbMonitoring();
    
  debugPrint('NotificationManager: Initialized successfully');
    return true;
  }

  // Load notification settings
  Future<void> _loadSettings() async {
    try {
      _settings = await NotificationSettingsManager.loadSettings();
    } catch (e) {
  debugPrint('Failed to load notification settings: $e');
      _settings = NotificationSettings(); // Use defaults
    }
  }

  // Refresh settings
  Future<void> refreshSettings() async {
    NotificationSettingsManager.clearCache();
    await _loadSettings();
  }

  // Show message notification with batching
  Future<void> showMessageNotification({
    required String senderName,
    required String senderId,
    required String messageContent,
    required String chatRoomId,
    required String messageId,
    String? senderAvatar,
    bool isGroup = false,
    String? groupName,
    DateTime? timestamp,
  }) async {
    if (!await _shouldShowNotification(NotificationType.message)) {
      return;
    }

    final notification = PendingNotification(
      id: _getNextNotificationId(),
      type: NotificationType.message,
      title: isGroup ? '$senderName in $groupName' : senderName,
      body: messageContent,
      timestamp: timestamp ?? DateTime.now(),
      payload: {
        'type': 'message',
        'chatRoomId': chatRoomId,
        'messageId': messageId,
        'senderId': senderId,
        'senderName': senderName,
        'isGroup': isGroup.toString(),
        if (groupName != null) 'groupName': groupName,
      },
      senderName: senderName,
      chatRoomId: chatRoomId,
    );

    // Add to batch queue
    await _addToBatch(notification);
  }

  // Show call notification (immediate, no batching)
  Future<void> showCallNotification({
    required String callerName,
    required String callerId,
    required String callId,
    required bool isVideoCall,
    String? callerAvatar,
  }) async {
    if (!await _shouldShowNotification(NotificationType.call)) {
      return;
    }

    final notificationId = _getNextNotificationId();
    final title = 'Incoming ${isVideoCall ? 'Video' : 'Voice'} Call';
    final body = 'From $callerName';

    await _notificationService.showCallNotification(
      callerName: callerName,
      callId: callId,
      isVideoCall: isVideoCall,
      callerAvatar: callerAvatar,
    );

    // Track active notification
    _trackActiveNotification(ActiveNotification(
      id: notificationId,
      type: NotificationType.call,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      chatRoomId: callId,
    ));

    _incrementBadgeCount();
  }

  // Show group activity notification
  Future<void> showGroupActivityNotification({
    required String groupName,
    required String groupId,
    required String activity,
    required String actorName,
    required String actorId,
  }) async {
    if (!await _shouldShowNotification(NotificationType.groupActivity)) {
      return;
    }

    // Check if we should only show for mentions
    if (_settings?.groupMentionOnly == true && !activity.contains('@')) {
      return;
    }

    final notificationId = _getNextNotificationId();

    await _notificationService.showGroupActivityNotification(
      groupName: groupName,
      activity: activity,
      actorName: actorName,
      chatRoomId: groupId,
    );

    _trackActiveNotification(ActiveNotification(
      id: notificationId,
      type: NotificationType.groupActivity,
      title: groupName,
      body: '$actorName $activity',
      timestamp: DateTime.now(),
      chatRoomId: groupId,
    ));

    _incrementBadgeCount();
  }

  // Show media notification
  Future<void> showMediaNotification({
    required String senderName,
    required String senderId,
    required String mediaType,
    required String chatRoomId,
    required String messageId,
    bool isGroup = false,
    String? groupName,
  }) async {
    if (!await _shouldShowNotification(NotificationType.mediaReceived)) {
      return;
    }

    final notificationId = _getNextNotificationId();

    await _notificationService.showMediaNotification(
      senderName: senderName,
      mediaType: mediaType,
      chatRoomId: chatRoomId,
      messageId: messageId,
      isGroup: isGroup,
      groupName: groupName,
    );

    _trackActiveNotification(ActiveNotification(
      id: notificationId,
      type: NotificationType.mediaReceived,
      title: isGroup ? '$senderName in $groupName' : senderName,
      body: 'Sent a $mediaType',
      timestamp: DateTime.now(),
      chatRoomId: chatRoomId,
    ));

    _incrementBadgeCount();
  }

  // Add notification to batch queue
  Future<void> _addToBatch(PendingNotification notification) async {
    final chatRoomId = notification.chatRoomId;
    
    // Initialize queue for this chat room if needed
    if (!_messageQueue.containsKey(chatRoomId)) {
      _messageQueue[chatRoomId] = [];
    }
    
    // Add notification to queue
    _messageQueue[chatRoomId]!.add(notification);
    
    // Cancel existing timer for this chat room
    _batchTimers[chatRoomId]?.cancel();
    
    // Set new timer for batching (2 seconds delay)
    _batchTimers[chatRoomId] = Timer(const Duration(seconds: 2), () {
      _processBatch(chatRoomId);
    });
  }

  // Process batched notifications
  Future<void> _processBatch(String chatRoomId) async {
    final notifications = _messageQueue[chatRoomId];
    if (notifications == null || notifications.isEmpty) {
      return;
    }

    // Remove from queue
    _messageQueue.remove(chatRoomId);
    _batchTimers.remove(chatRoomId);

    if (notifications.length == 1) {
      // Single notification
      final notification = notifications.first;
      await _showSingleNotification(notification);
    } else {
      // Multiple notifications - show as summary
      await _showBatchedNotification(chatRoomId, notifications);
    }
  }

  // Show single notification
  Future<void> _showSingleNotification(PendingNotification notification) async {
    await _notificationService.showMessageNotification(
      senderName: notification.senderName,
      messageContent: notification.body,
      chatRoomId: notification.chatRoomId,
      messageId: notification.payload['messageId'] ?? '',
      isGroup: notification.payload['isGroup'] == 'true',
      groupName: notification.payload['groupName'],
    );

    _trackActiveNotification(ActiveNotification(
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      timestamp: notification.timestamp,
      chatRoomId: notification.chatRoomId,
    ));

    _incrementBadgeCount();
  }

  // Show batched notification summary
  Future<void> _showBatchedNotification(
    String chatRoomId, 
    List<PendingNotification> notifications,
  ) async {
    final isGroup = notifications.first.payload['isGroup'] == 'true';
    final groupName = notifications.first.payload['groupName'];
    final senderCount = notifications.map((n) => n.senderName).toSet().length;
    
    String title;
    String body;
    
    if (isGroup) {
      title = groupName ?? 'Group Chat';
      if (senderCount == 1) {
        body = '${notifications.length} new messages from ${notifications.first.senderName}';
      } else {
        body = '${notifications.length} new messages from $senderCount people';
      }
    } else {
      title = notifications.first.senderName;
      body = '${notifications.length} new messages';
    }

    final notificationId = _getNextNotificationId();

    // Create a summary notification
    await _notificationService.showLocalNotification(
      title: title,
      body: body,
      payload: {
        'type': 'message',
        'chatRoomId': chatRoomId,
        'messageCount': notifications.length.toString(),
      },
      notificationType: NotificationType.message,
      priority: NotificationPriority.high,
    );

    _trackActiveNotification(ActiveNotification(
      id: notificationId,
      type: NotificationType.message,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      chatRoomId: chatRoomId,
      messageCount: notifications.length,
    ));

    _incrementBadgeCount(notifications.length);
  }

  // Check if notification should be shown
  Future<bool> _shouldShowNotification(NotificationType type) async {
    if (_settings == null) {
      await _loadSettings();
    }

    // Check global settings
    if (_settings?.notificationsEnabled != true) {
      return false;
    }

    // Check Do Not Disturb
    if (_settings?.isInDoNotDisturbPeriod == true) {
      return false;
    }

    // Check type-specific settings
    switch (type) {
      case NotificationType.message:
        return _settings?.messageNotifications == true;
      case NotificationType.call:
        return _settings?.callNotifications == true;
      case NotificationType.groupActivity:
        return _settings?.groupNotifications == true;
      case NotificationType.mediaReceived:
        return _settings?.mediaNotifications == true;
      case NotificationType.messageDelivered:
        return _settings?.deliveryReceipts == true;
      case NotificationType.messageRead:
        return _settings?.readReceipts == true;
      case NotificationType.typing:
        return _settings?.typingIndicators == true;
      default:
        return _settings?.systemNotifications == true;
    }
  }

  // Track active notification
  void _trackActiveNotification(ActiveNotification notification) {
    _activeNotifications[notification.id] = notification;
    
    // Auto-remove after timeout
    Timer(Duration(seconds: _settings?.notificationTimeout ?? 5), () {
      _activeNotifications.remove(notification.id);
    });
  }

  // Clear notifications for specific chat room
  Future<void> clearNotificationsForChat(String chatRoomId) async {
    // Cancel pending batches
    _batchTimers[chatRoomId]?.cancel();
    _messageQueue.remove(chatRoomId);
    
    // Find and cancel active notifications
    final notificationsToRemove = _activeNotifications.values
        .where((n) => n.chatRoomId == chatRoomId)
        .toList();
    
    for (final notification in notificationsToRemove) {
      await _notificationService.cancelNotification(notification.id);
      _activeNotifications.remove(notification.id);
    }

    // Reset badge count if configured
    if (_settings?.resetBadgeOnOpen == true) {
      _resetBadgeCount();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    // Cancel all timers
    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    _batchTimers.clear();
    _messageQueue.clear();
    
    // Cancel all active notifications
    await _notificationService.cancelAllNotifications();
    _activeNotifications.clear();
    
    _resetBadgeCount();
  }

  // Setup Do Not Disturb monitoring
  void _setupDoNotDisturbMonitoring() {
    // Check every minute if DND status has changed
    _dndTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // This can be used to update UI or handle DND changes
      if (kDebugMode) {
        final inDnd = _settings?.isInDoNotDisturbPeriod ?? false;
        if (inDnd) {
          debugPrint('Currently in Do Not Disturb period');
        }
      }
    });
  }

  // Badge count management
  void _incrementBadgeCount([int count = 1]) {
    if (_settings?.showBadgeCount == true) {
      _badgeCount += count;
      _updateAppBadge();
    }
  }

  void _resetBadgeCount() {
    _badgeCount = 0;
    _updateAppBadge();
  }

  void _updateAppBadge() {
    // Update app icon badge (platform specific implementation needed)
    if (!kIsWeb && Platform.isIOS) {
      // iOS badge update
      // FlutterLocalNotificationsPlugin can handle this
    } else if (Platform.isAndroid) {
      // Android badge update (requires additional plugin)
    } else if (!kIsWeb && Platform.isAndroid) {
      // flutter_app_badger or similar
    }
  }

  // Getters
  int get badgeCount => _badgeCount;
  NotificationSettings? get settings => _settings;
  Map<int, ActiveNotification> get activeNotifications => Map.from(_activeNotifications);
  
  // Get next notification ID
  int _getNextNotificationId() {
    return _nextNotificationId++;
  }

  // Test notification (for debugging)
  Future<void> showTestNotification() async {
    await _notificationService.showLocalNotification(
      title: 'AFO Test',
      body: 'This is a test notification',
      notificationType: NotificationType.message,
    );
  }

  // Schedule notification for later
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? payload,
    NotificationType type = NotificationType.message,
  }) async {
    // This would require additional implementation for scheduled notifications
    // Using flutter_local_notifications scheduling features
  debugPrint('Scheduling notification for $scheduledTime: $title');
  }

  // Cancel scheduled notification
  Future<void> cancelScheduledNotification(int id) async {
    await _notificationService.cancelNotification(id);
  }

  // Get notification history (last 24 hours)
  List<ActiveNotification> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _activeNotifications.values
        .where((n) => n.timestamp.isAfter(yesterday))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Cleanup
  void dispose() {
    // Cancel all timers
    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    _dndTimer?.cancel();
    
    // Clear queues
    _batchTimers.clear();
    _messageQueue.clear();
    _activeNotifications.clear();
    
    _notificationService.dispose();
  }
}

// Pending notification model
class PendingNotification {
  final int id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final String senderName;
  final String chatRoomId;

  PendingNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.payload,
    required this.senderName,
    required this.chatRoomId,
  });
}

// Active notification model
class ActiveNotification {
  final int id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final String chatRoomId;
  final int messageCount;

  ActiveNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.chatRoomId,
    this.messageCount = 1,
  });

  @override
  String toString() {
    return 'ActiveNotification(id: $id, type: $type, title: $title, chatRoom: $chatRoomId)';
  }
}