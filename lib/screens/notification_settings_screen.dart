// ignore_for_file: use_build_context_synchronously, dangling_library_doc_comments
/// AFO Chat Application - Notification Settings
import 'package:flutter/material.dart';

import '../models/notification_settings.dart';
import '../services/notification_manager.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await NotificationSettingsManager.loadSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = NotificationSettings();
        _isLoading = false;
      });
      _showError('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await NotificationSettingsManager.saveSettings(_settings!);
      if (success) {
        // Refresh notification manager settings
        await NotificationManager().refreshSettings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to save settings');
      }
    } catch (e) {
      _showError('Failed to save settings: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _updateSettings(NotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  Future<void> _selectTime(bool isStartTime) async {
    final currentTime = isStartTime 
        ? _settings?.doNotDisturbStart ?? const TimeOfDay(hour: 22, minute: 0)
        : _settings?.doNotDisturbEnd ?? const TimeOfDay(hour: 8, minute: 0);
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (picked != null && _settings != null) {
      _updateSettings(
        _settings!.copyWith(
          doNotDisturbStart: isStartTime ? picked : _settings!.doNotDisturbStart,
          doNotDisturbEnd: isStartTime ? _settings!.doNotDisturbEnd : picked,
        ),
      );
    }
  }

  void _testNotification() async {
    try {
      await NotificationManager().showTestNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent')),
      );
    } catch (e) {
      _showError('Failed to send test notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Failed to load settings'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Test notification button
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.notifications_active, color: Colors.orange),
                          title: const Text('Test Notification'),
                          subtitle: const Text('Send a test notification to verify settings'),
                          trailing: ElevatedButton(
                            onPressed: _testNotification,
                            child: const Text('Test'),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // General Settings
                      _buildSectionHeader('General Settings'),
                      _buildCard([
                        _buildSwitchTile(
                          'Enable Notifications',
                          'Turn all notifications on or off',
                          Icons.notifications,
                          _settings!.notificationsEnabled,
                          (value) => _updateSettings(_settings!.copyWith(notificationsEnabled: value)),
                        ),
                        _buildSwitchTile(
                          'Show on Lock Screen',
                          'Display notifications on the lock screen',
                          Icons.lock_outline,
                          _settings!.showOnLockScreen,
                          (value) => _updateSettings(_settings!.copyWith(showOnLockScreen: value)),
                        ),
                        _buildSwitchTile(
                          'Show Sender Info',
                          'Display sender name and avatar in notifications',
                          Icons.person_outline,
                          _settings!.showSenderInfo,
                          (value) => _updateSettings(_settings!.copyWith(showSenderInfo: value)),
                        ),
                        _buildSwitchTile(
                          'Show Badge Count',
                          'Display unread count on app icon',
                          Icons.circle_notifications,
                          _settings!.showBadgeCount,
                          (value) => _updateSettings(_settings!.copyWith(showBadgeCount: value)),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Message Notifications
                      _buildSectionHeader('Message Notifications'),
                      _buildCard([
                        _buildSwitchTile(
                          'Message Notifications',
                          'Receive notifications for new messages',
                          Icons.message,
                          _settings!.messageNotifications,
                          (value) => _updateSettings(_settings!.copyWith(messageNotifications: value)),
                        ),
                        _buildSwitchTile(
                          'Message Sound',
                          'Play sound for message notifications',
                          Icons.volume_up,
                          _settings!.messageSound,
                          (value) => _updateSettings(_settings!.copyWith(messageSound: value)),
                          enabled: _settings!.messageNotifications,
                        ),
                        _buildSwitchTile(
                          'Message Vibration',
                          'Vibrate for message notifications',
                          Icons.vibration,
                          _settings!.messageVibration,
                          (value) => _updateSettings(_settings!.copyWith(messageVibration: value)),
                          enabled: _settings!.messageNotifications,
                        ),
                        _buildSwitchTile(
                          'Message Preview',
                          'Show message content in notifications',
                          Icons.preview,
                          _settings!.messagePreview,
                          (value) => _updateSettings(_settings!.copyWith(messagePreview: value)),
                          enabled: _settings!.messageNotifications,
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Call Notifications
                      _buildSectionHeader('Call Notifications'),
                      _buildCard([
                        _buildSwitchTile(
                          'Call Notifications',
                          'Receive notifications for incoming calls',
                          Icons.phone,
                          _settings!.callNotifications,
                          (value) => _updateSettings(_settings!.copyWith(callNotifications: value)),
                        ),
                        _buildSwitchTile(
                          'Call Sound',
                          'Play ringtone for call notifications',
                          Icons.ring_volume,
                          _settings!.callSound,
                          (value) => _updateSettings(_settings!.copyWith(callSound: value)),
                          enabled: _settings!.callNotifications,
                        ),
                        _buildSwitchTile(
                          'Call Vibration',
                          'Vibrate for call notifications',
                          Icons.vibration,
                          _settings!.callVibration,
                          (value) => _updateSettings(_settings!.copyWith(callVibration: value)),
                          enabled: _settings!.callNotifications,
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Group Notifications
                      _buildSectionHeader('Group Notifications'),
                      _buildCard([
                        _buildSwitchTile(
                          'Group Notifications',
                          'Receive notifications for group messages',
                          Icons.group,
                          _settings!.groupNotifications,
                          (value) => _updateSettings(_settings!.copyWith(groupNotifications: value)),
                        ),
                        _buildSwitchTile(
                          'Mentions Only',
                          'Only notify when you are mentioned',
                          Icons.alternate_email,
                          _settings!.groupMentionOnly,
                          (value) => _updateSettings(_settings!.copyWith(groupMentionOnly: value)),
                          enabled: _settings!.groupNotifications,
                        ),
                        _buildSwitchTile(
                          'Group Sound',
                          'Play sound for group notifications',
                          Icons.volume_up,
                          _settings!.groupSound,
                          (value) => _updateSettings(_settings!.copyWith(groupSound: value)),
                          enabled: _settings!.groupNotifications,
                        ),
                        _buildSwitchTile(
                          'Group Vibration',
                          'Vibrate for group notifications',
                          Icons.vibration,
                          _settings!.groupVibration,
                          (value) => _updateSettings(_settings!.copyWith(groupVibration: value)),
                          enabled: _settings!.groupNotifications,
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Media Notifications
                      _buildSectionHeader('Media Notifications'),
                      _buildCard([
                        _buildSwitchTile(
                          'Media Notifications',
                          'Receive notifications for media messages',
                          Icons.photo_library,
                          _settings!.mediaNotifications,
                          (value) => _updateSettings(_settings!.copyWith(mediaNotifications: value)),
                        ),
                        _buildSwitchTile(
                          'Media Sound',
                          'Play sound for media notifications',
                          Icons.volume_up,
                          _settings!.mediaSound,
                          (value) => _updateSettings(_settings!.copyWith(mediaSound: value)),
                          enabled: _settings!.mediaNotifications,
                        ),
                        _buildSwitchTile(
                          'Media Vibration',
                          'Vibrate for media notifications',
                          Icons.vibration,
                          _settings!.mediaVibration,
                          (value) => _updateSettings(_settings!.copyWith(mediaVibration: value)),
                          enabled: _settings!.mediaNotifications,
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Status Notifications
                      _buildSectionHeader('Status Notifications'),
                      _buildCard([
                        _buildSwitchTile(
                          'Delivery Receipts',
                          'Notify when messages are delivered',
                          Icons.done,
                          _settings!.deliveryReceipts,
                          (value) => _updateSettings(_settings!.copyWith(deliveryReceipts: value)),
                        ),
                        _buildSwitchTile(
                          'Read Receipts',
                          'Notify when messages are read',
                          Icons.done_all,
                          _settings!.readReceipts,
                          (value) => _updateSettings(_settings!.copyWith(readReceipts: value)),
                        ),
                        _buildSwitchTile(
                          'Typing Indicators',
                          'Notify when someone is typing',
                          Icons.keyboard,
                          _settings!.typingIndicators,
                          (value) => _updateSettings(_settings!.copyWith(typingIndicators: value)),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Do Not Disturb
                      _buildSectionHeader('Do Not Disturb'),
                      _buildCard([
                        _buildSwitchTile(
                          'Do Not Disturb',
                          'Disable notifications during specified hours',
                          Icons.do_not_disturb,
                          _settings!.doNotDisturb,
                          (value) => _updateSettings(_settings!.copyWith(doNotDisturb: value)),
                        ),
                        if (_settings!.doNotDisturb) ...[
                          ListTile(
                            leading: const Icon(Icons.schedule),
                            title: const Text('Start Time'),
                            subtitle: Text(
                              _settings!.doNotDisturbStart != null
                                  ? _settings!.doNotDisturbStart!.format(context)
                                  : 'Not set',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _selectTime(true),
                          ),
                          ListTile(
                            leading: const Icon(Icons.schedule_send),
                            title: const Text('End Time'),
                            subtitle: Text(
                              _settings!.doNotDisturbEnd != null
                                  ? _settings!.doNotDisturbEnd!.format(context)
                                  : 'Not set',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _selectTime(false),
                          ),
                        ],
                      ]),

                      const SizedBox(height: 16),

                      // Privacy Settings
                      _buildSectionHeader('Privacy Settings'),
                      _buildCard([
                        _buildSwitchTile(
                          'Hide Notification Content',
                          'Hide message content in notifications',
                          Icons.visibility_off,
                          _settings!.hideNotificationContent,
                          (value) => _updateSettings(_settings!.copyWith(hideNotificationContent: value)),
                        ),
                        _buildSwitchTile(
                          'Hide Preview',
                          'Hide message preview in notifications',
                          Icons.visibility_off,
                          _settings!.hidePreview,
                          (value) => _updateSettings(_settings!.copyWith(hidePreview: value)),
                        ),
                        _buildSwitchTile(
                          'Hide Sender Name',
                          'Hide sender name in notifications',
                          Icons.person_off,
                          _settings!.hideSenderName,
                          (value) => _updateSettings(_settings!.copyWith(hideSenderName: value)),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // System Notifications
                      _buildSectionHeader('System Notifications'),
                      _buildCard([
                        _buildSwitchTile(
                          'System Notifications',
                          'Receive app and system notifications',
                          Icons.settings,
                          _settings!.systemNotifications,
                          (value) => _updateSettings(_settings!.copyWith(systemNotifications: value)),
                        ),
                        _buildSwitchTile(
                          'Security Alerts',
                          'Important security notifications',
                          Icons.security,
                          _settings!.securityAlerts,
                          (value) => _updateSettings(_settings!.copyWith(securityAlerts: value)),
                        ),
                        _buildSwitchTile(
                          'Backup Reminders',
                          'Notifications about data backup',
                          Icons.backup,
                          _settings!.backupReminders,
                          (value) => _updateSettings(_settings!.copyWith(backupReminders: value)),
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // Reset button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _resetToDefaults,
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset to Defaults'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Switch(
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
        activeColor: Colors.blue,
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all notification settings to their default values. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await NotificationSettingsManager.resetToDefaults();
        if (success) {
          await _loadSettings();
          await NotificationManager().refreshSettings();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings reset to defaults successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to reset settings');
        }
      } catch (e) {
        _showError('Failed to reset settings: $e');
      }
    }
  }
}