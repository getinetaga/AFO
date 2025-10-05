// ============================================================================
// AFO Chat Application - Notification Settings Model
// ============================================================================
// This file defines the comprehensive notification settings model for the AFO
// (Afaan Oromoo Chat Services) application. It handles all notification
// preferences, privacy settings, and user customization options.
//
// Features:
// - Message notification preferences (sound, vibration, ringtones)
// - Call notification settings with custom ringtones
// - Group notification controls with mention-only options
// - Media notification settings for file sharing
// - Status notification preferences (delivery/read receipts, typing)
// - System notification settings (security, backup alerts)
// - Do Not Disturb scheduling with time ranges
// - Privacy controls (hide content, sender info)
// - Badge count management and display options
// - Persistent storage using SharedPreferences
// ============================================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Comprehensive notification settings model for AFO chat application
/// 
/// This class manages all user notification preferences including:
/// - Individual notification types (messages, calls, groups, media)
/// - Sound and vibration settings for each notification type
/// - Privacy and display preferences
/// - Do Not Disturb scheduling
/// - Badge count management
class NotificationSettings {
  // ========================================================================
  // MESSAGE NOTIFICATION SETTINGS
  // ========================================================================
  
  /// Enable/disable message notifications globally
  bool messageNotifications;
  
  /// Enable sound for message notifications
  bool messageSound;
  
  /// Enable vibration for message notifications
  bool messageVibration;
  
  /// Custom ringtone identifier for message notifications
  String messageRingtone;
  
  /// Show message preview in notifications
  bool messagePreview;
  
  // ========================================================================
  // CALL NOTIFICATION SETTINGS
  // ========================================================================
  
  /// Enable/disable call notifications
  bool callNotifications;
  
  /// Enable sound for incoming calls
  bool callSound;
  
  /// Enable vibration for incoming calls
  bool callVibration;
  
  /// Custom ringtone identifier for incoming calls
  String callRingtone;
  
  // ========================================================================
  // GROUP NOTIFICATION SETTINGS
  // ========================================================================
  
  /// Enable/disable group notifications
  bool groupNotifications;
  
  /// Enable sound for group notifications
  bool groupSound;
  
  /// Enable vibration for group notifications
  bool groupVibration;
  
  /// Custom ringtone identifier for group notifications
  String groupRingtone;
  
  /// Only notify when user is mentioned in group (@username)
  bool groupMentionOnly;
  
  // ========================================================================
  // MEDIA NOTIFICATION SETTINGS
  // ========================================================================
  
  /// Enable/disable media sharing notifications
  bool mediaNotifications;
  
  /// Enable sound for media notifications (usually disabled)
  bool mediaSound;
  
  /// Enable vibration for media notifications
  bool mediaVibration;
  
  // ========================================================================
  // STATUS NOTIFICATION SETTINGS
  // ========================================================================
  
  /// Show delivery receipt notifications
  bool deliveryReceipts;
  
  /// Show read receipt notifications
  bool readReceipts;
  
  /// Show typing indicator notifications
  bool typingIndicators;
  
  // ========================================================================
  // SYSTEM NOTIFICATION SETTINGS
  // ========================================================================
  
  /// Enable system-wide notifications
  bool systemNotifications;
  
  /// Enable security alert notifications (login attempts, etc.)
  bool securityAlerts;
  
  /// Enable backup reminder notifications
  bool backupReminders;
  
  // ========================================================================
  // GENERAL NOTIFICATION SETTINGS
  // ========================================================================
  
  /// Master switch for all notifications
  bool notificationsEnabled;
  
  /// Enable Do Not Disturb mode
  bool doNotDisturb;
  
  /// Start time for Do Not Disturb period
  TimeOfDay? doNotDisturbStart;
  
  /// End time for Do Not Disturb period
  TimeOfDay? doNotDisturbEnd;
  
  /// Show notifications on device lock screen
  bool showOnLockScreen;
  
  /// Display sender information in notifications
  bool showSenderInfo;
  
  /// Notification timeout duration in seconds
  int notificationTimeout;
  
  // ========================================================================
  // PRIVACY SETTINGS
  // ========================================================================
  
  /// Hide notification content for privacy
  /// Hide notification content for privacy
  bool hideNotificationContent;
  
  /// Hide message preview in notifications
  bool hidePreview;
  
  /// Hide sender name in notifications
  bool hideSenderName;
  
  // ========================================================================
  // BADGE SETTINGS
  // ========================================================================
  
  /// Show unread count badge on app icon
  bool showBadgeCount;
  
  /// Reset badge count when app is opened
  bool resetBadgeOnOpen;

  /// Constructor with default values optimized for user experience
  /// 
  /// All notification types are enabled by default with sensible settings.
  /// Privacy features are disabled by default for better user engagement.
  /// Do Not Disturb is disabled to ensure important messages are received.
  NotificationSettings({
    // ====================================================================
    // MESSAGE NOTIFICATION DEFAULTS
    // ====================================================================
    this.messageNotifications = true,     // Enable message notifications
    this.messageSound = true,             // Enable sound for engagement
    this.messageVibration = true,         // Enable vibration for attention
    this.messageRingtone = 'default_message', // Default system ringtone
    this.messagePreview = true,           // Show previews for quick reading
    
    // ====================================================================
    // CALL NOTIFICATION DEFAULTS  
    // ====================================================================
    this.callNotifications = true,        // Critical for communication
    this.callSound = true,                // Essential for incoming calls
    this.callVibration = true,            // Backup alert method
    this.callRingtone = 'default_call',   // Distinctive call ringtone
    
    // ====================================================================
    // GROUP NOTIFICATION DEFAULTS
    // ====================================================================
    this.groupNotifications = true,       // Enable group participation
    this.groupSound = true,               // Group activity awareness
    this.groupVibration = true,           // Physical notification
    this.groupRingtone = 'default_group', // Group-specific sound
    this.groupMentionOnly = false,        // Show all group messages initially
    
    // ====================================================================
    // MEDIA NOTIFICATION DEFAULTS
    // ====================================================================
    this.mediaNotifications = true,       // Important for file sharing
    this.mediaSound = false,              // Quiet for media to avoid spam
    this.mediaVibration = true,           // Subtle physical alert
    
    // ====================================================================
    // STATUS NOTIFICATION DEFAULTS
    // ====================================================================
    this.deliveryReceipts = false,        // Reduce notification noise
    this.readReceipts = false,            // Privacy-friendly default
    this.typingIndicators = false,        // Minimize interruptions
    
    // ====================================================================
    // SYSTEM NOTIFICATION DEFAULTS
    // ====================================================================
    this.systemNotifications = true,      // Important system messages
    this.securityAlerts = true,           // Critical for account safety
    this.backupReminders = true,          // Data protection awareness
    
    // ====================================================================
    // GENERAL NOTIFICATION DEFAULTS
    // ====================================================================
    this.notificationsEnabled = true,     // Master switch enabled
    this.doNotDisturb = false,            // Allow notifications by default
    this.doNotDisturbStart,               // No DND schedule initially
    this.doNotDisturbEnd,                 // No DND schedule initially
    this.showOnLockScreen = true,         // Convenient access
    this.showSenderInfo = true,           // Helpful identification
    this.notificationTimeout = 5,         // 5 second display duration
    
    // ====================================================================
    // PRIVACY DEFAULTS (Less restrictive for better UX)
    // ====================================================================
    this.hideNotificationContent = false, // Show content for convenience
    this.hidePreview = false,             // Show previews for efficiency
    this.hideSenderName = false,          // Show sender for context
    
    // ====================================================================
    // BADGE DEFAULTS
    // ====================================================================
    this.showBadgeCount = true,           // Visual unread indicator
    this.resetBadgeOnOpen = true,         // Clean state when app opens
  });

  /// Convert notification settings to JSON format for persistent storage
  /// 
  /// Returns a Map containing all notification preferences that can be
  /// stored in SharedPreferences or sent to a backend service.
  /// 
  /// Special handling for TimeOfDay objects which are converted to 
  /// "HH:MM" string format for storage compatibility.
  Map<String, dynamic> toJson() {
    return {
      // Message settings
      'messageNotifications': messageNotifications,
      'messageSound': messageSound,
      'messageVibration': messageVibration,
      'messageRingtone': messageRingtone,
      'messagePreview': messagePreview,
      
      // Call settings
      'callNotifications': callNotifications,
      'callSound': callSound,
      'callVibration': callVibration,
      'callRingtone': callRingtone,
      
      // Group settings
      'groupNotifications': groupNotifications,
      'groupSound': groupSound,
      'groupVibration': groupVibration,
      'groupRingtone': groupRingtone,
      'groupMentionOnly': groupMentionOnly,
      
      // Media settings
      'mediaNotifications': mediaNotifications,
      'mediaSound': mediaSound,
      'mediaVibration': mediaVibration,
      
      // Status settings
      'deliveryReceipts': deliveryReceipts,
      'readReceipts': readReceipts,
      'typingIndicators': typingIndicators,
      
      // System settings
      'systemNotifications': systemNotifications,
      'securityAlerts': securityAlerts,
      'backupReminders': backupReminders,
      
      // General settings
      'notificationsEnabled': notificationsEnabled,
      'doNotDisturb': doNotDisturb,
      
      // Convert TimeOfDay to string format for storage
      'doNotDisturbStart': doNotDisturbStart != null 
          ? '${doNotDisturbStart!.hour}:${doNotDisturbStart!.minute}'
          : null,
      'doNotDisturbEnd': doNotDisturbEnd != null
          ? '${doNotDisturbEnd!.hour}:${doNotDisturbEnd!.minute}'
          : null,
      'showOnLockScreen': showOnLockScreen,
      'showSenderInfo': showSenderInfo,
      'notificationTimeout': notificationTimeout,
      
      // Privacy settings
      'hideNotificationContent': hideNotificationContent,
      'hidePreview': hidePreview,
      'hideSenderName': hideSenderName,
      
      // Badge settings
      'showBadgeCount': showBadgeCount,
      'resetBadgeOnOpen': resetBadgeOnOpen,
    };
  }

  /// Create NotificationSettings instance from JSON data
  /// 
  /// Used when loading settings from persistent storage (SharedPreferences)
  /// or receiving settings from a backend service.
  /// 
  /// Includes safe fallbacks to default values if JSON data is missing
  /// or corrupted. TimeOfDay strings are parsed back to TimeOfDay objects.
  /// 
  /// Parameters:
  /// - [json]: Map containing notification settings data
  /// 
  /// Returns: NotificationSettings instance with loaded or default values
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    /// Helper function to safely parse TimeOfDay from "HH:MM" string format
    /// 
    /// Handles edge cases:
    /// - Null or empty strings return null
    /// - Invalid format returns null  
    /// - Invalid hour/minute values default to 0
    TimeOfDay? parseTimeOfDay(String? timeString) {
      if (timeString == null || timeString.isEmpty) return null;
      
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      
      // Validate time ranges
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    }

    return NotificationSettings(
      // ====================================================================
      // MESSAGE SETTINGS - Load with safe fallbacks
      // ====================================================================
      messageNotifications: json['messageNotifications'] ?? true,
      messageSound: json['messageSound'] ?? true,
      messageVibration: json['messageVibration'] ?? true,
      messageRingtone: json['messageRingtone'] ?? 'default_message',
      messagePreview: json['messagePreview'] ?? true,
      
      // ====================================================================
      // CALL SETTINGS - Critical settings with safe defaults
      // ====================================================================
      callNotifications: json['callNotifications'] ?? true,
      callSound: json['callSound'] ?? true,
      callVibration: json['callVibration'] ?? true,
      callRingtone: json['callRingtone'] ?? 'default_call',
      
      // ====================================================================
      // GROUP SETTINGS - Community engagement preferences
      // ====================================================================
      groupNotifications: json['groupNotifications'] ?? true,
      groupSound: json['groupSound'] ?? true,
      groupVibration: json['groupVibration'] ?? true,
      groupRingtone: json['groupRingtone'] ?? 'default_group',
      groupMentionOnly: json['groupMentionOnly'] ?? false,
      
      mediaNotifications: json['mediaNotifications'] ?? true,
      mediaSound: json['mediaSound'] ?? false,
      mediaVibration: json['mediaVibration'] ?? true,
      
      deliveryReceipts: json['deliveryReceipts'] ?? false,
      readReceipts: json['readReceipts'] ?? false,
      typingIndicators: json['typingIndicators'] ?? false,
      
      systemNotifications: json['systemNotifications'] ?? true,
      securityAlerts: json['securityAlerts'] ?? true,
      backupReminders: json['backupReminders'] ?? true,
      
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      doNotDisturb: json['doNotDisturb'] ?? false,
      doNotDisturbStart: parseTimeOfDay(json['doNotDisturbStart']),
      doNotDisturbEnd: parseTimeOfDay(json['doNotDisturbEnd']),
      showOnLockScreen: json['showOnLockScreen'] ?? true,
      showSenderInfo: json['showSenderInfo'] ?? true,
      notificationTimeout: json['notificationTimeout'] ?? 5,
      
      hideNotificationContent: json['hideNotificationContent'] ?? false,
      hidePreview: json['hidePreview'] ?? false,
      hideSenderName: json['hideSenderName'] ?? false,
      
      showBadgeCount: json['showBadgeCount'] ?? true,
      resetBadgeOnOpen: json['resetBadgeOnOpen'] ?? true,
    );
  }

  // Copy with method for updating settings
  NotificationSettings copyWith({
    bool? messageNotifications,
    bool? messageSound,
    bool? messageVibration,
    String? messageRingtone,
    bool? messagePreview,
    
    bool? callNotifications,
    bool? callSound,
    bool? callVibration,
    String? callRingtone,
    
    bool? groupNotifications,
    bool? groupSound,
    bool? groupVibration,
    String? groupRingtone,
    bool? groupMentionOnly,
    
    bool? mediaNotifications,
    bool? mediaSound,
    bool? mediaVibration,
    
    bool? deliveryReceipts,
    bool? readReceipts,
    bool? typingIndicators,
    
    bool? systemNotifications,
    bool? securityAlerts,
    bool? backupReminders,
    
    bool? notificationsEnabled,
    bool? doNotDisturb,
    TimeOfDay? doNotDisturbStart,
    TimeOfDay? doNotDisturbEnd,
    bool? showOnLockScreen,
    bool? showSenderInfo,
    int? notificationTimeout,
    
    bool? hideNotificationContent,
    bool? hidePreview,
    bool? hideSenderName,
    
    bool? showBadgeCount,
    bool? resetBadgeOnOpen,
  }) {
    return NotificationSettings(
      messageNotifications: messageNotifications ?? this.messageNotifications,
      messageSound: messageSound ?? this.messageSound,
      messageVibration: messageVibration ?? this.messageVibration,
      messageRingtone: messageRingtone ?? this.messageRingtone,
      messagePreview: messagePreview ?? this.messagePreview,
      
      callNotifications: callNotifications ?? this.callNotifications,
      callSound: callSound ?? this.callSound,
      callVibration: callVibration ?? this.callVibration,
      callRingtone: callRingtone ?? this.callRingtone,
      
      groupNotifications: groupNotifications ?? this.groupNotifications,
      groupSound: groupSound ?? this.groupSound,
      groupVibration: groupVibration ?? this.groupVibration,
      groupRingtone: groupRingtone ?? this.groupRingtone,
      groupMentionOnly: groupMentionOnly ?? this.groupMentionOnly,
      
      mediaNotifications: mediaNotifications ?? this.mediaNotifications,
      mediaSound: mediaSound ?? this.mediaSound,
      mediaVibration: mediaVibration ?? this.mediaVibration,
      
      deliveryReceipts: deliveryReceipts ?? this.deliveryReceipts,
      readReceipts: readReceipts ?? this.readReceipts,
      typingIndicators: typingIndicators ?? this.typingIndicators,
      
      systemNotifications: systemNotifications ?? this.systemNotifications,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      backupReminders: backupReminders ?? this.backupReminders,
      
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
      showOnLockScreen: showOnLockScreen ?? this.showOnLockScreen,
      showSenderInfo: showSenderInfo ?? this.showSenderInfo,
      notificationTimeout: notificationTimeout ?? this.notificationTimeout,
      
      hideNotificationContent: hideNotificationContent ?? this.hideNotificationContent,
      hidePreview: hidePreview ?? this.hidePreview,
      hideSenderName: hideSenderName ?? this.hideSenderName,
      
      showBadgeCount: showBadgeCount ?? this.showBadgeCount,
      resetBadgeOnOpen: resetBadgeOnOpen ?? this.resetBadgeOnOpen,
    );
  }

  // Check if currently in Do Not Disturb period
  bool get isInDoNotDisturbPeriod {
    if (!doNotDisturb || doNotDisturbStart == null || doNotDisturbEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = doNotDisturbStart!;
    final end = doNotDisturbEnd!;

    // Handle same day period
    if (start.hour < end.hour || (start.hour == end.hour && start.minute <= end.minute)) {
      return _isTimeInRange(now, start, end);
    }
    // Handle overnight period (e.g., 22:00 to 08:00)
    else {
      return _isTimeInRange(now, start, const TimeOfDay(hour: 23, minute: 59)) ||
             _isTimeInRange(now, const TimeOfDay(hour: 0, minute: 0), end);
    }
  }

  bool _isTimeInRange(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeInMinutes = time.hour * 60 + time.minute;
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;
    
    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  }

  @override
  String toString() {
    return 'NotificationSettings(enabled: $notificationsEnabled, messages: $messageNotifications, calls: $callNotifications, groups: $groupNotifications)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettings &&
           other.messageNotifications == messageNotifications &&
           other.callNotifications == callNotifications &&
           other.groupNotifications == groupNotifications &&
           other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      messageNotifications,
      callNotifications,
      groupNotifications,
      notificationsEnabled,
    );
  }
}

// Notification settings manager
class NotificationSettingsManager {
  static const String _settingsKey = 'notification_settings';
  static NotificationSettings? _cachedSettings;

  // Load settings from storage
  static Future<NotificationSettings> loadSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> json = {};
        for (final pair in settingsJson.split('&')) {
          final parts = pair.split('=');
          if (parts.length == 2) {
            final key = Uri.decodeComponent(parts[0]);
            final value = Uri.decodeComponent(parts[1]);
            
            // Parse different value types
            if (value == 'true') {
              json[key] = true;
            } else if (value == 'false') {
              json[key] = false;
            } else if (int.tryParse(value) != null) {
              json[key] = int.parse(value);
            } else {
              json[key] = value;
            }
          }
        }
        
        _cachedSettings = NotificationSettings.fromJson(json);
        return _cachedSettings!;
      } catch (e) {
        print('Error loading notification settings: $e');
      }
    }

    _cachedSettings = NotificationSettings();
    return _cachedSettings!;
  }

  // Save settings to storage
  static Future<bool> saveSettings(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = settings.toJson();
      
      // Convert to URL-encoded string for storage
      final encodedSettings = json.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      
      final success = await prefs.setString(_settingsKey, encodedSettings);
      if (success) {
        _cachedSettings = settings;
      }
      return success;
    } catch (e) {
      print('Error saving notification settings: $e');
      return false;
    }
  }

  // Update specific setting
  static Future<bool> updateSetting<T>(String key, T value) async {
    final currentSettings = await loadSettings();
    
    // Create a map from current settings
    final json = currentSettings.toJson();
    json[key] = value;
    
    // Create new settings object
    final newSettings = NotificationSettings.fromJson(json);
    
    return await saveSettings(newSettings);
  }

  // Reset to defaults
  static Future<bool> resetToDefaults() async {
    final defaultSettings = NotificationSettings();
    final success = await saveSettings(defaultSettings);
    if (success) {
      _cachedSettings = null; // Force reload
    }
    return success;
  }

  // Clear cache
  static void clearCache() {
    _cachedSettings = null;
  }

  // Get current cached settings (may be null)
  static NotificationSettings? get cachedSettings => _cachedSettings;
}

// Import for TimeOfDay
