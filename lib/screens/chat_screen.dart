/**
 * AFO Chat Application - Chat Screen
 * AFO: Afaan Oromoo Chat Services
 * 
 * This screen provides the individual chat interface for conversations
 * between users in the Afaan Oromoo community. Features include:
 * 
 * - WhatsApp-style chat interface with message bubbles
 * - Real-time message sending and receiving (mock implementation)
 * - Professional UI with blue theme matching AFO branding
 * - Message input with send button functionality
 * - Contact information display in app bar
 * - Scrollable message history with proper alignment
 * 
 * The screen uses ChatService for message operations and maintains
 * state for the message input controller and conversation history.
 */

import 'package:flutter/material.dart';
import 'dart:io';

import '../services/advanced_call_service.dart';
import '../services/chat_service_new.dart';
import '../services/media_upload_service.dart';
import '../widgets/media_picker.dart';
import '../widgets/media_viewers.dart';
import 'advanced_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String contactId;
  final String contactName;

  const ChatScreen({
    Key? key,
    required this.contactId,
    required this.contactName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final MediaUploadService _mediaUploadService = MediaUploadService();
  List<ChatMessage> _messages = [];
  bool _isGroupChat = false;
  String? _groupId;
  final Map<String, ValueNotifier<double>> _uploadProgress = {};
  final List<String> _activeUploads = [];

  @override
  void initState() {
    super.initState();
    _setupChat();
  }

  void _setupChat() {
    // Set current user ID (in real app, get from AuthService)
    _chatService.setCurrentUser('current_user', 'You');
    
    // Check if this is a group chat (group IDs start with 'group_')
    _isGroupChat = widget.contactId.startsWith('group_');
    if (_isGroupChat) {
      _groupId = widget.contactId;
    }
    
    // Listen to messages based on chat type
    Stream<List<ChatMessage>> messageStream;
    if (_isGroupChat) {
      messageStream = _chatService.getGroupMessagesStream(widget.contactId);
    } else {
      messageStream = _chatService.getMessagesStream(userId: widget.contactId);
    }
    
    messageStream.listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        
        // Mark messages as read
        if (messages.isNotEmpty) {
          final latestMessage = messages.first;
          _chatService.markMessageAsRead(latestMessage.id, latestMessage.chatRoomId);
        }
      }
    });
  }

  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    
    try {
      if (_isGroupChat) {
        await _chatService.sendGroupMessage(
          groupId: widget.contactId,
          message: text,
          type: MessageType.text,
        );
      } else {
        await _chatService.sendMessage(
          receiverId: widget.contactId,
          message: text,
          type: MessageType.text,
        );
      }
      
      // Auto-scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade700,
              child: Text(
                widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.contactName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Online",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdvancedCallScreen(
                    remoteUserId: widget.contactId,
                    remoteUserName: widget.contactName,
                    callType: CallType.voice,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdvancedCallScreen(
                    remoteUserId: widget.contactId,
                    remoteUserName: widget.contactName,
                    callType: CallType.video,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
              ),
              child: Column(
                children: [
                  // Upload progress indicators
                  ..._activeUploads.map((uploadId) {
                    final progressNotifier = _uploadProgress[uploadId];
                    if (progressNotifier != null) {
                      return MediaUploadProgressWidget(
                        fileName: 'Uploading media...',
                        progressNotifier: progressNotifier,
                        onCancel: () => _cancelUpload(uploadId),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                  
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Determine if this message was sent by current user
    final isMe = message.senderId == 'current_user';
    final isSystem = message.senderId == 'system';
    
    // System messages (group events)
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && _isGroupChat) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getAvatarColor(message.senderName),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMe && !_isGroupChat) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: Text(
                widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue.shade700 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show sender name in group chats
                  if (!isMe && _isGroupChat) ...[
                    Text(
                      message.senderName,
                      style: TextStyle(
                        color: _getAvatarColor(message.senderName),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Media content
                  if (message.mediaAttachment != null)
                    _buildMediaContent(message),
                  // Text content
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildMessageStatusIcon(message.status),
                      ],
                    ],
                  ),
                  // Show read receipts for group messages
                  if (isMe && _isGroupChat && message.readBy.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Read by ${message.readBy.length}',
                      style: TextStyle(
                        color: isMe ? Colors.white60 : Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.shade600,
              child: const Text(
                'Me',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
              onPressed: _showMediaPicker,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time,
          size: 12,
          color: Colors.white60,
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 12,
          color: Colors.white60,
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 12,
          color: Colors.white60,
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 12,
          color: Colors.lightBlue.shade200,
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 12,
          color: Colors.red.shade300,
        );
    }
  }

  Color _getAvatarColor(String name) {
    // Generate consistent colors based on name
    final colors = [
      Colors.purple.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.pink.shade400,
    ];
    
    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}h ago";
    } else {
      return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
    }
  }

  // Media picker functionality
  void _showMediaPicker() {
    showDialog(
      context: context,
      builder: (context) => MediaPickerWidget(
        onMediaSelected: _handleMediaSelection,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  // Handle selected media file
  Future<void> _handleMediaSelection(File file, MessageType mediaType) async {
    Navigator.of(context).pop(); // Close media picker
    
    try {
      // Start upload
      final uploadResult = await _mediaUploadService.uploadFile(
        file: file,
        mediaType: mediaType,
        chatRoomId: _isGroupChat ? widget.contactId : 'direct_${widget.contactId}',
        senderId: 'current_user',
      );
      
      if (uploadResult.success) {
        // Create media attachment
        final mediaAttachment = MediaAttachment(
          id: uploadResult.uploadId,
          fileName: file.path.split('/').last,
          filePath: file.path,
          fileUrl: uploadResult.fileUrl ?? '',
          fileSize: uploadResult.fileSize ?? 0,
          mimeType: uploadResult.mimeType ?? '',
          mediaType: mediaType,
          thumbnailUrl: uploadResult.thumbnailUrl,
          uploadedAt: DateTime.now(),
          encryptionKey: uploadResult.encryptionKey,
        );
        
        // Send media message
        if (_isGroupChat) {
          await _chatService.sendGroupMessage(
            groupId: widget.contactId,
            message: mediaType == MessageType.image ? 'Photo' : 
                    mediaType == MessageType.video ? 'Video' :
                    mediaType == MessageType.audio ? 'Audio' :
                    mediaType == MessageType.document ? 'Document' : 'Media',
            type: mediaType,
            mediaAttachment: mediaAttachment,
          );
        } else {
          await _chatService.sendMessage(
            receiverId: widget.contactId,
            message: mediaType == MessageType.image ? 'Photo' : 
                    mediaType == MessageType.video ? 'Video' :
                    mediaType == MessageType.audio ? 'Audio' :
                    mediaType == MessageType.document ? 'Document' : 'Media',
            type: mediaType,
            mediaAttachment: mediaAttachment,
          );
        }
      } else {
        _showError('Failed to upload media: ${uploadResult.error}');
      }
    } catch (e) {
      _showError('Error uploading media: $e');
    }
  }

  // Build media content for messages
  Widget _buildMediaContent(ChatMessage message) {
    final mediaAttachment = message.mediaAttachment!;
    
    switch (mediaAttachment.mediaType) {
      case MessageType.image:
        return Container(
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 200,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ImageViewerWidget(
              mediaAttachment: mediaAttachment,
              onDownload: _downloadMedia,
            ),
          ),
        );
      
      case MessageType.video:
        return Container(
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 180,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: VideoPlayerWidget(
            mediaAttachment: mediaAttachment,
            onDownload: _downloadMedia,
          ),
        );
      
      case MessageType.audio:
      case MessageType.voiceNote:
        return Container(
          width: 250,
          margin: const EdgeInsets.only(bottom: 8),
          child: AudioPlayerWidget(
            mediaAttachment: mediaAttachment,
            onDownload: _downloadMedia,
          ),
        );
      
      case MessageType.document:
        return Container(
          width: 250,
          margin: const EdgeInsets.only(bottom: 8),
          child: DocumentViewerWidget(
            mediaAttachment: mediaAttachment,
            onDownload: _downloadMedia,
          ),
        );
      
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_file, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                mediaAttachment.fileName,
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],
          ),
        );
    }
  }

  // Download media file
  void _downloadMedia(MediaAttachment mediaAttachment) {
    // In production, trigger download using MediaDownloadService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${mediaAttachment.fileName}...'),
      ),
    );
  }

  // Cancel upload
  void _cancelUpload(String uploadId) {
    _mediaUploadService.cancelUpload(uploadId);
    setState(() {
      _activeUploads.remove(uploadId);
      _uploadProgress.remove(uploadId);
    });
  }

  // Show error message
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
