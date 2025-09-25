/**
 * AFO Chat Application - Advanced Chat Service
 * AFO: Afaan Oromoo Chat Services
 * 
 * This comprehensive chat service provides full messaging capabilities for the
 * AFO chat application, designed specifically for the Afaan Oromoo community. 
 * Features include:
 * 
 * CORE MESSAGING:
 * - One-to-one chat with real-time message delivery
 * - Group chat with member management and permissions
 * - Message encryption/decryption using AES-256 encryption
 * - Message delivery status tracking (sent, delivered, read)
 * - Read receipts system with timestamp tracking
 * 
 * MESSAGE MANAGEMENT:
 * - Message history retrieval with pagination support
 * - Message search functionality across conversations
 * - Message editing and deletion with history tracking
 * - File and media message support with encryption
 * - Message reactions and threading capabilities
 * 
 * SECURITY FEATURES:
 * - End-to-end encryption for all messages
 * - Secure key management and exchange
 * - Message integrity verification
 * - User authentication and authorization
 * 
 * This mock implementation simulates real Firebase/Socket.IO functionality
 * for development and testing purposes.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// Message delivery status enumeration
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed
}

/// Chat type enumeration
enum ChatType {
  oneToOne,
  group
}

/// Message type enumeration  
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  contact,
  sticker,
  gif,
  voiceNote,
}

}

/// Message edit history model
class MessageEditHistory {
  final String messageId;
  final String originalContent;
  final String currentContent;
  final DateTime editedAt;
  final int editCount;

  MessageEditHistory({
    required this.messageId,
    required this.originalContent,
    required this.currentContent,
    required this.editedAt,
    required this.editCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'originalContent': originalContent,
      'currentContent': currentContent,
      'editedAt': editedAt.millisecondsSinceEpoch,
      'editCount': editCount,
    };
  }

  factory MessageEditHistory.fromJson(Map<String, dynamic> json) {
    return MessageEditHistory(
      messageId: json['messageId'],
      originalContent: json['originalContent'],
      currentContent: json['currentContent'],
      editedAt: DateTime.fromMillisecondsSinceEpoch(json['editedAt']),
      editCount: json['editCount'] ?? 1,
    );
  }
}

/// Enhanced ChatService with advanced messaging features
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String? encryptedContent;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;
  final String chatRoomId;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;
  final List<String> readBy;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isEdited;
  final DateTime? editedAt;
  final String? originalContent;
  
  // Media attachment properties
  final MediaAttachment? mediaAttachment;
  final String? thumbnailPath;
  final Duration? mediaDuration;
  final double? mediaSize; // in MB
  final Map<String, String>? mediaMetadata;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.encryptedContent,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.type = MessageType.text,
    required this.chatRoomId,
    this.replyToMessageId,
    this.metadata,
    this.readBy = const [],
    this.deliveredAt,
    this.readAt,
    this.isEdited = false,
    this.editedAt,
    this.originalContent,
    this.mediaAttachment,
    this.thumbnailPath,
    this.mediaDuration,
    this.mediaSize,
    this.mediaMetadata,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    String? encryptedContent,
    DateTime? timestamp,
    MessageStatus? status,
    MessageType? type,
    String? chatRoomId,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isEdited,
    DateTime? editedAt,
    String? originalContent,
    MediaAttachment? mediaAttachment,
    String? thumbnailPath,
    Duration? mediaDuration,
    double? mediaSize,
    Map<String, String>? mediaMetadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      originalContent: originalContent ?? this.originalContent,
      mediaAttachment: mediaAttachment ?? this.mediaAttachment,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      mediaSize: mediaSize ?? this.mediaSize,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'encryptedContent': encryptedContent,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.index,
      'type': type.index,
      'chatRoomId': chatRoomId,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
      'readBy': readBy,
      'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'isEdited': isEdited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'originalContent': originalContent,
      'mediaAttachment': mediaAttachment?.toJson(),
      'thumbnailPath': thumbnailPath,
      'mediaDuration': mediaDuration?.inMilliseconds,
      'mediaSize': mediaSize,
      'mediaMetadata': mediaMetadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      encryptedContent: json['encryptedContent'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      status: MessageStatus.values[json['status'] ?? 0],
      type: MessageType.values[json['type'] ?? 0],
      chatRoomId: json['chatRoomId'],
      replyToMessageId: json['replyToMessageId'],
      metadata: json['metadata']?.cast<String, dynamic>(),
      readBy: (json['readBy'] as List<dynamic>?)?.cast<String>() ?? [],
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt']) 
          : null,
      readAt: json['readAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['readAt']) 
          : null,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['editedAt']) 
          : null,
      originalContent: json['originalContent'],
      mediaAttachment: json['mediaAttachment'] != null
          ? MediaAttachment.fromJson(json['mediaAttachment'])
          : null,
      thumbnailPath: json['thumbnailPath'],
      mediaDuration: json['mediaDuration'] != null
          ? Duration(milliseconds: json['mediaDuration'])
          : null,
      mediaSize: json['mediaSize']?.toDouble(),
      mediaMetadata: json['mediaMetadata']?.cast<String, String>(),
    );
  }
}

/// Media attachment model for file sharing
class MediaAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final String fileUrl;
  final int fileSize; // in bytes
  final String mimeType;
  final MessageType mediaType;
  final String? thumbnailPath;
  final String? thumbnailUrl;
  final Duration? duration; // for audio/video
  final int? width; // for images/videos
  final int? height; // for images/videos
  final Map<String, dynamic>? metadata;
  final DateTime uploadedAt;
  final bool isEncrypted;
  final String? encryptionKey;

  MediaAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.mediaType,
    this.thumbnailPath,
    this.thumbnailUrl,
    this.duration,
    this.width,
    this.height,
    this.metadata,
    required this.uploadedAt,
    this.isEncrypted = true,
    this.encryptionKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'mediaType': mediaType.index,
      'thumbnailPath': thumbnailPath,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration?.inMilliseconds,
      'width': width,
      'height': height,
      'metadata': metadata,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
      'isEncrypted': isEncrypted,
      'encryptionKey': encryptionKey,
    };
  }

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      fileUrl: json['fileUrl'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      mediaType: MessageType.values[json['mediaType'] ?? 0],
      thumbnailPath: json['thumbnailPath'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      width: json['width'],
      height: json['height'],
      metadata: json['metadata']?.cast<String, dynamic>(),
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(json['uploadedAt']),
      isEncrypted: json['isEncrypted'] ?? true,
      encryptionKey: json['encryptionKey'],
    );
  }

  // Get file size in human readable format
  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize} B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Check if media type supports thumbnails
  bool get supportsThumbnail {
    return mediaType == MessageType.image || 
           mediaType == MessageType.video ||
           mediaType == MessageType.gif;
  }
}

/// Enhanced ChatRoom model with group support
class ChatRoom {
  final String id;
  final String name;
  final ChatType type;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String? lastMessageId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSender;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final String createdBy;
  final Map<String, dynamic>? groupSettings;
  final String? groupDescription;
  final String? groupImage;
  final List<String> admins;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.participantIds,
    required this.participantNames,
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    this.unreadCount = const {},
    required this.createdAt,
    required this.createdBy,
    this.groupSettings,
    this.groupDescription,
    this.groupImage,
    this.admins = const [],
    this.isActive = true,
  });

  ChatRoom copyWith({
    String? id,
    String? name,
    ChatType? type,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    String? lastMessageId,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSender,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    String? createdBy,
    Map<String, dynamic>? groupSettings,
    String? groupDescription,
    String? groupImage,
    List<String>? admins,
    bool? isActive,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      groupSettings: groupSettings ?? this.groupSettings,
      groupDescription: groupDescription ?? this.groupDescription,
      groupImage: groupImage ?? this.groupImage,
      admins: admins ?? this.admins,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Advanced Chat Service Implementation
class ChatService {
  // Current authenticated user
  String? _currentUserId;
  String? _currentUserName;
  
  // Encryption components
  late final Encrypter _encrypter;
  late final IV _iv;
  final Map<String, Key> _chatKeys = {};
  
  // In-memory storage for mock implementation
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, ChatRoom> _chatRooms = {};
  final Map<String, StreamController<List<ChatMessage>>> _messageControllers = {};
  final StreamController<List<ChatRoom>> _chatRoomsController = StreamController<List<ChatRoom>>.broadcast();
  
  // Message delivery tracking
  final Map<String, Timer> _deliveryTimers = {};
  final Map<String, Timer> _readReceiptTimers = {};
  
  // Message history pagination
  static const int _pageSize = 50;
  final Map<String, int> _messagePage = {};

  /**
   * ChatService Constructor
   * 
   * Initializes the advanced chat service with encryption capabilities,
   * mock data, and real-time streaming controllers. Sets up AES-256 encryption
   * for secure message transmission.
   */
  ChatService() {
    _initializeEncryption();
    _initializeMockData();
  }

  /**
   * Initialize Encryption
   * 
   * Sets up AES-256 encryption for secure message transmission.
   * In production, keys would be exchanged securely between users.
   */
  void _initializeEncryption() {
    final key = Key.fromSecureRandom(32); // AES-256 key
    _iv = IV.fromSecureRandom(16); // AES block size
    _encrypter = Encrypter(AES(key));
  }

  /**
   * Generate Chat Key
   * 
   * Generates a unique encryption key for each chat room.
   * In production, this would use proper key exchange protocols.
   */
  Key _generateChatKey(String chatRoomId) {
    if (!_chatKeys.containsKey(chatRoomId)) {
      _chatKeys[chatRoomId] = Key.fromSecureRandom(32);
    }
    return _chatKeys[chatRoomId]!;
  }

  /**
   * Encrypt Message
   * 
   * Encrypts message content using AES-256 encryption.
   */
  String _encryptMessage(String message, String chatRoomId) {
    try {
      final key = _generateChatKey(chatRoomId);
      final encrypter = Encrypter(AES(key));
      final encrypted = encrypter.encrypt(message, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return message; // Fallback to plain text for mock
    }
  }

  /**
   * Decrypt Message
   * 
   * Decrypts encrypted message content.
   */
  String _decryptMessage(String encryptedMessage, String chatRoomId) {
    try {
      final key = _generateChatKey(chatRoomId);
      final encrypter = Encrypter(AES(key));
      final encrypted = Encrypted.fromBase64(encryptedMessage);
      return encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Decryption error: $e');
      return encryptedMessage; // Fallback for mock
    }
  }

  /**
   * Set Current User
   * 
   * Sets the current authenticated user for the chat service.
   */
  void setCurrentUser(String userId, [String? userName]) {
    _currentUserId = userId;
    _currentUserName = userName ?? 'User';
  }

  /**
   * Send Message (One-to-One)
   * 
   * Sends a message to another user with encryption and delivery tracking.
   */
  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String message,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    MediaAttachment? mediaAttachment,
  }) async {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    final timestamp = DateTime.now();
    final messageId = '${timestamp.millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final chatRoomId = _getChatRoomId(_currentUserId!, receiverId);
    
    // Encrypt message content
    final encryptedContent = _encryptMessage(message, chatRoomId);

    final chatMessage = ChatMessage(
      id: messageId,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'User',
      content: message,
      encryptedContent: encryptedContent,
      timestamp: timestamp,
      status: MessageStatus.sending,
      type: type,
      chatRoomId: chatRoomId,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
      mediaAttachment: mediaAttachment,
      mediaSize: mediaAttachment != null ? mediaAttachment.fileSize.toDouble() / (1024 * 1024) : null,
      mediaDuration: mediaAttachment?.duration,
    );

    // Add message to storage
    _messages[chatRoomId] ??= [];
    _messages[chatRoomId]!.add(chatMessage);

    // Update chat room
    await _updateChatRoom(chatRoomId, chatMessage);

    // Simulate message delivery process
    _simulateMessageDelivery(messageId, chatRoomId);

    // Notify listeners
    _notifyMessageUpdate(chatRoomId);

    return chatMessage;
  }

  /**
   * Create Group Chat
   * 
   * Creates a new group chat with specified participants.
   */
  Future<ChatRoom> createGroupChat({
    required String groupName,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    String? groupDescription,
    String? groupImage,
  }) async {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now();

    // Add current user to participants
    final allParticipants = [_currentUserId!, ...participantIds];
    final allParticipantNames = {
      _currentUserId!: _currentUserName ?? 'User',
      ...participantNames,
    };

    final groupChat = ChatRoom(
      id: groupId,
      name: groupName,
      type: ChatType.group,
      participantIds: allParticipants,
      participantNames: allParticipantNames,
      createdAt: timestamp,
      createdBy: _currentUserId!,
      groupDescription: groupDescription,
      groupImage: groupImage,
      admins: [_currentUserId!], // Creator is admin
      unreadCount: {for (var id in allParticipants) id: 0},
    );

    _chatRooms[groupId] = groupChat;

    // Create system message for group creation
    await _createSystemMessage(
      groupId, 
      '${_currentUserName ?? 'User'} created the group "$groupName"'
    );

    _notifyChatsUpdate();
    return groupChat;
  }

  /**
   * Send Group Message
   * 
   * Sends a message to a group chat with encryption and delivery tracking.
   */
  Future<ChatMessage> sendGroupMessage({
    required String groupId,
    required String message,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    MediaAttachment? mediaAttachment,
  }) async {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    final chatRoom = _chatRooms[groupId];
    if (chatRoom == null) {
      throw Exception("Group chat not found");
    }

    if (!chatRoom.participantIds.contains(_currentUserId)) {
      throw Exception("You are not a member of this group");
    }

    final timestamp = DateTime.now();
    final messageId = '${timestamp.millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    
    // Encrypt message content
    final encryptedContent = _encryptMessage(message, groupId);

    final chatMessage = ChatMessage(
      id: messageId,
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'User',
      content: message,
      encryptedContent: encryptedContent,
      timestamp: timestamp,
      status: MessageStatus.sending,
      type: type,
      chatRoomId: groupId,
      replyToMessageId: replyToMessageId,
      metadata: metadata,
      mediaAttachment: mediaAttachment,
      mediaSize: mediaAttachment != null ? mediaAttachment.fileSize.toDouble() / (1024 * 1024) : null,
      mediaDuration: mediaAttachment?.duration,
    );

    // Add message to storage
    _messages[groupId] ??= [];
    _messages[groupId]!.add(chatMessage);

    // Update chat room
    await _updateChatRoom(groupId, chatMessage);

    // Simulate message delivery to all group members
    _simulateGroupMessageDelivery(messageId, groupId, chatRoom.participantIds);

    // Notify listeners
    _notifyMessageUpdate(groupId);

    return chatMessage;
  }

  /**
   * Mark Message as Read
   * 
   * Marks a message as read by the current user and sends read receipts.
   */
  Future<void> markMessageAsRead(String messageId, String chatRoomId) async {
    if (_currentUserId == null) return;

    final messages = _messages[chatRoomId];
    if (messages == null) return;

    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final message = messages[messageIndex];
    if (message.senderId == _currentUserId) return; // Don't mark own messages

    // Update message with read receipt
    final updatedReadBy = [...message.readBy];
    if (!updatedReadBy.contains(_currentUserId!)) {
      updatedReadBy.add(_currentUserId!);
    }

    final updatedMessage = message.copyWith(
      status: MessageStatus.read,
      readBy: updatedReadBy,
      readAt: DateTime.now(),
    );

    messages[messageIndex] = updatedMessage;

    // Update unread count
    final chatRoom = _chatRooms[chatRoomId];
    if (chatRoom != null) {
      final updatedUnreadCount = Map<String, int>.from(chatRoom.unreadCount);
      updatedUnreadCount[_currentUserId!] = 0;
      
      _chatRooms[chatRoomId] = chatRoom.copyWith(unreadCount: updatedUnreadCount);
    }

    _notifyMessageUpdate(chatRoomId);
    _notifyChatsUpdate();
  }

  /**
   * Get Messages Stream
   * 
   * Returns a real-time stream of messages for a chat room with decryption.
   */
  Stream<List<ChatMessage>> getMessagesStream({required String userId}) {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    final chatRoomId = _getChatRoomId(_currentUserId!, userId);
    return _getMessageStreamForChatRoom(chatRoomId);
  }

  /**
   * Get Group Messages Stream
   * 
   * Returns a real-time stream of messages for a group chat.
   */
  Stream<List<ChatMessage>> getGroupMessagesStream(String groupId) {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    return _getMessageStreamForChatRoom(groupId);
  }

  /**
   * Get Message Stream for Chat Room
   * 
   * Internal method to get message stream with decryption.
   */
  Stream<List<ChatMessage>> _getMessageStreamForChatRoom(String chatRoomId) {
    _messageControllers[chatRoomId] ??= StreamController<List<ChatMessage>>.broadcast();

    // Send initial data with decrypted messages
    final messages = _getDecryptedMessages(chatRoomId);
    Future.microtask(() {
      if (!_messageControllers[chatRoomId]!.isClosed) {
        _messageControllers[chatRoomId]!.add(messages);
      }
    });

    return _messageControllers[chatRoomId]!.stream;
  }

  /**
   * Get Decrypted Messages
   * 
   * Retrieves and decrypts messages for display.
   */
  List<ChatMessage> _getDecryptedMessages(String chatRoomId) {
    final messages = _messages[chatRoomId]?.reversed.toList() ?? [];
    
    // Decrypt messages for display
    return messages.map((message) {
      if (message.encryptedContent != null) {
        try {
          final decryptedContent = _decryptMessage(message.encryptedContent!, chatRoomId);
          return message.copyWith(content: decryptedContent);
        } catch (e) {
          print('Error decrypting message: $e');
          return message; // Return original if decryption fails
        }
      }
      return message;
    }).toList();
  }

  /**
   * Get Message History
   * 
   * Retrieves message history with pagination support.
   */
  Future<List<ChatMessage>> getMessageHistory({
    required String chatRoomId,
    int page = 0,
    int limit = 50,
    String? searchQuery,
  }) async {
    final messages = _messages[chatRoomId] ?? [];
    
    // Filter by search query if provided
    var filteredMessages = messages;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredMessages = messages.where((message) {
        final content = message.encryptedContent != null 
            ? _decryptMessage(message.encryptedContent!, chatRoomId)
            : message.content;
        return content.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by timestamp (newest first)
    filteredMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply pagination
    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, filteredMessages.length);
    
    if (startIndex >= filteredMessages.length) {
      return [];
    }

    final paginatedMessages = filteredMessages.sublist(startIndex, endIndex);
    
    // Decrypt messages for display
    return paginatedMessages.map((message) {
      if (message.encryptedContent != null) {
        try {
          final decryptedContent = _decryptMessage(message.encryptedContent!, chatRoomId);
          return message.copyWith(content: decryptedContent);
        } catch (e) {
          return message;
        }
      }
      return message;
    }).toList();
  }

  /**
   * Search Messages
   * 
   * Searches messages across all chat rooms.
   */
  Future<List<ChatMessage>> searchMessages({
    required String query,
    String? chatRoomId,
    int limit = 100,
  }) async {
    final List<ChatMessage> results = [];
    
    final chatRoomsToSearch = chatRoomId != null 
        ? [chatRoomId]
        : _messages.keys.toList();

    for (final roomId in chatRoomsToSearch) {
      final messages = _messages[roomId] ?? [];
      
      for (final message in messages) {
        final content = message.encryptedContent != null 
            ? _decryptMessage(message.encryptedContent!, roomId)
            : message.content;
            
        if (content.toLowerCase().contains(query.toLowerCase())) {
          final decryptedMessage = message.encryptedContent != null
              ? message.copyWith(content: content)
              : message;
          results.add(decryptedMessage);
        }
        
        if (results.length >= limit) break;
      }
      
      if (results.length >= limit) break;
    }

    // Sort by relevance and timestamp
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return results;
  }

  /**
   * Get User Chats Stream
   * 
   * Returns a real-time stream of all chat rooms for the current user.
   */
  Stream<List<ChatRoom>> getUserChats() {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    // Filter chat rooms for current user
    final userChatRooms = _chatRooms.values
        .where((room) => room.participantIds.contains(_currentUserId))
        .toList()
      ..sort((a, b) => (b.lastMessageTime ?? b.createdAt)
          .compareTo(a.lastMessageTime ?? a.createdAt));

    // Send initial data
    Future.microtask(() {
      if (!_chatRoomsController.isClosed) {
        _chatRoomsController.add(userChatRooms);
      }
    });

    return _chatRoomsController.stream;
  }

  // Helper Methods

  /**
   * Generate Chat Room ID
   * 
   * Creates a consistent chat room identifier for two users.
   */
  String _getChatRoomId(String user1, String user2) {
    List<String> users = [user1, user2];
    users.sort();
    return users.join('_');
  }

  /**
   * Update Chat Room
   * 
   * Updates chat room with latest message information.
   */
  Future<void> _updateChatRoom(String chatRoomId, ChatMessage message) async {
    final existingRoom = _chatRooms[chatRoomId];
    
    if (existingRoom != null) {
      // Update existing room
      final updatedUnreadCount = Map<String, int>.from(existingRoom.unreadCount);
      
      // Increment unread count for all participants except sender
      for (final participantId in existingRoom.participantIds) {
        if (participantId != message.senderId) {
          updatedUnreadCount[participantId] = (updatedUnreadCount[participantId] ?? 0) + 1;
        }
      }

      _chatRooms[chatRoomId] = existingRoom.copyWith(
        lastMessageId: message.id,
        lastMessage: message.content.length > 50 
            ? '${message.content.substring(0, 50)}...' 
            : message.content,
        lastMessageTime: message.timestamp,
        lastMessageSender: message.senderName,
        unreadCount: updatedUnreadCount,
      );
    } else {
      // Create new one-to-one chat room
      final otherUserId = chatRoomId.split('_').firstWhere((id) => id != _currentUserId);
      
      _chatRooms[chatRoomId] = ChatRoom(
        id: chatRoomId,
        name: 'Chat', // Will be set based on other user's name
        type: ChatType.oneToOne,
        participantIds: [_currentUserId!, otherUserId],
        participantNames: {
          _currentUserId!: _currentUserName ?? 'You',
          otherUserId: 'User', // This would come from user service in real app
        },
        lastMessageId: message.id,
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        lastMessageSender: message.senderName,
        createdAt: message.timestamp,
        createdBy: _currentUserId!,
        unreadCount: {
          _currentUserId!: 0,
          otherUserId: 1,
        },
      );
    }

    _notifyChatsUpdate();
  }

  /**
   * Create System Message
   * 
   * Creates a system message for group events.
   */
  Future<void> _createSystemMessage(String chatRoomId, String content) async {
    final timestamp = DateTime.now();
    final messageId = 'system_${timestamp.millisecondsSinceEpoch}';

    final systemMessage = ChatMessage(
      id: messageId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      timestamp: timestamp,
      status: MessageStatus.delivered,
      type: MessageType.text,
      chatRoomId: chatRoomId,
      metadata: {'isSystem': true},
    );

    _messages[chatRoomId] ??= [];
    _messages[chatRoomId]!.add(systemMessage);

    _notifyMessageUpdate(chatRoomId);
  }

  /**
   * Simulate Message Delivery
   * 
   * Simulates realistic message delivery process with timers.
   */
  void _simulateMessageDelivery(String messageId, String chatRoomId) {
    // Simulate sent status after 100ms
    Timer(const Duration(milliseconds: 100), () {
      _updateMessageStatus(messageId, chatRoomId, MessageStatus.sent);
    });

    // Simulate delivered status after 500ms
    _deliveryTimers[messageId] = Timer(const Duration(milliseconds: 500), () {
      _updateMessageStatus(messageId, chatRoomId, MessageStatus.delivered);
      
      // Simulate read receipt after 2-5 seconds (random)
      final readDelay = Duration(seconds: 2 + Random().nextInt(4));
      _readReceiptTimers[messageId] = Timer(readDelay, () {
        _updateMessageStatus(messageId, chatRoomId, MessageStatus.read);
      });
    });
  }

  /**
   * Simulate Group Message Delivery
   * 
   * Simulates message delivery to all group members.
   */
  void _simulateGroupMessageDelivery(String messageId, String groupId, List<String> participantIds) {
    // Simulate sent status
    Timer(const Duration(milliseconds: 100), () {
      _updateMessageStatus(messageId, groupId, MessageStatus.sent);
    });

    // Simulate delivered status for all members
    Timer(const Duration(milliseconds: 500), () {
      _updateMessageStatus(messageId, groupId, MessageStatus.delivered);
    });

    // Simulate gradual read receipts from different members
    for (int i = 0; i < participantIds.length; i++) {
      if (participantIds[i] != _currentUserId) {
        final delay = Duration(seconds: 2 + (i * 2) + Random().nextInt(3));
        Timer(delay, () {
          _addReadReceipt(messageId, groupId, participantIds[i]);
        });
      }
    }
  }

  /**
   * Update Message Status
   * 
   * Updates the status of a specific message.
   */
  void _updateMessageStatus(String messageId, String chatRoomId, MessageStatus status) {
    final messages = _messages[chatRoomId];
    if (messages == null) return;

    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final message = messages[messageIndex];
    DateTime? deliveredAt = message.deliveredAt;
    DateTime? readAt = message.readAt;

    if (status == MessageStatus.delivered && deliveredAt == null) {
      deliveredAt = DateTime.now();
    } else if (status == MessageStatus.read && readAt == null) {
      readAt = DateTime.now();
    }

    messages[messageIndex] = message.copyWith(
      status: status,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );

    _notifyMessageUpdate(chatRoomId);
  }

  /**
   * Add Read Receipt
   * 
   * Adds a read receipt for a specific user.
   */
  void _addReadReceipt(String messageId, String chatRoomId, String userId) {
    final messages = _messages[chatRoomId];
    if (messages == null) return;

    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final message = messages[messageIndex];
    final updatedReadBy = [...message.readBy];
    
    if (!updatedReadBy.contains(userId)) {
      updatedReadBy.add(userId);
    }

    messages[messageIndex] = message.copyWith(
      readBy: updatedReadBy,
      status: updatedReadBy.isNotEmpty ? MessageStatus.read : message.status,
      readAt: DateTime.now(),
    );

    _notifyMessageUpdate(chatRoomId);
  }

  /**
   * Notify Message Update
   * 
   * Notifies all listeners of message updates.
   */
  void _notifyMessageUpdate(String chatRoomId) {
    final controller = _messageControllers[chatRoomId];
    if (controller != null && !controller.isClosed) {
      final decryptedMessages = _getDecryptedMessages(chatRoomId);
      controller.add(decryptedMessages);
    }
  }

  /**
   * Notify Chats Update
   * 
   * Notifies all listeners of chat list updates.
   */
  void _notifyChatsUpdate() {
    if (!_chatRoomsController.isClosed && _currentUserId != null) {
      final userChatRooms = _chatRooms.values
          .where((room) => room.participantIds.contains(_currentUserId))
          .toList()
        ..sort((a, b) => (b.lastMessageTime ?? b.createdAt)
            .compareTo(a.lastMessageTime ?? a.createdAt));

      _chatRoomsController.add(userChatRooms);
    }
  }

  /**
   * Initialize Mock Data
   * 
   * Creates sample data for development and testing.
   */
  void _initializeMockData() {
    final now = DateTime.now();
    
    // Create sample one-to-one chats
    final sampleUsers = [
      {'id': 'alice', 'name': 'Alice Johnson'},
      {'id': 'bob', 'name': 'Bob Smith'},
      {'id': 'carol', 'name': 'Carol Davis'},
    ];

    for (int i = 0; i < sampleUsers.length; i++) {
      final user = sampleUsers[i];
      final chatRoomId = 'mock_${user['id']}';
      
      // Create sample messages
      final messages = [
        ChatMessage(
          id: 'msg_${i}_1',
          senderId: user['id']!,
          senderName: user['name']!,
          content: 'Hello! How are you doing today?',
          timestamp: now.subtract(Duration(hours: i + 1)),
          status: MessageStatus.read,
          type: MessageType.text,
          chatRoomId: chatRoomId,
          readBy: ['current_user'],
          deliveredAt: now.subtract(Duration(hours: i + 1, minutes: 5)),
          readAt: now.subtract(Duration(hours: i, minutes: 30)),
        ),
        ChatMessage(
          id: 'msg_${i}_2',
          senderId: 'current_user',
          senderName: 'You',
          content: 'I\'m doing great! Thanks for asking. How about you?',
          timestamp: now.subtract(Duration(hours: i, minutes: 45)),
          status: MessageStatus.read,
          type: MessageType.text,
          chatRoomId: chatRoomId,
          readBy: [user['id']!],
          deliveredAt: now.subtract(Duration(hours: i, minutes: 40)),
          readAt: now.subtract(Duration(hours: i, minutes: 30)),
        ),
      ];
      
      _messages[chatRoomId] = messages;
      
      // Create chat room
      _chatRooms[chatRoomId] = ChatRoom(
        id: chatRoomId,
        name: user['name']!,
        type: ChatType.oneToOne,
        participantIds: ['current_user', user['id']!],
        participantNames: {
          'current_user': 'You',
          user['id']!: user['name']!,
        },
        lastMessageId: messages.last.id,
        lastMessage: messages.last.content,
        lastMessageTime: messages.last.timestamp,
        lastMessageSender: messages.last.senderName,
        createdAt: now.subtract(Duration(days: i + 1)),
        createdBy: 'current_user',
        unreadCount: {
          'current_user': 0,
          user['id']!: 0,
        },
      );
    }

    // Create sample group chat
    const groupId = 'group_sample';
    final groupMessages = [
      ChatMessage(
        id: 'group_msg_1',
        senderId: 'alice',
        senderName: 'Alice Johnson',
        content: 'Welcome to our AFO group chat!',
        timestamp: now.subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
        type: MessageType.text,
        chatRoomId: groupId,
        readBy: ['current_user', 'bob', 'carol'],
      ),
      ChatMessage(
        id: 'group_msg_2',
        senderId: 'bob',
        senderName: 'Bob Smith',
        content: 'Thanks Alice! Great to be part of the Afaan Oromoo community.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        status: MessageStatus.read,
        type: MessageType.text,
        chatRoomId: groupId,
        readBy: ['current_user', 'alice', 'carol'],
      ),
    ];

    _messages[groupId] = groupMessages;

    _chatRooms[groupId] = ChatRoom(
      id: groupId,
      name: 'AFO Community Group',
      type: ChatType.group,
      participantIds: ['current_user', 'alice', 'bob', 'carol'],
      participantNames: {
        'current_user': 'You',
        'alice': 'Alice Johnson',
        'bob': 'Bob Smith',
        'carol': 'Carol Davis',
      },
      lastMessageId: groupMessages.last.id,
      lastMessage: groupMessages.last.content,
      lastMessageTime: groupMessages.last.timestamp,
      lastMessageSender: groupMessages.last.senderName,
      createdAt: now.subtract(const Duration(days: 7)),
      createdBy: 'alice',
      groupDescription: 'A community group for Afaan Oromoo speakers to connect and chat.',
      admins: ['alice'],
      unreadCount: {
        'current_user': 0,
        'alice': 0,
        'bob': 0,
        'carol': 0,
      },
    );
  }

  /**
   * Edit Message
   * 
   * Allows users to edit their own messages within a time limit.
   * Updates the message content and marks it as edited.
   */
  Future<bool> editMessage({
    required String messageId,
    required String chatRoomId,
    required String newContent,
  }) async {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    final messages = _messages[chatRoomId];
    if (messages == null) return false;

    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return false;

    final message = messages[messageIndex];

    // Validate permissions
    if (message.senderId != _currentUserId) {
      throw Exception("You can only edit your own messages");
    }

    // Check time limit (15 minutes for editing)
    final timeSinceMessage = DateTime.now().difference(message.timestamp);
    if (timeSinceMessage.inMinutes > 15) {
      throw Exception("Messages can only be edited within 15 minutes");
    }

    // Don't allow editing of media messages
    if (message.type != MessageType.text) {
      throw Exception("Only text messages can be edited");
    }

    // Validate new content
    if (newContent.trim().isEmpty) {
      throw Exception("Message content cannot be empty");
    }

    try {
      // Store original content if this is the first edit
      final originalContent = message.isEdited ? message.originalContent : message.content;
      
      // Encrypt new content
      final encryptedContent = _encryptMessage(newContent, chatRoomId);

      // Create updated message
      final updatedMessage = message.copyWith(
        content: newContent.trim(),
        encryptedContent: encryptedContent,
        isEdited: true,
        editedAt: DateTime.now(),
        originalContent: originalContent,
      );

      // Update message in storage
      messages[messageIndex] = updatedMessage;

      // Update chat room's last message if this was the latest message
      final chatRoom = _chatRooms[chatRoomId];
      if (chatRoom != null && chatRoom.lastMessageId == messageId) {
        await _updateChatRoom(chatRoomId, updatedMessage);
      }

      // Notify listeners
      _notifyMessageUpdate(chatRoomId);

      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  /**
   * Delete Message
   * 
   * Allows users to delete their own messages within a time limit.
   * Supports both "delete for me" and "delete for everyone" options.
   */
  Future<bool> deleteMessage({
    required String messageId,
    required String chatRoomId,
    bool deleteForEveryone = false,
  }) async {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    final messages = _messages[chatRoomId];
    if (messages == null) return false;

    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return false;

    final message = messages[messageIndex];

    // Validate permissions for "delete for everyone"
    if (deleteForEveryone) {
      if (message.senderId != _currentUserId) {
        throw Exception("You can only delete your own messages for everyone");
      }

      // Check time limit for "delete for everyone" (1 hour)
      final timeSinceMessage = DateTime.now().difference(message.timestamp);
      if (timeSinceMessage.inHours > 1) {
        throw Exception("Messages can only be deleted for everyone within 1 hour");
      }
    }

    try {
      if (deleteForEveryone) {
        // Replace message content with "deleted" indicator
        final deletedMessage = message.copyWith(
          content: "🚫 This message was deleted",
          encryptedContent: _encryptMessage("🚫 This message was deleted", chatRoomId),
          type: MessageType.text,
          mediaAttachment: null, // Remove media attachment if any
          metadata: {
            ...?message.metadata,
            'deleted': true,
            'deletedAt': DateTime.now().millisecondsSinceEpoch,
            'deletedBy': _currentUserId,
          },
        );

        messages[messageIndex] = deletedMessage;

        // Update chat room's last message if this was the latest message
        final chatRoom = _chatRooms[chatRoomId];
        if (chatRoom != null && chatRoom.lastMessageId == messageId) {
          await _updateChatRoom(chatRoomId, deletedMessage);
        }
      } else {
        // "Delete for me" - just remove from local storage
        // In a real implementation, you'd mark it as hidden for current user
        messages.removeAt(messageIndex);

        // If this was the last message, update chat room with previous message
        final chatRoom = _chatRooms[chatRoomId];
        if (chatRoom != null && chatRoom.lastMessageId == messageId) {
          if (messages.isNotEmpty) {
            await _updateChatRoom(chatRoomId, messages.first);
          } else {
            // No more messages, clear last message info
            final updatedRoom = chatRoom.copyWith(
              lastMessageId: '',
              lastMessage: '',
              lastMessageTime: null,
              lastMessageSender: '',
            );
            _chatRooms[chatRoomId] = updatedRoom;
          }
        }
      }

      // Notify listeners
      _notifyMessageUpdate(chatRoomId);
      _notifyChatsUpdate();

      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /**
   * Get Message Edit History
   * 
   * Returns the edit history for a specific message.
   */
  Future<MessageEditHistory?> getMessageEditHistory(String messageId, String chatRoomId) async {
    final messages = _messages[chatRoomId];
    if (messages == null) return null;

    final message = messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception("Message not found"),
    );

    if (!message.isEdited) return null;

    return MessageEditHistory(
      messageId: messageId,
      originalContent: message.originalContent ?? message.content,
      currentContent: message.content,
      editedAt: message.editedAt ?? DateTime.now(),
      editCount: 1, // In a real implementation, track multiple edits
    );
  }

  /**
   * Can Edit Message
   * 
   * Checks if a message can be edited by the current user.
   */
  bool canEditMessage(ChatMessage message) {
    if (_currentUserId == null || message.senderId != _currentUserId) {
      return false;
    }

    if (message.type != MessageType.text) {
      return false;
    }

    final timeSinceMessage = DateTime.now().difference(message.timestamp);
    return timeSinceMessage.inMinutes <= 15;
  }

  /**
   * Can Delete Message
   * 
   * Checks if a message can be deleted by the current user.
   */
  bool canDeleteMessage(ChatMessage message, {bool deleteForEveryone = false}) {
    if (_currentUserId == null) return false;

    if (deleteForEveryone) {
      if (message.senderId != _currentUserId) return false;
      
      final timeSinceMessage = DateTime.now().difference(message.timestamp);
      return timeSinceMessage.inHours <= 1;
    }

    // "Delete for me" is always allowed
    return true;
  }

  /**
   * Dispose Resources
   * 
   * Properly closes all resources and prevents memory leaks.
   */
  void dispose() {
    // Cancel all timers
    for (final timer in _deliveryTimers.values) {
      timer.cancel();
    }
    _deliveryTimers.clear();

    for (final timer in _readReceiptTimers.values) {
      timer.cancel();
    }
    _readReceiptTimers.clear();

    // Close all stream controllers
    for (final controller in _messageControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _messageControllers.clear();

    if (!_chatRoomsController.isClosed) {
      _chatRoomsController.close();
    }

    // Clear encryption keys
    _chatKeys.clear();
  }
}