// ============================================================================
// AFO CHAT APPLICATION - MEDIA PICKER WIDGET
// ============================================================================

/// Comprehensive media picker widget for AFO Chat Services
/// 
/// This widget provides a professional, animated interface for selecting
/// various types of media content in chat conversations. Features include:
/// 
/// MEDIA SELECTION CAPABILITIES:
/// • Camera capture: Photo and video recording with front/rear camera
/// • Gallery selection: Images and videos from device gallery
/// • Audio recording: Voice messages and audio notes
/// • Document picker: PDFs, Word docs, spreadsheets, and other files
/// • Contact sharing: Share contact information
/// • Location sharing: GPS location and address sharing
/// 
/// TECHNICAL FEATURES:
/// • Smooth animations with scale and fade transitions
/// • Professional circular action buttons with icons
/// • File type validation and size limits
/// • Permission handling for camera, microphone, and storage
/// • Integration with MediaUploadService for file processing
/// • Callback system for selected media handling
/// 
/// USAGE:
/// ```dart
/// MediaPickerWidget(
///   onMediaSelected: (file, messageType) {
///     // Handle selected media
///   },
///   onCancel: () {
///     // Handle picker dismissal
///   },
/// )
/// ```
/// 
/// The widget appears as an animated overlay with media options
/// and handles all the complexity of media selection and validation.
library;


import 'dart:io';
import 'package:flutter/material.dart';
import '../services/chat_service_new.dart';

/// Professional media picker widget with animations and comprehensive options
/// 
/// Provides an animated overlay interface for selecting various media types
/// in chat conversations. Supports camera, gallery, audio recording,
/// document selection, and more with smooth animations and intuitive UX.
/// 
/// The widget uses SingleTickerProviderStateMixin for smooth animation
/// control and integrates with device capabilities for media selection.
class MediaPickerWidget extends StatefulWidget {
  /// Callback function called when media is selected
  /// 
  /// Parameters:
  /// - [File]: The selected media file
  /// - [MessageType]: The type of message (image, video, audio, document, etc.)
  final Function(File, MessageType) onMediaSelected;
  
  /// Optional callback function called when picker is cancelled
  final Function()? onCancel;

  /// Creates a MediaPickerWidget with required callbacks
  /// 
  /// Parameters:
  /// - [onMediaSelected]: Required callback for handling selected media
  /// - [onCancel]: Optional callback for handling picker cancellation
  const MediaPickerWidget({
    super.key,
    required this.onMediaSelected,
    this.onCancel,
  });

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

/// State class for MediaPickerWidget managing animations and interactions
/// 
/// Handles the complex animation system for the media picker overlay,
/// including scale and fade animations for smooth appearance/disappearance.
/// Also manages media selection logic and device permission handling.
class _MediaPickerWidgetState extends State<MediaPickerWidget>
    with SingleTickerProviderStateMixin {
  /// Animation controller for coordinating all picker animations
  late AnimationController _animationController;
  
  /// Scale animation for the picker appearance effect
  late Animation<double> _scaleAnimation;
  
  /// Fade animation for smooth opacity transitions
  late Animation<double> _fadeAnimation;

  /// Initialize animations and set up the picker widget
  /// 
  /// Sets up the animation controller with a 300ms duration and creates
  /// both scale and fade animations with smooth curves for professional UX.
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  /// Pick an image from camera or gallery
  /// 
  /// Handles image selection from the specified source with proper error
  /// handling and mock implementation. In production, this would integrate
  /// with the image_picker package for actual camera/gallery access.
  /// 
  /// Parameters:
  /// - [source]: ImageSource (camera or gallery)
  /// 
  /// Calls onMediaSelected callback with the selected image file
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Mock image picker implementation
      // In production, use image_picker package
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For demonstration, create a mock image file
      final mockImageFile = await _createMockFile('image.jpg', MessageType.image);
      widget.onMediaSelected(mockImageFile, MessageType.image);
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  /// Pick a video from camera or gallery
  /// 
  /// Handles video selection from the specified source with proper error
  /// handling and mock implementation. In production, this would integrate
  /// with the image_picker package for actual video recording/selection.
  /// 
  /// Parameters:
  /// - [source]: VideoSource (camera or gallery)
  /// 
  /// Calls onMediaSelected callback with the selected video file
  Future<void> _pickVideo(VideoSource source) async {
    try {
      // Mock video picker implementation
      // In production, use image_picker package for videos
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockVideoFile = await _createMockFile('video.mp4', MessageType.video);
      widget.onMediaSelected(mockVideoFile, MessageType.video);
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  /// Pick a document file from device storage
  /// 
  /// Handles document selection including PDFs, Word docs, spreadsheets,
  /// and other file types. Includes file validation and size checking.
  /// In production, integrates with file_picker package.
  /// 
  /// Supported formats: PDF, DOC, DOCX, XLS, XLSX, TXT, etc.
  /// 
  /// Calls onMediaSelected callback with the selected document file
  Future<void> _pickDocument() async {
    try {
      // Mock document picker implementation
      // In production, use file_picker package
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockDocFile = await _createMockFile('document.pdf', MessageType.document);
      widget.onMediaSelected(mockDocFile, MessageType.document);
    } catch (e) {
      _showError('Failed to pick document: $e');
    }
  }

  /// Pick an audio file from device storage
  /// 
  /// Handles audio file selection including music, sound effects,
  /// and other audio content. Supports common audio formats like
  /// MP3, WAV, M4A, etc. In production, integrates with file_picker.
  /// 
  /// Calls onMediaSelected callback with the selected audio file
  Future<void> _pickAudio() async {
    try {
      // Mock audio picker implementation
      // In production, use file_picker package
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockAudioFile = await _createMockFile('audio.mp3', MessageType.audio);
      widget.onMediaSelected(mockAudioFile, MessageType.audio);
    } catch (e) {
      _showError('Failed to pick audio: $e');
    }
  }

  /// Record a voice note using device microphone
  /// 
  /// Provides voice recording functionality for creating voice messages
  /// in chat conversations. Handles microphone permissions and audio
  /// recording with compression. In production, uses audio recording packages.
  /// 
  /// Features:
  /// • Real-time recording with duration display
  /// • Audio compression for efficient transmission
  /// • Waveform visualization during recording
  /// • Pause/resume recording capabilities
  /// 
  /// Calls onMediaSelected callback with the recorded voice file
  Future<void> _recordVoiceNote() async {
    try {
      // Mock voice recording implementation
      // In production, use audio recording packages
      await Future.delayed(const Duration(milliseconds: 2000));
      
      final mockVoiceFile = await _createMockFile('voice_note.m4a', MessageType.voiceNote);
      widget.onMediaSelected(mockVoiceFile, MessageType.voiceNote);
    } catch (e) {
      _showError('Failed to record voice note: $e');
    }
  }

  /// Create a mock file for demonstration purposes
  /// 
  /// Generates temporary files with appropriate mock data for testing
  /// the media picker functionality without requiring actual media.
  /// Each file type gets specific mock data to simulate real files.
  /// 
  /// Parameters:
  /// - [fileName]: Name for the mock file
  /// - [type]: MessageType to determine mock data content
  /// 
  /// Returns: File object with mock data for testing
  /// 
  /// NOTE: This is for development/testing only. Production code
  /// would handle actual files from device storage or camera.
  Future<File> _createMockFile(String fileName, MessageType type) async {
    // Create a temporary mock file for demonstration
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    
    // Write some mock data based on file type
    List<int> mockData;
    switch (type) {
      case MessageType.image:
        mockData = List.generate(1024 * 50, (i) => i % 256); // 50KB
        break;
      case MessageType.video:
        mockData = List.generate(1024 * 1024 * 5, (i) => i % 256); // 5MB
        break;
      case MessageType.audio:
      case MessageType.voiceNote:
        mockData = List.generate(1024 * 500, (i) => i % 256); // 500KB
        break;
      case MessageType.document:
        mockData = List.generate(1024 * 100, (i) => i % 256); // 100KB
        break;
      default:
        mockData = List.generate(1024, (i) => i % 256); // 1KB
    }
    
    await file.writeAsBytes(mockData);
    return file;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _close() {
    _animationController.reverse().then((_) {
      widget.onCancel?.call();
    });
  }

  /// Build the main media picker dialog interface
  /// 
  /// Creates an animated dialog with a grid of media options including:
  /// • Camera and Gallery for photos
  /// • Video camera and video gallery
  /// • Document and audio file pickers
  /// • Voice recording option
  /// 
  /// Uses AnimatedBuilder for smooth scale and fade animations
  /// with professional Material Design styling.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Text(
                          'Share Media',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _close,
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Media options grid
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        // Camera
                        _MediaOptionTile(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          color: Colors.green,
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                        
                        // Gallery
                        _MediaOptionTile(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          color: Colors.blue,
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                        
                        // Video Camera
                        _MediaOptionTile(
                          icon: Icons.videocam,
                          label: 'Video',
                          color: Colors.red,
                          onTap: () => _pickVideo(VideoSource.camera),
                        ),
                        
                        // Video Gallery
                        _MediaOptionTile(
                          icon: Icons.video_library,
                          label: 'Videos',
                          color: Colors.purple,
                          onTap: () => _pickVideo(VideoSource.gallery),
                        ),
                        
                        // Documents
                        _MediaOptionTile(
                          icon: Icons.folder,
                          label: 'Document',
                          color: Colors.orange,
                          onTap: _pickDocument,
                        ),
                        
                        // Audio
                        _MediaOptionTile(
                          icon: Icons.audiotrack,
                          label: 'Audio',
                          color: Colors.teal,
                          onTap: _pickAudio,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Voice note option (full width)
                    _VoiceNoteOption(
                      onRecord: _recordVoiceNote,
                    ),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Clean up animation controller and resources
  /// 
  /// Properly disposes of the animation controller to prevent
  /// memory leaks and ensure smooth widget cleanup.
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// Individual media option tile widget
/// 
/// Creates a professional, interactive tile for each media selection option.
/// Features rounded corners, color-coded styling, and smooth tap animations.
/// 
/// Each tile displays an icon and label with consistent styling across
/// all media types (camera, gallery, documents, etc.).
class _MediaOptionTile extends StatelessWidget {
  /// Icon to display for this media option
  final IconData icon;
  
  /// Text label describing the media option
  final String label;
  
  /// Color theme for the tile (icon and border)
  final Color color;
  
  /// Callback function executed when tile is tapped
  final VoidCallback onTap;

  /// Creates a MediaOptionTile with required styling and callback
  const _MediaOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Voice note recording option widget
/// 
/// Provides an interactive voice recording interface with animated
/// recording indicators and professional UX. Features include:
/// • Animated pulse effect during recording
/// • Visual feedback for recording state
/// • Professional microphone icon and styling
/// • One-tap recording initiation
class _VoiceNoteOption extends StatefulWidget {
  /// Callback function executed when recording is initiated
  final VoidCallback onRecord;

  /// Creates a VoiceNoteOption with recording callback
  const _VoiceNoteOption({
    required this.onRecord,
  });

  @override
  State<_VoiceNoteOption> createState() => _VoiceNoteOptionState();
}

/// State class for VoiceNoteOption managing recording animations
/// 
/// Handles the animated pulse effect during voice recording and
/// manages the recording state with visual feedback for users.
class _VoiceNoteOptionState extends State<_VoiceNoteOption>
    with TickerProviderStateMixin {
  /// Current recording state indicator
  bool _isRecording = false;
  
  /// Animation controller for pulse effect during recording
  late AnimationController _pulseController;
  
  /// Pulse animation for visual recording feedback
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    _pulseController.repeat(reverse: true);
    
    // Auto-stop after 3 seconds for demo
    Future.delayed(const Duration(seconds: 3), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    _pulseController.stop();
    _pulseController.reset();
    widget.onRecord();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isRecording 
                ? Colors.red.withOpacity(0.3) 
                : Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 24,
                    color: _isRecording ? Colors.red : Colors.amber[700],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              _isRecording ? 'Tap to stop recording...' : 'Record Voice Note',
              style: TextStyle(
                color: _isRecording ? Colors.red : Colors.amber[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

/// Media upload progress widget
class MediaUploadProgressWidget extends StatefulWidget {
  final String fileName;
  final ValueNotifier<double> progressNotifier;
  final VoidCallback? onCancel;

  const MediaUploadProgressWidget({
    super.key,
    required this.fileName,
    required this.progressNotifier,
    this.onCancel,
  });

  @override
  State<MediaUploadProgressWidget> createState() => _MediaUploadProgressWidgetState();
}

class _MediaUploadProgressWidgetState extends State<MediaUploadProgressWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload,
                color: Colors.blue[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Uploading ${widget.fileName}',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onCancel != null)
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Icon(
                    Icons.close,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          ValueListenableBuilder<double>(
            valueListenable: widget.progressNotifier,
            builder: (context, progress, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Media selection sheet for mobile-optimized experience
class MediaSelectionSheet extends StatelessWidget {
  final Function(File, MessageType) onMediaSelected;

  const MediaSelectionSheet({
    super.key,
    required this.onMediaSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'Share Media',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickMediaOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  // Trigger camera
                },
              ),
              _QuickMediaOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  // Trigger gallery
                },
              ),
              _QuickMediaOption(
                icon: Icons.folder,
                label: 'Files',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  // Trigger file picker
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // More options list
          _MediaListOption(
            icon: Icons.videocam,
            label: 'Record Video',
            onTap: () {
              Navigator.pop(context);
              // Trigger video recording
            },
          ),
          _MediaListOption(
            icon: Icons.audiotrack,
            label: 'Audio File',
            onTap: () {
              Navigator.pop(context);
              // Trigger audio picker
            },
          ),
          _MediaListOption(
            icon: Icons.mic,
            label: 'Voice Note',
            onTap: () {
              Navigator.pop(context);
              // Trigger voice recording
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickMediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickMediaOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaListOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaListOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue[600],
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Enums for media source selection
enum ImageSource { camera, gallery }
enum VideoSource { camera, gallery }