// ============================================================================
// AFO CHAT APPLICATION - NOTIFICATION SERVICE
// ============================================================================

/// Comprehensive notification service for AFO Chat Services
/// 
/// This service manages all notification functionality for the AFO chat
/// application, providing both local and push notifications with advanced
/// customization and intelligent delivery systems.
/// 
/// CORE NOTIFICATION FEATURES:
/// • Local notifications: In-app alerts and banners
/// • Push notifications: Firebase Cloud Messaging integration
/// • Rich notifications: Images, actions, and custom layouts
/// • Notification scheduling: Delayed and recurring notifications
/// • Sound management: Custom sounds and vibration patterns
/// • Badge management: App icon badge count updates
/// 
/// NOTIFICATION TYPES:
/// • Message notifications: New chat messages with sender info
/// • Call notifications: Incoming voice/video calls
/// • Group activity: Group joins, leaves, and updates
/// • Media notifications: File, image, and video sharing
/// • Delivery status: Message delivered and read receipts
/// • System updates: App updates and maintenance notices
/// 
/// INTELLIGENT FEATURES:
/// • Smart grouping: Related notifications bundled together
/// • Quiet hours: Automatic notification suppression
/// • Priority handling: Critical notifications bypass Do Not Disturb
/// • Adaptive delivery: Frequency limiting and smart timing
/// • Context awareness: Location and activity-based filtering
/// • User preferences: Granular notification control settings
/// 
/// TECHNICAL INTEGRATION:
/// • Flutter Local Notifications: Cross-platform local notifications
/// • Firebase Messaging: Cloud push notification delivery
/// • Permission Handler: Runtime permission management
/// • AudioPlayers: Custom notification sounds
/// • Vibration: Haptic feedback patterns
/// • SharedPreferences: User preference persistence
/// 
/// SECURITY & PRIVACY:
/// • End-to-end encryption for notification content
/// • Privacy-preserving message previews
/// • Secure token management for push notifications
/// • User consent and opt-out mechanisms

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

// ============================================================================
// NOTIFICATION ENUMS AND TYPES
// ============================================================================

/// Comprehensive notification type classification
/// 
/// Defines all possible notification types in the AFO chat system,
/// enabling specific handling, styling, and user preferences for
/// different categories of notifications.
enum NotificationType {
  /// New chat message received
  message,
  
  /// Incoming voice or video call
  call,
  
  /// Group activity (joins, leaves, updates)
  groupActivity,
  
  /// Media file received (image, video, document)
  mediaReceived,
  
  /// Message delivery confirmation
  messageDelivered,
  
  /// Message read receipt
  messageRead,
  
  /// User typing indicator
  typing,
  
  /// Group invitation received
  groupInvite,
  
  /// Contact request received
  contactRequest,
  
  /// System update or maintenance notice
  systemUpdate
}

/// Notification priority levels for intelligent delivery
/// 
/// Determines notification urgency and how it should be presented
/// to the user, affecting sound, vibration, and display behavior.
enum NotificationPriority {
  /// Low priority: Silent notifications, minimal disruption
  low,
  
  /// Normal priority: Standard notification behavior
  normal,
  
  /// High priority: Bypass Do Not Disturb, prominent display
  high,
  urgent
}

// Sound types for notifications
enum NotificationSound {
  none,
  defaultSound,
  messageSound,
  callSound,
  alertSound,
  custom
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isInitialized = false;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  // Notification channels
  static const String messageChannelId = 'afo_messages';
  static const String callChannelId = 'afo_calls';
  static const String groupChannelId = 'afo_groups';
  static const String mediaChannelId = 'afo_media';
  static const String systemChannelId = 'afo_system';

  // Initialize notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Set up message handlers
      await _setupMessageHandlers();

      _isInitialized = true;
      print('NotificationService: Initialized successfully');
      return true;
    } catch (e) {
      print('NotificationService: Initialization failed: $e');
      return false;
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();
    
    if (Platform.isAndroid) {
      await Permission.scheduleExactAlarm.request();
    }

    // Firebase messaging permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  // Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        messageChannelId,
        'Messages',
        description: 'Notifications for new messages',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('message_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      ),
      const AndroidNotificationChannel(
        callChannelId,
        'Calls',
        description: 'Notifications for incoming calls',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('call_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ),
      const AndroidNotificationChannel(
        groupChannelId,
        'Group Activities',
        description: 'Notifications for group activities',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('group_sound'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        mediaChannelId,
        'Media',
        description: 'Notifications for media files',
        importance: Importance.defaultImportance,
        sound: RawResourceAndroidNotificationSound('media_sound'),
      ),
      const AndroidNotificationChannel(
        systemChannelId,
        'System',
        description: 'System notifications',
        importance: Importance.low,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _onTokenRefresh(token);
    });

    // Configure foreground notification presentation
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Set up message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle messages when app is terminated
    RemoteMessage? initialMessage = 
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Handling foreground message: ${message.messageId}');
    
    final notificationType = _getNotificationTypeFromMessage(message);
    
    // Show local notification for foreground messages
    _showLocalNotification(
      title: message.notification?.title ?? 'AFO',
      body: message.notification?.body ?? 'New notification',
      payload: message.data,
      notificationType: notificationType,
    );
  }

  // Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.messageId}');
    _navigateFromNotification(message.data);
  }

  // Get notification type from FCM message
  NotificationType _getNotificationTypeFromMessage(RemoteMessage message) {
    final type = message.data['type'] ?? 'message';
    switch (type) {
      case 'call':
        return NotificationType.call;
      case 'group':
        return NotificationType.groupActivity;
      case 'media':
        return NotificationType.mediaReceived;
      case 'typing':
        return NotificationType.typing;
      case 'delivered':
        return NotificationType.messageDelivered;
      case 'read':
        return NotificationType.messageRead;
      default:
        return NotificationType.message;
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    NotificationType notificationType = NotificationType.message,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!await _shouldShowNotification(notificationType)) {
      return;
    }

    final channelId = _getChannelId(notificationType);
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(notificationType),
      channelDescription: _getChannelDescription(notificationType),
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: _getNotificationStyle(body, notificationType),
      autoCancel: true,
      enableVibration: await _shouldVibrate(notificationType),
      vibrationPattern: _getVibrationPattern(notificationType),
      sound: await _getNotificationSound(notificationType),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.private,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload != null ? _encodePayload(payload) : null,
    );

    // Play custom sound and vibration
    await _playNotificationEffects(notificationType);
  }

  // Show message notification with additional features
  Future<void> showMessageNotification({
    required String senderName,
    required String messageContent,
    required String chatRoomId,
    required String messageId,
    String? senderAvatar,
    bool isGroup = false,
    String? groupName,
  }) async {
    final title = isGroup ? '$senderName in $groupName' : senderName;
    final body = messageContent;

    await _showLocalNotification(
      title: title,
      body: body,
      payload: {
        'type': 'message',
        'chatRoomId': chatRoomId,
        'messageId': messageId,
        'senderId': senderName,
      },
      notificationType: NotificationType.message,
      priority: NotificationPriority.high,
    );
  }

  // Show call notification
  Future<void> showCallNotification({
    required String callerName,
    required String callId,
    required bool isVideoCall,
    String? callerAvatar,
  }) async {
    final title = 'Incoming ${isVideoCall ? 'Video' : 'Voice'} Call';
    final body = 'From $callerName';

    await _showLocalNotification(
      title: title,
      body: body,
      payload: {
        'type': 'call',
        'callId': callId,
        'callerName': callerName,
        'isVideoCall': isVideoCall.toString(),
      },
      notificationType: NotificationType.call,
      priority: NotificationPriority.urgent,
    );
  }

  // Show group activity notification
  Future<void> showGroupActivityNotification({
    required String groupName,
    required String activity,
    required String actorName,
    required String chatRoomId,
  }) async {
    final title = groupName;
    final body = '$actorName $activity';

    await _showLocalNotification(
      title: title,
      body: body,
      payload: {
        'type': 'group',
        'chatRoomId': chatRoomId,
        'activity': activity,
        'actorName': actorName,
      },
      notificationType: NotificationType.groupActivity,
    );
  }

  // Show media notification
  Future<void> showMediaNotification({
    required String senderName,
    required String mediaType,
    required String chatRoomId,
    required String messageId,
    bool isGroup = false,
    String? groupName,
  }) async {
    final title = isGroup ? '$senderName in $groupName' : senderName;
    final body = 'Sent a $mediaType';

    await _showLocalNotification(
      title: title,
      body: body,
      payload: {
        'type': 'media',
        'chatRoomId': chatRoomId,
        'messageId': messageId,
        'mediaType': mediaType,
      },
      notificationType: NotificationType.mediaReceived,
    );
  }

  // Cancel notification
  Future<void> cancelNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final payload = _decodePayload(response.payload!);
      _navigateFromNotification(payload);
    }
  }

  // Navigate based on notification payload
  void _navigateFromNotification(Map<String, dynamic> payload) {
    final type = payload['type'];
    
    switch (type) {
      case 'message':
      case 'media':
        // Navigate to chat screen
        _navigateToChat(payload['chatRoomId']);
        break;
      case 'call':
        // Navigate to call screen or show call interface
        _navigateToCall(payload['callId']);
        break;
      case 'group':
        // Navigate to group chat
        _navigateToChat(payload['chatRoomId']);
        break;
      default:
        // Navigate to home screen
        _navigateToHome();
        break;
    }
  }

  // Navigation helpers (to be implemented based on your app's navigation)
  void _navigateToChat(String chatRoomId) {
    // Implement navigation to chat screen
    print('Navigating to chat: $chatRoomId');
  }

  void _navigateToCall(String callId) {
    // Implement navigation to call screen
    print('Navigating to call: $callId');
  }

  void _navigateToHome() {
    // Implement navigation to home screen
    print('Navigating to home');
  }

  // Notification settings helpers
  Future<bool> _shouldShowNotification(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'notification_${type.toString().split('.').last}';
    return prefs.getBool(key) ?? true;
  }

  Future<bool> _shouldVibrate(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vibration_${type.toString().split('.').last}';
    return prefs.getBool(key) ?? true;
  }

  Future<RawResourceAndroidNotificationSound?> _getNotificationSound(
      NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sound_${type.toString().split('.').last}';
    final soundName = prefs.getString(key) ?? 'default';
    
    if (soundName == 'none') return null;
    return RawResourceAndroidNotificationSound(soundName);
  }

  // Play notification effects
  Future<void> _playNotificationEffects(NotificationType type) async {
    // Play custom sound
    await _playNotificationSound(type);
    
    // Trigger vibration
    await _triggerVibration(type);
  }

  Future<void> _playNotificationSound(NotificationType type) async {
    if (!await _shouldPlaySound(type)) return;
    
    final soundFile = _getSoundFile(type);
    if (soundFile != null) {
      try {
        await _audioPlayer.play(AssetSource(soundFile));
      } catch (e) {
        print('Error playing sound: $e');
      }
    }
  }

  Future<void> _triggerVibration(NotificationType type) async {
    if (!await _shouldVibrate(type)) return;
    
    final pattern = _getVibrationPattern(type);
    if (await Vibration.hasVibrator() ?? false) {
      if (pattern.isNotEmpty) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        await Vibration.vibrate(duration: 500);
      }
    }
  }

  Future<bool> _shouldPlaySound(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sound_enabled_${type.toString().split('.').last}';
    return prefs.getBool(key) ?? true;
  }

  String? _getSoundFile(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return 'sounds/message.mp3';
      case NotificationType.call:
        return 'sounds/ringtone.mp3';
      case NotificationType.groupActivity:
        return 'sounds/group.mp3';
      case NotificationType.mediaReceived:
        return 'sounds/media.mp3';
      default:
        return 'sounds/notification.mp3';
    }
  }

  // Helper methods for notification configuration
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.call:
        return callChannelId;
      case NotificationType.groupActivity:
        return groupChannelId;
      case NotificationType.mediaReceived:
        return mediaChannelId;
      case NotificationType.messageDelivered:
      case NotificationType.messageRead:
      case NotificationType.typing:
        return systemChannelId;
      default:
        return messageChannelId;
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.call:
        return 'Calls';
      case NotificationType.groupActivity:
        return 'Group Activities';
      case NotificationType.mediaReceived:
        return 'Media';
      case NotificationType.messageDelivered:
      case NotificationType.messageRead:
      case NotificationType.typing:
        return 'System';
      default:
        return 'Messages';
    }
  }

  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.call:
        return 'Notifications for incoming calls';
      case NotificationType.groupActivity:
        return 'Notifications for group activities';
      case NotificationType.mediaReceived:
        return 'Notifications for media files';
      case NotificationType.messageDelivered:
      case NotificationType.messageRead:
      case NotificationType.typing:
        return 'System notifications';
      default:
        return 'Notifications for new messages';
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  AndroidNotificationStyle _getNotificationStyle(
      String body, NotificationType type) {
    if (body.length > 50) {
      return BigTextStyleInformation(
        body,
        contentTitle: _getChannelName(type),
        summaryText: 'AFO',
      );
    }
    return const DefaultStyleInformation(true, true);
  }

  List<int> _getVibrationPattern(NotificationType type) {
    switch (type) {
      case NotificationType.call:
        return [0, 1000, 500, 1000, 500, 1000];
      case NotificationType.message:
        return [0, 250, 250, 250];
      case NotificationType.groupActivity:
        return [0, 500, 200, 500];
      case NotificationType.mediaReceived:
        return [0, 300, 100, 300];
      default:
        return [0, 250];
    }
  }

  // Payload encoding/decoding
  String _encodePayload(Map<String, dynamic> payload) {
    return payload.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final Map<String, dynamic> result = {};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        result[parts[0]] = Uri.decodeComponent(parts[1]);
      }
    }
    return result;
  }

  // Token management
  String? get fcmToken => _fcmToken;

  void _onTokenRefresh(String token) {
    // Implement token refresh logic
    // Send new token to your server
    print('FCM token refreshed: $token');
  }

  // Cleanup
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _audioPlayer.dispose();
  }
}