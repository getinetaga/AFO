import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chat_service_new.dart';
import '../services/media_download_service.dart';

/// Image viewer widget with zoom and pan capabilities
class ImageViewerWidget extends StatefulWidget {
  final MediaAttachment mediaAttachment;
  final File? localFile;
  final Function(MediaAttachment)? onDownload;

  const ImageViewerWidget({
    Key? key,
    required this.mediaAttachment,
    this.localFile,
    this.onDownload,
  }) : super(key: key);

  @override
  State<ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> {
  final TransformationController _transformationController = TransformationController();
  File? _displayFile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  Future<void> _initializeImage() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.localFile != null && await widget.localFile!.exists()) {
        setState(() {
          _displayFile = widget.localFile;
          _isLoading = false;
        });
      } else {
        // Try to download the image
        final downloadService = MediaDownloadService();
        final result = await downloadService.downloadMedia(
          mediaAttachment: widget.mediaAttachment,
          useCache: true,
        );
        
        if (result.success && result.file != null) {
          setState(() {
            _displayFile = result.file;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result.error ?? 'Failed to load image';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading image: $e';
        _isLoading = false;
      });
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _displayFile == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Image not available',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (widget.onDownload != null) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => widget.onDownload!(widget.mediaAttachment),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Retry Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: _resetZoom,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            _displayFile!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

/// Video player widget with controls
class VideoPlayerWidget extends StatefulWidget {
  final MediaAttachment mediaAttachment;
  final File? localFile;
  final Function(MediaAttachment)? onDownload;

  const VideoPlayerWidget({
    Key? key,
    required this.mediaAttachment,
    this.localFile,
    this.onDownload,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  File? _videoFile;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.localFile != null && await widget.localFile!.exists()) {
        setState(() {
          _videoFile = widget.localFile;
          _isLoading = false;
        });
      } else {
        // Try to download the video
        final downloadService = MediaDownloadService();
        final result = await downloadService.downloadMedia(
          mediaAttachment: widget.mediaAttachment,
          useCache: true,
        );
        
        if (result.success && result.file != null) {
          setState(() {
            _videoFile = result.file;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result.error ?? 'Failed to load video';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading video: $e';
        _isLoading = false;
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    // In production, control actual video player
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null || _videoFile == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Video not available',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (widget.onDownload != null) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => widget.onDownload!(widget.mediaAttachment),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video preview/thumbnail
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 64,
              color: Colors.white70,
            ),
          ),
          
          // Play/Pause button
          Positioned(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Video info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.mediaAttachment.formattedFileSize,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (widget.mediaAttachment.duration != null)
                    Text(
                      _formatDuration(widget.mediaAttachment.duration!),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Audio player widget with waveform visualization
class AudioPlayerWidget extends StatefulWidget {
  final MediaAttachment mediaAttachment;
  final File? localFile;
  final Function(MediaAttachment)? onDownload;

  const AudioPlayerWidget({
    Key? key,
    required this.mediaAttachment,
    this.localFile,
    this.onDownload,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with TickerProviderStateMixin {
  File? _audioFile;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late AnimationController _waveAnimationController;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.localFile != null && await widget.localFile!.exists()) {
        setState(() {
          _audioFile = widget.localFile;
          _duration = widget.mediaAttachment.duration ?? const Duration(minutes: 3);
          _isLoading = false;
        });
      } else {
        // Try to download the audio
        final downloadService = MediaDownloadService();
        final result = await downloadService.downloadMedia(
          mediaAttachment: widget.mediaAttachment,
          useCache: true,
        );
        
        if (result.success && result.file != null) {
          setState(() {
            _audioFile = result.file;
            _duration = widget.mediaAttachment.duration ?? const Duration(minutes: 3);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result.error ?? 'Failed to load audio';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading audio: $e';
        _isLoading = false;
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      _waveAnimationController.repeat();
      // In production, start audio playback
    } else {
      _waveAnimationController.stop();
      // In production, pause audio playback
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading audio...'),
          ],
        ),
      );
    }

    if (_error != null || _audioFile == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.audiotrack_rounded,
                  color: Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.mediaAttachment.fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.red[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _error ?? 'Audio not available',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
            if (widget.onDownload != null) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => widget.onDownload!(widget.mediaAttachment),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio file info
          Row(
            children: [
              Icon(
                Icons.audiotrack_rounded,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.mediaAttachment.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                widget.mediaAttachment.formattedFileSize,
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Audio controls
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Waveform visualization
              Expanded(
                child: AnimatedBuilder(
                  animation: _waveAnimationController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(double.infinity, 30),
                      painter: WaveformPainter(
                        progress: _position.inMilliseconds / _duration.inMilliseconds,
                        isPlaying: _isPlaying,
                        animationValue: _waveAnimationController.value,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Time display
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }
}

/// Document viewer widget with file info
class DocumentViewerWidget extends StatefulWidget {
  final MediaAttachment mediaAttachment;
  final File? localFile;
  final Function(MediaAttachment)? onDownload;

  const DocumentViewerWidget({
    Key? key,
    required this.mediaAttachment,
    this.localFile,
    this.onDownload,
  }) : super(key: key);

  @override
  State<DocumentViewerWidget> createState() => _DocumentViewerWidgetState();
}

class _DocumentViewerWidgetState extends State<DocumentViewerWidget> {
  File? _documentFile;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeDocument();
  }

  Future<void> _initializeDocument() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.localFile != null && await widget.localFile!.exists()) {
        setState(() {
          _documentFile = widget.localFile;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading document: $e';
        _isLoading = false;
      });
    }
  }

  IconData _getDocumentIcon() {
    final extension = widget.mediaAttachment.fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor() {
    final extension = widget.mediaAttachment.fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  void _openDocument() {
    // In production, open the document with appropriate viewer
    // For now, just trigger download if needed
    if (_documentFile == null && widget.onDownload != null) {
      widget.onDownload!(widget.mediaAttachment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentColor = _getDocumentColor();
    final documentIcon = _getDocumentIcon();

    return GestureDetector(
      onTap: _openDocument,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: documentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: documentColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: documentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                documentIcon,
                color: documentColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mediaAttachment.fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: documentColor.withOpacity(0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.mediaAttachment.formattedFileSize,
                    style: TextStyle(
                      color: documentColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            if (_isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: documentColor,
                ),
              )
            else if (_documentFile != null)
              Icon(
                Icons.visibility,
                color: documentColor,
                size: 20,
              )
            else
              Icon(
                Icons.download,
                color: documentColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for audio waveform
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final double animationValue;

  WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[300]!
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final playedPaint = Paint()
      ..color = Colors.blue[600]!
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final barCount = 40;
    final barWidth = size.width / barCount;
    final playedWidth = size.width * progress;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      
      // Generate pseudo-random heights
      final normalizedHeight = (i * 7 % 15) / 15.0;
      var barHeight = size.height * (0.2 + normalizedHeight * 0.8);
      
      // Add animation for playing state
      if (isPlaying && (x - playedWidth).abs() < barWidth * 3) {
        final animationOffset = (animationValue * 2 * 3.14159) + (i * 0.5);
        barHeight *= (1.0 + 0.3 * (1.0 + Math.sin(animationOffset)) / 2);
      }
      
      final isPlayed = x <= playedWidth;
      final currentPaint = isPlayed ? playedPaint : paint;
      
      canvas.drawLine(
        Offset(x, (size.height - barHeight) / 2),
        Offset(x, (size.height + barHeight) / 2),
        currentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Import required for Math.sin
import 'dart:math' as Math;