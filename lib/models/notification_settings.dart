import 'package:shared_preferences/shared_preferences.dart';

// Notification settings model
class NotificationSettings {
  // Message notifications
  bool messageNotifications;
  bool messageSound;
  bool messageVibration;
  String messageRingtone;
  bool messagePreview;
  
  // Call notifications
  bool callNotifications;
  bool callSound;
  bool callVibration;
  String callRingtone;
  
  // Group notifications
  bool groupNotifications;
  bool groupSound;
  bool groupVibration;
  String groupRingtone;
  bool groupMentionOnly;
  
  // Media notifications
  bool mediaNotifications;
  bool mediaSound;
  bool mediaVibration;
  
  // Status notifications
  bool deliveryReceipts;
  bool readReceipts;
  bool typingIndicators;
  
  // System notifications
  bool systemNotifications;
  bool securityAlerts;
  bool backupReminders;
  
  // General settings
  bool notificationsEnabled;
  bool doNotDisturb;
  TimeOfDay? doNotDisturbStart;
  TimeOfDay? doNotDisturbEnd;
  bool showOnLockScreen;
  bool showSenderInfo;
  int notificationTimeout; // in seconds
  
  // Privacy settings
  bool hideNotificationContent;
  bool hidePreview;
  bool hideSenderName;
  
  // Badge settings
  bool showBadgeCount;
  bool resetBadgeOnOpen;

  NotificationSettings({
    // Message defaults
    this.messageNotifications = true,
    this.messageSound = true,
    this.messageVibration = true,
    this.messageRingtone = 'default_message',
    this.messagePreview = true,
    
    // Call defaults
    this.callNotifications = true,
    this.callSound = true,
    this.callVibration = true,
    this.callRingtone = 'default_call',
    
    // Group defaults
    this.groupNotifications = true,
    this.groupSound = true,
    this.groupVibration = true,
    this.groupRingtone = 'default_group',
    this.groupMentionOnly = false,
    
    // Media defaults
    this.mediaNotifications = true,
    this.mediaSound = false,
    this.mediaVibration = true,
    
    // Status defaults
    this.deliveryReceipts = false,
    this.readReceipts = false,
    this.typingIndicators = false,
    
    // System defaults
    this.systemNotifications = true,
    this.securityAlerts = true,
    this.backupReminders = true,
    
    // General defaults
    this.notificationsEnabled = true,
    this.doNotDisturb = false,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
    this.showOnLockScreen = true,
    this.showSenderInfo = true,
    this.notificationTimeout = 5,
    
    // Privacy defaults
    this.hideNotificationContent = false,
    this.hidePreview = false,
    this.hideSenderName = false,
    
    // Badge defaults
    this.showBadgeCount = true,
    this.resetBadgeOnOpen = true,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'messageNotifications': messageNotifications,
      'messageSound': messageSound,
      'messageVibration': messageVibration,
      'messageRingtone': messageRingtone,
      'messagePreview': messagePreview,
      
      'callNotifications': callNotifications,
      'callSound': callSound,
      'callVibration': callVibration,
      'callRingtone': callRingtone,
      
      'groupNotifications': groupNotifications,
      'groupSound': groupSound,
      'groupVibration': groupVibration,
      'groupRingtone': groupRingtone,
      'groupMentionOnly': groupMentionOnly,
      
      'mediaNotifications': mediaNotifications,
      'mediaSound': mediaSound,
      'mediaVibration': mediaVibration,
      
      'deliveryReceipts': deliveryReceipts,
      'readReceipts': readReceipts,
      'typingIndicators': typingIndicators,
      
      'systemNotifications': systemNotifications,
      'securityAlerts': securityAlerts,
      'backupReminders': backupReminders,
      
      'notificationsEnabled': notificationsEnabled,
      'doNotDisturb': doNotDisturb,
      'doNotDisturbStart': doNotDisturbStart != null 
          ? '${doNotDisturbStart!.hour}:${doNotDisturbStart!.minute}'
          : null,
      'doNotDisturbEnd': doNotDisturbEnd != null
          ? '${doNotDisturbEnd!.hour}:${doNotDisturbEnd!.minute}'
          : null,
      'showOnLockScreen': showOnLockScreen,
      'showSenderInfo': showSenderInfo,
      'notificationTimeout': notificationTimeout,
      
      'hideNotificationContent': hideNotificationContent,
      'hidePreview': hidePreview,
      'hideSenderName': hideSenderName,
      
      'showBadgeCount': showBadgeCount,
      'resetBadgeOnOpen': resetBadgeOnOpen,
    };
  }

  // Create from JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTimeOfDay(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    return NotificationSettings(
      messageNotifications: json['messageNotifications'] ?? true,
      messageSound: json['messageSound'] ?? true,
      messageVibration: json['messageVibration'] ?? true,
      messageRingtone: json['messageRingtone'] ?? 'default_message',
      messagePreview: json['messagePreview'] ?? true,
      
      callNotifications: json['callNotifications'] ?? true,
      callSound: json['callSound'] ?? true,
      callVibration: json['callVibration'] ?? true,
      callRingtone: json['callRingtone'] ?? 'default_call',
      
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
import 'package:flutter/material.dart';