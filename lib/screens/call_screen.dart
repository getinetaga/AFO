/// AFO Chat Application - Call Screen
/// AFO: Afaan Oromoo Chat Services
/// 
/// This screen provides comprehensive voice and video calling functionality for users
/// in the Afaan Oromoo community. Features include:
/// 
/// - Professional calling interface with user information display
/// - Voice and video call support with dynamic UI based on call type
/// - Top navigation with back button and camera switch controls
/// - Call controls: mute, speaker, end call, camera toggle
/// - Real-time call duration tracking and display
/// - Interactive control buttons with visual feedback
/// - Mock implementation using CallService (replaces Agora RTC Engine)
/// - Professional dark theme optimized for calling interface
/// - Comprehensive error handling and status management
/// 
/// The screen uses CallService for call management and maintains
/// state for call duration, control states, and call status.
/// Combines the best features from multiple implementation approaches.
library;

import 'package:flutter/material.dart';

import '../services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String remoteUserId;
  final String remoteUserName;
  final CallType callType;

  const CallScreen({
    super.key, 
    required this.remoteUserId,
    required this.remoteUserName,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  String _callStatusText = 'Connecting...';
  Duration _callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  void _initializeCall() async {
    // Listen to call status changes
    _callService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          switch (status) {
            case CallStatus.connecting:
              _callStatusText = 'Connecting...';
              break;
            case CallStatus.connected:
              _callStatusText = 'Connected';
              break;
            case CallStatus.disconnecting:
              _callStatusText = 'Ending call...';
              break;
            case CallStatus.idle:
              Navigator.of(context).pop();
              break;
          }
        });
      }
    });

    // Listen to call duration
    _callService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _callDuration = duration;
        });
      }
    });

    // Start the call
    try {
      await _callService.startCall(
        remoteUserId: widget.remoteUserId,
        remoteUserName: widget.remoteUserName,
        type: widget.callType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVideo = widget.callType == CallType.video;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background for video call preview (placeholder)
          if (isVideo)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.black54, Colors.black87],
                ),
              ),
            ),
          
          // Call status
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User avatar placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade700,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam : Icons.call,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  widget.remoteUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  _callStatusText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                
                if (_callDuration.inSeconds > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Top navigation controls
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (isVideo)
                  IconButton(
                    onPressed: () async {
                      await _callService.toggleCamera();
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),

          // Control buttons at bottom
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute button
                if (isVideo)
                  _buildControlButton(
                    icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
                    backgroundColor: _callService.isMuted ? Colors.red : Colors.white24,
                    onTap: () async {
                      await _callService.toggleMute();
                      setState(() {});
                    },
                  ),

                // End call button (always red)
                _buildControlButton(
                  icon: Icons.call_end,
                  backgroundColor: Colors.red,
                  size: 64,
                  iconSize: 32,
                  onTap: () async {
                    await _callService.endCall();
                    // Navigator.pop will be called automatically via status stream
                  },
                ),

                // Video/Speaker toggle button
                if (isVideo)
                  _buildControlButton(
                    icon: _callService.isCameraOn ? Icons.videocam : Icons.videocam_off,
                    backgroundColor: _callService.isCameraOn ? Colors.white24 : Colors.red,
                    onTap: () async {
                      await _callService.toggleCamera();
                      setState(() {});
                    },
                  )
                else
                  _buildControlButton(
                    icon: _callService.isSpeakerOn ? Icons.volume_up : Icons.hearing,
                    backgroundColor: _callService.isSpeakerOn ? Colors.blue : Colors.white24,
                    onTap: () async {
                      await _callService.toggleSpeaker();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    // Make sure to end call if screen is disposed
    if (_callService.status != CallStatus.idle) {
      _callService.endCall();
    }
    super.dispose();
  }
}
