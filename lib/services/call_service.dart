// ============================================================================
// AFO Chat Application - Call Service
// ============================================================================
// This service provides voice and video calling functionality for the
// AFO (Afaan Oromoo Chat Services) application as a mock replacement for 
// Agora RTC Engine. It simulates real call behavior including:
// - Call initiation and management
// - Audio/video controls (mute, camera, speaker)
// - Call status tracking and streams
// - Permission handling
// - Call duration tracking
//
// NOTE: This is a MOCK implementation that simulates real calling functionality
// without requiring Agora SDK or external dependencies. For production,
// integrate with actual WebRTC or Agora RTC implementation.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

// ========================================================================
// Enums - Call State Definitions
// ========================================================================

/// Call connection status states
enum CallStatus {
  idle,           // No active call
  connecting,     // Attempting to connect
  connected,      // Call is active
  disconnecting,  // Call ending process
}

/// Types of calls supported
enum CallType {
  voice,  // Audio-only call
  video,  // Video call with audio
}

// ========================================================================
// Data Models
// ========================================================================

/// Call information model containing call details
class CallInfo {
  final String callId;          // Unique call identifier
  final String remoteUserId;    // ID of the other participant
  final String remoteUserName;  // Display name of other participant
  final CallType type;          // Voice or video call
  final DateTime startTime;     // When the call started

  CallInfo({
    required this.callId,
    required this.remoteUserId,
    required this.remoteUserName,
    required this.type,
    required this.startTime,
  });
}

// ========================================================================
// Call Service - Main Service Class
// ========================================================================

/// Mock Call Service - Simulates Agora RTC Engine functionality
/// Implements Singleton pattern to ensure single instance across app
class CallService {
  // Singleton implementation
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // ========================================================================
  // State Management
  // ========================================================================

  /// Current call connection status
  CallStatus _status = CallStatus.idle;
  
  /// Current active call information
  CallInfo? _currentCall;
  
  /// Timer for tracking call duration
  Timer? _callTimer;
  
  /// Total duration of current call
  Duration _callDuration = Duration.zero;

  // ========================================================================
  // Stream Controllers - Real-time Updates
  // ========================================================================

  /// Broadcasts call status changes to listeners
  final StreamController<CallStatus> _statusController = StreamController<CallStatus>.broadcast();
  
  /// Broadcasts call info updates to listeners  
  final StreamController<CallInfo?> _callInfoController = StreamController<CallInfo?>.broadcast();
  
  /// Broadcasts call duration updates to listeners
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();

  // ========================================================================
  // Public Getters - Current State Access
  // ========================================================================
  
  CallStatus get status => _status;
  CallInfo? get currentCall => _currentCall;
  Duration get callDuration => _callDuration;

  // Streams
  Stream<CallStatus> get statusStream => _statusController.stream;
  Stream<CallInfo?> get callInfoStream => _callInfoController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  /// Mock permission check (always returns true for demo)
  Future<bool> requestPermissions({required bool isVideo}) async {
    debugPrint('📱 ${isVideo ? 'Camera and microphone' : 'Microphone'} permissions granted (mock)');
    // No delay in tests - permissions are granted immediately in mock
    return true;
  }

  /// Start a voice or video call
  Future<void> startCall({
    required String remoteUserId,
    required String remoteUserName,
    required CallType type,
  }) async {
    if (_status != CallStatus.idle) {
      throw Exception('Call already in progress');
    }

    debugPrint('📞 Starting ${type.name} call to $remoteUserName...');
    
    // Check permissions
    final hasPermission = await requestPermissions(isVideo: type == CallType.video);
    if (!hasPermission) {
      throw Exception('Permissions not granted');
    }

    // Update status to connecting
    _status = CallStatus.connecting;
  if (!_statusController.isClosed) _statusController.add(_status);

    // Create call info
    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    _currentCall = CallInfo(
      callId: callId,
      remoteUserId: remoteUserId,
      remoteUserName: remoteUserName,
      type: type,
      startTime: DateTime.now(),
    );
    _callInfoController.add(_currentCall);

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    // Update status to connected
  _status = CallStatus.connected;
  if (!_statusController.isClosed) _statusController.add(_status);
    
    // Start call duration timer
    _startCallTimer();
    
    debugPrint('✅ Call connected successfully');
  }

  /// End the current call
  Future<void> endCall() async {
    if (_status == CallStatus.idle) return;

    debugPrint('📴 Ending call...');
    
  _status = CallStatus.disconnecting;
  if (!_statusController.isClosed) _statusController.add(_status);

    // Stop call timer
    _stopCallTimer();

  // End call immediately (no artificial delay to keep tests deterministic)
  // Reset state
  _status = CallStatus.idle;
  _currentCall = null;
  _callDuration = Duration.zero;

  // Notify listeners if still open
  if (!_statusController.isClosed) _statusController.add(_status);
  if (!_callInfoController.isClosed) _callInfoController.add(_currentCall);
  if (!_durationController.isClosed) _durationController.add(_callDuration);

    debugPrint('✅ Call ended');
  }

  /// Start the call duration timer
  void _startCallTimer() {
    _callDuration = Duration.zero;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
      _durationController.add(_callDuration);
    });
  }

  /// Stop the call duration timer
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  /// Toggle mute (mock functionality)
  bool _isMuted = false;
  bool get isMuted => _isMuted;
  
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    debugPrint('🔇 ${_isMuted ? 'Muted' : 'Unmuted'} microphone');
  }

  /// Toggle speaker (mock functionality)  
  bool _isSpeakerOn = false;
  bool get isSpeakerOn => _isSpeakerOn;
  
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    debugPrint('🔊 Speaker ${_isSpeakerOn ? 'on' : 'off'}');
  }

  /// Toggle camera for video calls (mock functionality)
  bool _isCameraOn = true;
  bool get isCameraOn => _isCameraOn;
  
  Future<void> toggleCamera() async {
    if (_currentCall?.type != CallType.video) return;
    
    _isCameraOn = !_isCameraOn;
    debugPrint('📹 Camera ${_isCameraOn ? 'on' : 'off'}');
  }

  /// Switch camera front/back (mock functionality)
  bool _isFrontCamera = true;
  bool get isFrontCamera => _isFrontCamera;
  
  Future<void> switchCamera() async {
    if (_currentCall?.type != CallType.video) return;
    
    _isFrontCamera = !_isFrontCamera;
    debugPrint('📷 Switched to ${_isFrontCamera ? 'front' : 'back'} camera');
  }

  /// Dispose resources
  void dispose() {
    _stopCallTimer();
    _statusController.close();
    _callInfoController.close();
    _durationController.close();
  }
}
