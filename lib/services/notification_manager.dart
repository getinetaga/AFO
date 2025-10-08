import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../models/notification_settings.dart';
import 'notification_service.dart';

/// A comprehensive notification management system for the AFO chat application.
/// 
/// This class provides a centralized way to handle all types of notifications including:
/// - Message notifications with intelligent batching
/// - Call notifications (voice and video)
/// - Group activity notifications
/// - Media notifications
/// - Badge count management
/// - Do Not Disturb functionality
/// 
/// The manager implements a singleton pattern to ensure consistent notification
/// state across the application and provides batching capabilities to prevent
/// notification spam in active conversations.
/// 
/// Example usage:
/// ```dart
/// final manager = NotificationManager();
/// await manager.initialize();
/// 
/// await manager.showMessageNotification(
///   senderName: 'John Doe',
///   senderId: 'user123',
///   messageContent: 'Hello there!',
///   chatRoomId: 'room456',
///   messageId: 'msg789',
/// );
/// ```
class NotificationManager {
  /// Singleton instance of the NotificationManager
  static final NotificationManager _instance = NotificationManager._internal();
  
  /// Factory constructor that returns the singleton instance
  factory NotificationManager() => _instance;
  
  /// Private constructor for singleton pattern
  NotificationManager._internal();

  /// Core notification service that handles platform-specific implementations
  final NotificationService _notificationService = NotificationService();
  
  /// Current notification settings loaded from storage
  NotificationSettings? _settings;
  
  /// Message queues for batching notifications by chat room
  /// Key: chatRoomId, Value: List of pending notifications
  final Map<String, List<PendingNotification>> _messageQueue = {};
  
  /// Timers for managing batch delays per chat room
  /// Key: chatRoomId, Value: Timer for that chat room's batch
  final Map<String, Timer> _batchTimers = {};
  
  /// Currently active notifications for tracking and cleanup
  /// Key: notificationId, Value: ActiveNotification details
  final Map<int, ActiveNotification> _activeNotifications = {};
  
  /// Counter for generating unique notification IDs
  int _nextNotificationId = 1000;
  
  /// Timer for monitoring Do Not Disturb status changes
  Timer? _dndTimer;
  
  /// Current application badge count
  int _badgeCount = 0;

  /// Initializes the notification manager and all its dependencies.
  /// 
  /// This method must be called before using any other notification functionality.
  /// It performs the following initialization steps:
  /// 1. Initializes the underlying notification service
  /// 2. Loads user notification settings from storage
  /// 3. Sets up Do Not Disturb monitoring
  /// 
  /// Returns `true` if initialization was successful, `false` otherwise.
  /// 
  /// Example:
  /// ```dart
  /// final manager = NotificationManager();
  /// if (await manager.initialize()) {
  ///   print('Notification manager ready');
  /// } else {
  ///   print('Failed to initialize notifications');
  /// }
  /// ```
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

  /// Loads notification settings from persistent storage.
  /// 
  /// If settings cannot be loaded (e.g., first run, corrupted data),
  /// defaults to standard notification settings.
  /// 
  /// This method is called internally during initialization and
  /// when settings need to be refreshed.
  Future<void> _loadSettings() async {
    try {
      _settings = await NotificationSettingsManager.loadSettings();
    } catch (e) {
      debugPrint('Failed to load notification settings: $e');
      _settings = NotificationSettings(); // Use defaults
    }
  }

  /// Refreshes notification settings by clearing cache and reloading.
  /// 
  /// Call this method when notification settings have been changed
  /// in the app settings to ensure the manager uses the latest configuration.
  /// 
  /// Example:
  /// ```dart
  /// // After user changes notification settings
  /// await NotificationManager().refreshSettings();
  /// ```
  Future<void> refreshSettings() async {
    NotificationSettingsManager.clearCache();
    await _loadSettings();
  }

  /// Shows a message notification with intelligent batching.
  /// 
  /// This method handles both individual and group chat messages. Messages
  /// from the same chat room are automatically batched together if they
  /// arrive within a 2-second window to prevent notification spam.
  /// 
  /// For group chats, the notification will show both the sender name
  /// and group name for better context.
  /// 
  /// Parameters:
  /// - [senderName]: Display name of the message sender
  /// - [senderId]: Unique identifier of the sender
  /// - [messageContent]: The actual message text content
  /// - [chatRoomId]: Unique identifier of the chat room
  /// - [messageId]: Unique identifier of this specific message
  /// - [senderAvatar]: Optional avatar URL/path for the sender
  /// - [isGroup]: Whether this is a group chat message (default: false)
  /// - [groupName]: Name of the group (required if isGroup is true)
  /// - [timestamp]: Message timestamp (defaults to current time)
  /// 
  /// Example:
  /// ```dart
  /// await manager.showMessageNotification(
  ///   senderName: 'Alice Smith',
  ///   senderId: 'alice123',
  ///   messageContent: 'Hey everyone, how\'s it going?',
  ///   chatRoomId: 'team-general',
  ///   messageId: 'msg_456789',
  ///   isGroup: true,
  ///   groupName: 'Team General',
  /// );
  /// ```
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

    // Create pending notification with all necessary metadata
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

    // Add notification to batching queue for intelligent grouping
    await _addToBatch(notification);
  }

  /// Shows an immediate call notification (bypasses batching).
  /// 
  /// Call notifications are time-sensitive and are displayed immediately
  /// without any batching delay. Supports both voice and video calls
  /// with appropriate styling and actions.
  /// 
  /// Parameters:
  /// - [callerName]: Display name of the person calling
  /// - [callerId]: Unique identifier of the caller
  /// - [callId]: Unique identifier for this call session
  /// - [isVideoCall]: Whether this is a video call (affects icon and text)
  /// - [callerAvatar]: Optional avatar URL/path for the caller
  /// 
  /// Example:
  /// ```dart
  /// await manager.showCallNotification(
  ///   callerName: 'John Doe',
  ///   callerId: 'john123',
  ///   callId: 'call_789',
  ///   isVideoCall: true,
  ///   callerAvatar: 'https://example.com/avatars/john.jpg',
  /// );
  /// ```
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

    // Show call notification immediately (no batching for calls)
    await _notificationService.showCallNotification(
      callerName: callerName,
      callId: callId,
      isVideoCall: isVideoCall,
      callerAvatar: callerAvatar,
    );

    // Track active notification for management and cleanup
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

  /// Shows a group activity notification.
  /// 
  /// Displays notifications for group activities such as member joins,
  /// leaves, role changes, etc. Can be configured to only show notifications
  /// for mentions if the user has enabled mention-only mode.
  /// 
  /// Parameters:
  /// - [groupName]: Name of the group where activity occurred
  /// - [groupId]: Unique identifier of the group
  /// - [activity]: Description of the activity (e.g., "joined the group")
  /// - [actorName]: Name of the person who performed the activity
  /// - [actorId]: Unique identifier of the person who performed the activity
  /// 
  /// Example:
  /// ```dart
  /// await manager.showGroupActivityNotification(
  ///   groupName: 'Development Team',
  ///   groupId: 'dev-team-123',
  ///   activity: 'joined the group',
  ///   actorName: 'Sarah Wilson',
  ///   actorId: 'sarah456',
  /// );
  /// ```
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

    // Check if user has configured to only show notifications for mentions
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

    // Track the notification for cleanup and management
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

  /// Shows a media notification when someone sends media content.
  /// 
  /// Displays notifications for media files like images, videos, documents,
  /// or audio files. The notification includes the media type for context.
  /// 
  /// Parameters:
  /// - [senderName]: Display name of the person who sent the media
  /// - [senderId]: Unique identifier of the sender
  /// - [mediaType]: Type of media (e.g., "photo", "video", "document")
  /// - [chatRoomId]: Unique identifier of the chat room
  /// - [messageId]: Unique identifier of the message containing the media
  /// - [isGroup]: Whether this is from a group chat (default: false)
  /// - [groupName]: Name of the group (if applicable)
  /// 
  /// Example:
  /// ```dart
  /// await manager.showMediaNotification(
  ///   senderName: 'Mike Johnson',
  ///   senderId: 'mike789',
  ///   mediaType: 'photo',
  ///   chatRoomId: 'chat-456',
  ///   messageId: 'msg-media-123',
  ///   isGroup: false,
  /// );
  /// ```
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

    // Track notification with appropriate title based on chat type
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

  /// Adds a notification to the batching queue for intelligent grouping.
  /// 
  /// This internal method manages the batching logic that prevents notification
  /// spam in active conversations. Messages from the same chat room are grouped
  /// together if they arrive within a 2-second window.
  /// 
  /// The batching process:
  /// 1. Adds notification to the chat room's queue
  /// 2. Cancels any existing timer for that chat room
  /// 3. Sets a new 2-second timer for processing the batch
  /// 
  /// [notification] The pending notification to add to the batch queue
  Future<void> _addToBatch(PendingNotification notification) async {
    final chatRoomId = notification.chatRoomId;
    
    // Initialize queue for this chat room if it doesn't exist
    if (!_messageQueue.containsKey(chatRoomId)) {
      _messageQueue[chatRoomId] = [];
    }
    
    // Add notification to the appropriate chat room queue
    _messageQueue[chatRoomId]!.add(notification);
    
    // Cancel any existing batch timer for this chat room
    _batchTimers[chatRoomId]?.cancel();
    
    // Set new timer for batching (2 seconds delay allows for grouping)
    _batchTimers[chatRoomId] = Timer(const Duration(seconds: 2), () {
      _processBatch(chatRoomId);
    });
  }

  /// Processes a batch of notifications for a specific chat room.
  /// 
  /// This internal method handles the actual display of batched notifications.
  /// It decides whether to show individual notifications or create a summary
  /// notification based on the number of pending notifications.
  /// 
  /// Batching logic:
  /// - Single notification: Shows individual notification with full details
  /// - Multiple notifications: Shows summary notification with count and senders
  /// 
  /// [chatRoomId] The chat room whose notification batch should be processed
  Future<void> _processBatch(String chatRoomId) async {
    final notifications = _messageQueue[chatRoomId];
    if (notifications == null || notifications.isEmpty) {
      return;
    }

    // Clean up the processed batch from queues
    _messageQueue.remove(chatRoomId);
    _batchTimers.remove(chatRoomId);

    if (notifications.length == 1) {
      // Single notification - show with full details
      final notification = notifications.first;
      await _showSingleNotification(notification);
    } else {
      // Multiple notifications - show as intelligent summary
      await _showBatchedNotification(chatRoomId, notifications);
    }
  }

  /// Displays a single notification with full message details.
  /// 
  /// This internal method handles the display of individual notifications
  /// that weren't batched with other messages. It shows the complete
  /// message content and sender information.
  /// 
  /// [notification] The pending notification to display
  Future<void> _showSingleNotification(PendingNotification notification) async {
    await _notificationService.showMessageNotification(
      senderName: notification.senderName,
      messageContent: notification.body,
      chatRoomId: notification.chatRoomId,
      messageId: notification.payload['messageId'] ?? '',
      isGroup: notification.payload['isGroup'] == 'true',
      groupName: notification.payload['groupName'],
    );

    // Track the active notification for management
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

  /// Displays a batched notification summary for multiple messages.
  /// 
  /// This internal method creates intelligent summary notifications when
  /// multiple messages arrive in quick succession from the same chat room.
  /// The summary includes message count and sender information.
  /// 
  /// Summary format varies based on context:
  /// - Group chats: Shows group name, message count, and sender count
  /// - Direct chats: Shows sender name and message count
  /// - Single sender: "X new messages from [Name]"
  /// - Multiple senders: "X new messages from Y people"
  /// 
  /// [chatRoomId] The chat room ID for the batched notifications
  /// [notifications] List of notifications to summarize
  Future<void> _showBatchedNotification(
    String chatRoomId, 
    List<PendingNotification> notifications,
  ) async {
    final isGroup = notifications.first.payload['isGroup'] == 'true';
    final groupName = notifications.first.payload['groupName'];
    final senderCount = notifications.map((n) => n.senderName).toSet().length;
    
    String title;
    String body;
    
    // Generate appropriate title and body text based on chat context
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

    // Create a comprehensive summary notification
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

    // Track the summary notification
    _trackActiveNotification(ActiveNotification(
      id: notificationId,
      type: NotificationType.message,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      chatRoomId: chatRoomId,
      messageCount: notifications.length,
    ));

    // Increment badge count by the number of messages in the batch
    _incrementBadgeCount(notifications.length);
  }

  /// Determines whether a notification should be displayed based on settings.
  /// 
  /// This internal method checks multiple conditions to decide if a notification
  /// should be shown to the user:
  /// 
  /// 1. Global notification settings
  /// 2. Do Not Disturb status
  /// 3. Type-specific notification preferences
  /// 4. Time-based restrictions
  /// 
  /// Returns `true` if the notification should be shown, `false` otherwise.
  /// 
  /// [type] The type of notification to check (message, call, etc.)
  Future<bool> _shouldShowNotification(NotificationType type) async {
    if (_settings == null) {
      await _loadSettings();
    }

    // Check if notifications are globally disabled
    if (_settings?.notificationsEnabled != true) {
      return false;
    }

    // Respect Do Not Disturb settings
    if (_settings?.isInDoNotDisturbPeriod == true) {
      return false;
    }

    // Check type-specific notification preferences
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

  /// Tracks an active notification for management and cleanup.
  /// 
  /// This internal method adds a notification to the active notifications
  /// registry and sets up automatic cleanup after the configured timeout.
  /// This helps manage memory usage and provides cleanup capabilities.
  /// 
  /// The notification will be automatically removed from tracking after
  /// the timeout period specified in settings (default: 5 seconds).
  /// 
  /// [notification] The active notification to track
  void _trackActiveNotification(ActiveNotification notification) {
    _activeNotifications[notification.id] = notification;
    
    // Set up automatic cleanup after timeout to prevent memory leaks
    Timer(Duration(seconds: _settings?.notificationTimeout ?? 5), () {
      _activeNotifications.remove(notification.id);
    });
  }

  /// Clears all notifications for a specific chat room.
  /// 
  /// This method provides comprehensive cleanup for a specific chat:
  /// 1. Cancels any pending batched notifications
  /// 2. Removes notifications from the message queue
  /// 3. Cancels and removes active notifications from the system
  /// 4. Optionally resets the badge count
  /// 
  /// This is typically called when a user opens a chat room to
  /// clear notifications that are no longer relevant.
  /// 
  /// [chatRoomId] The unique identifier of the chat room to clear
  /// 
  /// Example:
  /// ```dart
  /// // User opened chat room, clear its notifications
  /// await NotificationManager().clearNotificationsForChat('room-123');
  /// ```
  Future<void> clearNotificationsForChat(String chatRoomId) async {
    // Cancel any pending batch operations for this chat
    _batchTimers[chatRoomId]?.cancel();
    _messageQueue.remove(chatRoomId);
    
    // Find all active notifications for this chat room
    final notificationsToRemove = _activeNotifications.values
        .where((n) => n.chatRoomId == chatRoomId)
        .toList();
    
    // Cancel each notification and remove from tracking
    for (final notification in notificationsToRemove) {
      await _notificationService.cancelNotification(notification.id);
      _activeNotifications.remove(notification.id);
    }

    // Reset badge count if user has configured this behavior
    if (_settings?.resetBadgeOnOpen == true) {
      _resetBadgeCount();
    }
  }

  /// Clears all notifications from the system.
  /// 
  /// This method performs a complete cleanup of all notification-related data:
  /// 1. Cancels all pending batch timers
  /// 2. Clears all message queues
  /// 3. Cancels all active notifications
  /// 4. Resets the badge count to zero
  /// 
  /// This is typically called when:
  /// - User manually clears all notifications
  /// - App is logging out or switching accounts
  /// - System-wide notification reset is needed
  /// 
  /// Example:
  /// ```dart
  /// // Clear all notifications on logout
  /// await NotificationManager().clearAllNotifications();
  /// ```
  Future<void> clearAllNotifications() async {
    // Cancel all pending batch timers to prevent future notifications
    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    _batchTimers.clear();
    _messageQueue.clear();
    
    // Cancel all currently displayed notifications
    await _notificationService.cancelAllNotifications();
    _activeNotifications.clear();
    
    // Reset badge count to zero
    _resetBadgeCount();
  }

  /// Sets up periodic monitoring of Do Not Disturb status.
  /// 
  /// This internal method establishes a periodic timer that checks
  /// for changes in Do Not Disturb settings every minute. This allows
  /// the app to respond to DND changes and update UI accordingly.
  /// 
  /// The monitoring helps ensure that:
  /// - DND status changes are detected promptly
  /// - UI can be updated to reflect current DND state
  /// - Debug information is available during development
  /// 
  /// The timer runs throughout the app lifecycle and is cleaned up
  /// when the manager is disposed.
  void _setupDoNotDisturbMonitoring() {
    // Check every minute for Do Not Disturb status changes
    _dndTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Monitor DND status for UI updates and behavior changes
      if (kDebugMode) {
        final inDnd = _settings?.isInDoNotDisturbPeriod ?? false;
        if (inDnd) {
          debugPrint('Currently in Do Not Disturb period');
        }
      }
    });
  }

  /// Increments the application badge count by the specified amount.
  /// 
  /// Updates the badge count if badge display is enabled in settings
  /// and triggers a platform-specific badge update on the app icon.
  /// 
  /// [count] Number to increment the badge by (default: 1)
  void _incrementBadgeCount([int count = 1]) {
    if (_settings?.showBadgeCount == true) {
      _badgeCount += count;
      _updateAppBadge();
    }
  }

  /// Resets the application badge count to zero.
  /// 
  /// Clears the badge count and updates the app icon to remove
  /// any visible badge indicator.
  void _resetBadgeCount() {
    _badgeCount = 0;
    _updateAppBadge();
  }

  /// Updates the platform-specific app icon badge.
  /// 
  /// This internal method handles the platform-specific implementation
  /// for updating the app icon badge count. Different platforms have
  /// different APIs and capabilities for badge management.
  /// 
  /// Platform support:
  /// - iOS: Native badge support through FlutterLocalNotificationsPlugin
  /// - Android: Requires additional plugins (e.g., flutter_app_badger)
  /// - Web: Limited badge support depending on browser
  void _updateAppBadge() {
    // Platform-specific badge update implementation
    if (!kIsWeb && Platform.isIOS) {
      // iOS has native badge support through the notification plugin
      // Implementation would use FlutterLocalNotificationsPlugin
    } else if (Platform.isAndroid) {
      // Android badge updates require additional plugins
      // Implementation would use flutter_app_badger or similar
    } else if (!kIsWeb && Platform.isAndroid) {
      // Alternative Android badge implementation
      // Could use flutter_app_badger or other badge plugins
    }
    // Note: Actual implementation depends on chosen badge plugin
  }

  /// Gets the current application badge count.
  /// 
  /// Returns the current number displayed on the app icon badge.
  /// This count represents unread notifications across all chats.
  int get badgeCount => _badgeCount;
  
  /// Gets the current notification settings.
  /// 
  /// Returns the loaded notification settings or null if not yet loaded.
  /// Use [refreshSettings] to reload settings if needed.
  NotificationSettings? get settings => _settings;
  
  /// Gets a copy of all currently active notifications.
  /// 
  /// Returns a map of notification IDs to their corresponding
  /// ActiveNotification objects. This is a copy to prevent
  /// external modification of the internal tracking data.
  Map<int, ActiveNotification> get activeNotifications => Map.from(_activeNotifications);
  
  /// Generates the next unique notification ID.
  /// 
  /// This internal method provides sequential notification IDs
  /// starting from 1000 to avoid conflicts with other parts
  /// of the application that might use notification IDs.
  /// 
  /// Returns a unique integer ID for the next notification.
  int _getNextNotificationId() {
    return _nextNotificationId++;
  }

  /// Displays a test notification for debugging purposes.
  /// 
  /// This method shows a simple test notification to verify that
  /// the notification system is working correctly. Useful for:
  /// - Testing notification permissions
  /// - Verifying notification appearance
  /// - Debugging notification issues
  /// 
  /// Example:
  /// ```dart
  /// // Test if notifications are working
  /// await NotificationManager().showTestNotification();
  /// ```
  Future<void> showTestNotification() async {
    await _notificationService.showLocalNotification(
      title: 'AFO Test',
      body: 'This is a test notification',
      notificationType: NotificationType.message,
    );
  }

  /// Schedules a notification to be displayed at a specific time.
  /// 
  /// This method allows scheduling notifications for future delivery.
  /// Useful for reminders, delayed messages, or time-based alerts.
  /// 
  /// Note: This requires additional implementation using the
  /// flutter_local_notifications scheduling features.
  /// 
  /// Parameters:
  /// - [title]: The notification title
  /// - [body]: The notification body text
  /// - [scheduledTime]: When to display the notification
  /// - [payload]: Optional data to include with the notification
  /// - [type]: The type of notification (default: message)
  /// 
  /// Example:
  /// ```dart
  /// // Schedule a reminder for 1 hour from now
  /// await manager.scheduleNotification(
  ///   title: 'Meeting Reminder',
  ///   body: 'Team standup in 5 minutes',
  ///   scheduledTime: DateTime.now().add(Duration(hours: 1)),
  /// );
  /// ```
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? payload,
    NotificationType type = NotificationType.message,
  }) async {
    // This requires additional implementation for scheduled notifications
    // using flutter_local_notifications scheduling features
    debugPrint('Scheduling notification for $scheduledTime: $title');
  }

  /// Cancels a scheduled notification by its ID.
  /// 
  /// Removes a previously scheduled notification from the system
  /// so it will not be displayed at its scheduled time.
  /// 
  /// [id] The unique ID of the notification to cancel
  /// 
  /// Example:
  /// ```dart
  /// // Cancel a scheduled notification
  /// await manager.cancelScheduledNotification(12345);
  /// ```
  Future<void> cancelScheduledNotification(int id) async {
    await _notificationService.cancelNotification(id);
  }

  /// Gets a list of recent notifications from the last 24 hours.
  /// 
  /// Returns notifications that were displayed within the last 24 hours,
  /// sorted by timestamp in descending order (newest first). This is
  /// useful for displaying notification history or debugging.
  /// 
  /// Returns a list of [ActiveNotification] objects representing
  /// recently displayed notifications.
  /// 
  /// Example:
  /// ```dart
  /// // Get recent notifications for history view
  /// final recent = NotificationManager().getRecentNotifications();
  /// for (final notification in recent) {
  ///   print('${notification.title}: ${notification.body}');
  /// }
  /// ```
  List<ActiveNotification> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _activeNotifications.values
        .where((n) => n.timestamp.isAfter(yesterday))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Cleans up all resources and cancels all timers.
  /// 
  /// This method should be called when the NotificationManager is no longer
  /// needed (e.g., on app shutdown or when switching accounts). It performs
  /// comprehensive cleanup:
  /// 
  /// 1. Cancels all batch timers
  /// 2. Cancels the Do Not Disturb monitoring timer
  /// 3. Clears all internal queues and tracking data
  /// 4. Disposes of the underlying notification service
  /// 
  /// Example:
  /// ```dart
  /// // Clean up on app shutdown
  /// NotificationManager().dispose();
  /// ```
  void dispose() {
    // Cancel all batch timers to prevent memory leaks
    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    
    // Cancel Do Not Disturb monitoring
    _dndTimer?.cancel();
    
    // Clear all internal data structures
    _batchTimers.clear();
    _messageQueue.clear();
    _activeNotifications.clear();
    
    // Dispose of the underlying notification service
    _notificationService.dispose();
  }
}

/// Represents a notification that is waiting to be processed or batched.
/// 
/// This model stores all the necessary information for a notification
/// that hasn't been displayed yet, typically while waiting in the
/// batching queue for intelligent grouping with other notifications.
/// 
/// Contains metadata about the notification including sender information,
/// message content, timing, and routing data needed for proper display
/// and user interaction handling.
class PendingNotification {
  /// Unique identifier for this notification
  final int id;
  
  /// The type/category of this notification
  final NotificationType type;
  
  /// Display title for the notification
  final String title;
  
  /// Main content/body text of the notification
  final String body;
  
  /// When this notification was created
  final DateTime timestamp;
  
  /// Additional data for routing and interaction handling
  final Map<String, dynamic> payload;
  
  /// Display name of the message sender
  final String senderName;
  
  /// Unique identifier of the chat room this notification belongs to
  final String chatRoomId;

  /// Creates a new pending notification with the specified properties.
  /// 
  /// All parameters are required to ensure complete notification data
  /// is available when the notification is eventually processed and displayed.
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

/// Represents a notification that has been displayed to the user.
/// 
/// This model tracks notifications that are currently active in the system,
/// allowing for proper management, cleanup, and interaction handling.
/// It maintains the essential information needed for notification lifecycle
/// management and user interaction routing.
/// 
/// Active notifications are tracked for:
/// - Cleanup when chat rooms are opened
/// - Badge count management
/// - Notification history
/// - System resource management
class ActiveNotification {
  /// Unique identifier for this notification
  final int id;
  
  /// The type/category of this notification
  final NotificationType type;
  
  /// Display title that was shown to the user
  final String title;
  
  /// Main content/body text that was displayed
  final String body;
  
  /// When this notification was displayed
  final DateTime timestamp;
  
  /// Unique identifier of the chat room this notification belongs to
  final String chatRoomId;
  
  /// Number of messages represented by this notification (for batched notifications)
  final int messageCount;

  /// Creates a new active notification with the specified properties.
  /// 
  /// The [messageCount] parameter defaults to 1 for individual notifications
  /// but can be higher for batched notification summaries.
  ActiveNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.chatRoomId,
    this.messageCount = 1,
  });

  /// Provides a string representation of the notification for debugging.
  /// 
  /// Includes key identifying information such as ID, type, title,
  /// and associated chat room for easy debugging and logging.
  @override
  String toString() {
    return 'ActiveNotification(id: $id, type: $type, title: $title, chatRoom: $chatRoomId)';
  }
}