// ignore_for_file: dangling_library_doc_comments
// ignore_for_file: unused_field, curly_braces_in_flow_control_structures
/// AFO Chat Application - Advanced Chat Service
/// AFO: Afaan Oromoo Chat Services
///
/// This comprehensive chat service provides full messaging capabilities for the
/// AFO chat application, designed specifically for the Afaan Oromoo community.
/// Features include one-to-one and group messaging, encrypted messages, delivery
/// status tracking, edit/delete features, media attachments, and mock real-time
/// streams for development.

import 'dart:async';
import 'dart:math';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'notification_manager.dart';

/// Message delivery status enumeration
enum MessageStatus { sending, sent, delivered, read, failed }

/// Chat type enumeration
enum ChatType { oneToOne, group }

/// Message type enumeration
enum MessageType { text, image, video, audio, document, location, contact, sticker, gif, voiceNote }

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

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'originalContent': originalContent,
        'currentContent': currentContent,
        'editedAt': editedAt.millisecondsSinceEpoch,
        'editCount': editCount,
      };

  factory MessageEditHistory.fromJson(Map<String, dynamic> json) => MessageEditHistory(
        messageId: json['messageId'],
        originalContent: json['originalContent'],
        currentContent: json['currentContent'],
        editedAt: DateTime.fromMillisecondsSinceEpoch(json['editedAt']),
        editCount: json['editCount'] ?? 1,
      );
}

/// Media attachment model for file sharing
class MediaAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final MessageType mediaType;
  final String? thumbnailPath;
  final String? thumbnailUrl;
  final Duration? duration;
  final int? width;
  final int? height;
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

  Map<String, dynamic> toJson() => {
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

  factory MediaAttachment.fromJson(Map<String, dynamic> json) => MediaAttachment(
        id: json['id'],
        fileName: json['fileName'],
        filePath: json['filePath'],
        fileUrl: json['fileUrl'],
        fileSize: json['fileSize'],
        mimeType: json['mimeType'],
        mediaType: MessageType.values[json['mediaType'] ?? 0],
        thumbnailPath: json['thumbnailPath'],
        thumbnailUrl: json['thumbnailUrl'],
        duration: json['duration'] != null ? Duration(milliseconds: json['duration']) : null,
        width: json['width'],
        height: json['height'],
        metadata: json['metadata']?.cast<String, dynamic>(),
        uploadedAt: DateTime.fromMillisecondsSinceEpoch(json['uploadedAt']),
        isEncrypted: json['isEncrypted'] ?? true,
        encryptionKey: json['encryptionKey'],
      );

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get supportsThumbnail => mediaType == MessageType.image || mediaType == MessageType.video || mediaType == MessageType.gif;
}

/// Chat message model (rich)
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
  final MediaAttachment? mediaAttachment;
  final String? thumbnailPath;
  final Duration? mediaDuration;
  final double? mediaSize;
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

  Map<String, dynamic> toJson() => {
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
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
        deliveredAt: json['deliveredAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['deliveredAt']) : null,
        readAt: json['readAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['readAt']) : null,
        isEdited: json['isEdited'] ?? false,
        editedAt: json['editedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['editedAt']) : null,
        originalContent: json['originalContent'],
        mediaAttachment: json['mediaAttachment'] != null ? MediaAttachment.fromJson(json['mediaAttachment']) : null,
        thumbnailPath: json['thumbnailPath'],
        mediaDuration: json['mediaDuration'] != null ? Duration(milliseconds: json['mediaDuration']) : null,
        mediaSize: json['mediaSize']?.toDouble(),
        mediaMetadata: json['mediaMetadata']?.cast<String, String>(),
      );
}

/// Enhanced ChatRoom model
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
  String? _currentUserId;
  String? _currentUserName;

  final NotificationManager _notificationManager = NotificationManager();

  late final Encrypter _encrypter;
  late final IV _iv;
  final Map<String, Key> _chatKeys = {};

  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, ChatRoom> _chatRooms = {};
  final Map<String, StreamController<List<ChatMessage>>> _messageControllers = {};
  final StreamController<List<ChatRoom>> _chatRoomsController = StreamController<List<ChatRoom>>.broadcast();

  final Map<String, Timer> _deliveryTimers = {};
  final Map<String, Timer> _readReceiptTimers = {};

  static const int _pageSize = 50;
  final Map<String, int> _messagePage = {};

  ChatService() {
    _initializeEncryption();
    _initializeMockData();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationManager.initialize();
      debugPrint('ChatService: Notifications initialized');
    } catch (e) {
      debugPrint('ChatService: Failed to initialize notifications: $e');
    }
  }

  void _initializeEncryption() {
    final key = Key.fromSecureRandom(32);
    _iv = IV.fromSecureRandom(16);
    _encrypter = Encrypter(AES(key));
  }

  Key _generateChatKey(String chatRoomId) {
    if (!_chatKeys.containsKey(chatRoomId)) {
      _chatKeys[chatRoomId] = Key.fromSecureRandom(32);
    }
    return _chatKeys[chatRoomId]!;
  }

  String _encryptMessage(String message, String chatRoomId) {
    try {
      final key = _generateChatKey(chatRoomId);
      final encrypter = Encrypter(AES(key));
      final encrypted = encrypter.encrypt(message, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption error: $e');
      return message;
    }
  }

  String _decryptMessage(String encryptedMessage, String chatRoomId) {
    try {
      final key = _generateChatKey(chatRoomId);
      final encrypter = Encrypter(AES(key));
      final encrypted = Encrypted.fromBase64(encryptedMessage);
      return encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return encryptedMessage;
    }
  }

  void setCurrentUser(String userId, [String? userName]) {
    _currentUserId = userId;
    _currentUserName = userName ?? 'User';
  }

  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String message,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    MediaAttachment? mediaAttachment,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final timestamp = DateTime.now();
    final messageId = '${timestamp.millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final chatRoomId = _getChatRoomId(_currentUserId!, receiverId);

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

    _messages[chatRoomId] ??= [];
    _messages[chatRoomId]!.add(chatMessage);

    await _updateChatRoom(chatRoomId, chatMessage);
    _simulateMessageDelivery(messageId, chatRoomId);
    await _triggerMessageNotification(chatMessage, receiverId);
    _notifyMessageUpdate(chatRoomId);

    return chatMessage;
  }

  Future<ChatRoom> createGroupChat({
    required String groupName,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    String? groupDescription,
    String? groupImage,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now();

    final allParticipants = [_currentUserId!, ...participantIds];
    final allParticipantNames = {_currentUserId!: _currentUserName ?? 'User', ...participantNames};

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
      admins: [_currentUserId!],
      unreadCount: {for (var id in allParticipants) id: 0},
    );

    _chatRooms[groupId] = groupChat;
    await _createSystemMessage(groupId, '${_currentUserName ?? 'User'} created the group "$groupName"');
    _notifyChatsUpdate();
    return groupChat;
  }

  Future<ChatMessage> sendGroupMessage({
    required String groupId,
    required String message,
    MessageType type = MessageType.text,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    MediaAttachment? mediaAttachment,
  }) async {
    debugPrint('🟢 sendGroupMessage called - groupId: $groupId, message: $message');
    debugPrint('🟢 Current user: $_currentUserId');
    debugPrint('🟢 Available chatRooms: ${_chatRooms.keys}');
    
    if (_currentUserId == null) {
      debugPrint('🔴 User not authenticated');
      throw Exception('User not authenticated');
    }
    
    final chatRoom = _chatRooms[groupId];
    if (chatRoom == null) {
      debugPrint('🔴 Group chat not found for groupId: $groupId');
      throw Exception('Group chat not found');
    }
    
    debugPrint('🟡 Found chatRoom: ${chatRoom.name}, participants: ${chatRoom.participantIds}');
    
    if (!chatRoom.participantIds.contains(_currentUserId)) {
      debugPrint('🔴 User $_currentUserId not a member of group. Participants: ${chatRoom.participantIds}');
      throw Exception('You are not a member of this group');
    }

    final timestamp = DateTime.now();
    final messageId = '${timestamp.millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final encryptedContent = _encryptMessage(message, groupId);

    debugPrint('🟡 Creating ChatMessage with id: $messageId');
    
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

    debugPrint('🟡 Adding message to messages list');
    _messages[groupId] ??= [];
    _messages[groupId]!.add(chatMessage);
    
    debugPrint('🟡 Updating chat room');
    await _updateChatRoom(groupId, chatMessage);
    
    debugPrint('🟡 Simulating message delivery');
    _simulateGroupMessageDelivery(messageId, groupId, chatRoom.participantIds);
    
    debugPrint('🟡 Notifying message update');
    _notifyMessageUpdate(groupId);
    
    debugPrint('🟢 sendGroupMessage completed successfully');
    return chatMessage;
  }

  Future<void> markMessageAsRead(String messageId, String chatRoomId) async {
    if (_currentUserId == null) return;
    final messages = _messages[chatRoomId];
    if (messages == null) return;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final message = messages[messageIndex];
    if (message.senderId == _currentUserId) return;

    final updatedReadBy = [...message.readBy];
    if (!updatedReadBy.contains(_currentUserId!)) updatedReadBy.add(_currentUserId!);

    final updatedMessage = message.copyWith(status: MessageStatus.read, readBy: updatedReadBy, readAt: DateTime.now());
    messages[messageIndex] = updatedMessage;

    final chatRoom = _chatRooms[chatRoomId];
    if (chatRoom != null) {
      final updatedUnreadCount = Map<String, int>.from(chatRoom.unreadCount);
      updatedUnreadCount[_currentUserId!] = 0;
      _chatRooms[chatRoomId] = chatRoom.copyWith(unreadCount: updatedUnreadCount);
    }

    _notifyMessageUpdate(chatRoomId);
    _notifyChatsUpdate();
  }

  Stream<List<ChatMessage>> getMessagesStream({required String userId}) {
    if (_currentUserId == null) throw Exception('User not authenticated');
    final chatRoomId = _getChatRoomId(_currentUserId!, userId);
    return _getMessageStreamForChatRoom(chatRoomId);
  }

  Stream<List<ChatMessage>> getGroupMessagesStream(String groupId) {
    if (_currentUserId == null) throw Exception('User not authenticated');
    return _getMessageStreamForChatRoom(groupId);
  }

  Stream<List<ChatMessage>> _getMessageStreamForChatRoom(String chatRoomId) {
    _messageControllers[chatRoomId] ??= StreamController<List<ChatMessage>>.broadcast();
    final messages = _getDecryptedMessages(chatRoomId);
    Future.microtask(() {
      if (!_messageControllers[chatRoomId]!.isClosed) _messageControllers[chatRoomId]!.add(messages);
    });
    return _messageControllers[chatRoomId]!.stream;
  }

  List<ChatMessage> _getDecryptedMessages(String chatRoomId) {
    final messages = _messages[chatRoomId]?.reversed.toList() ?? [];
    return messages.map((message) {
      if (message.encryptedContent != null) {
        try {
          final decryptedContent = _decryptMessage(message.encryptedContent!, chatRoomId);
          return message.copyWith(content: decryptedContent);
        } catch (e) {
          debugPrint('Error decrypting message: $e');
          return message;
        }
      }
      return message;
    }).toList();
  }

  Future<List<ChatMessage>> getMessageHistory({required String chatRoomId, int page = 0, int limit = 50, String? searchQuery}) async {
    final messages = _messages[chatRoomId] ?? [];
    var filteredMessages = messages;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredMessages = messages.where((message) {
        final content = message.encryptedContent != null ? _decryptMessage(message.encryptedContent!, chatRoomId) : message.content;
        return content.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
    filteredMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, filteredMessages.length);
    if (startIndex >= filteredMessages.length) return [];
    final paginatedMessages = filteredMessages.sublist(startIndex, endIndex);
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

  Future<List<ChatMessage>> searchMessages({required String query, String? chatRoomId, int limit = 100}) async {
    final List<ChatMessage> results = [];
    final chatRoomsToSearch = chatRoomId != null ? [chatRoomId] : _messages.keys.toList();
    for (final roomId in chatRoomsToSearch) {
      final messages = _messages[roomId] ?? [];
      for (final message in messages) {
        final content = message.encryptedContent != null ? _decryptMessage(message.encryptedContent!, roomId) : message.content;
        if (content.toLowerCase().contains(query.toLowerCase())) {
          final decryptedMessage = message.encryptedContent != null ? message.copyWith(content: content) : message;
          results.add(decryptedMessage);
        }
        if (results.length >= limit) break;
      }
      if (results.length >= limit) break;
    }
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  Stream<List<ChatRoom>> getUserChats() {
    if (_currentUserId == null) throw Exception('User not authenticated');
    final userChatRooms = _chatRooms.values.where((room) => room.participantIds.contains(_currentUserId)).toList()..sort((a, b) => (b.lastMessageTime ?? b.createdAt).compareTo(a.lastMessageTime ?? a.createdAt));
    Future.microtask(() {
      if (!_chatRoomsController.isClosed) _chatRoomsController.add(userChatRooms);
    });
    return _chatRoomsController.stream;
  }

  String _getChatRoomId(String user1, String user2) {
    List<String> users = [user1, user2];
    users.sort();
    return users.join('_');
  }

  Future<void> _updateChatRoom(String chatRoomId, ChatMessage message) async {
    final existingRoom = _chatRooms[chatRoomId];
    if (existingRoom != null) {
      final updatedUnreadCount = Map<String, int>.from(existingRoom.unreadCount);
      for (final participantId in existingRoom.participantIds) {
        if (participantId != message.senderId) {
          updatedUnreadCount[participantId] = (updatedUnreadCount[participantId] ?? 0) + 1;
        }
      }
      _chatRooms[chatRoomId] = existingRoom.copyWith(lastMessageId: message.id, lastMessage: message.content.length > 50 ? '${message.content.substring(0, 50)}...' : message.content, lastMessageTime: message.timestamp, lastMessageSender: message.senderName, unreadCount: updatedUnreadCount);
    } else {
      final otherUserId = chatRoomId.split('_').firstWhere((id) => id != _currentUserId);
      _chatRooms[chatRoomId] = ChatRoom(id: chatRoomId, name: 'Chat', type: ChatType.oneToOne, participantIds: [_currentUserId!, otherUserId], participantNames: {_currentUserId!: _currentUserName ?? 'You', otherUserId: 'User'}, lastMessageId: message.id, lastMessage: message.content, lastMessageTime: message.timestamp, lastMessageSender: message.senderName, createdAt: message.timestamp, createdBy: _currentUserId!, unreadCount: {_currentUserId!: 0, otherUserId: 1});
    }
    _notifyChatsUpdate();
  }

  Future<void> _createSystemMessage(String chatRoomId, String content) async {
    final timestamp = DateTime.now();
    final messageId = 'system_${timestamp.millisecondsSinceEpoch}';
    final systemMessage = ChatMessage(id: messageId, senderId: 'system', senderName: 'System', content: content, timestamp: timestamp, status: MessageStatus.delivered, type: MessageType.text, chatRoomId: chatRoomId, metadata: {'isSystem': true});
    _messages[chatRoomId] ??= [];
    _messages[chatRoomId]!.add(systemMessage);
    _notifyMessageUpdate(chatRoomId);
  }

  void _simulateMessageDelivery(String messageId, String chatRoomId) {
    Timer(const Duration(milliseconds: 100), () {
      _updateMessageStatus(messageId, chatRoomId, MessageStatus.sent);
    });
    _deliveryTimers[messageId] = Timer(const Duration(milliseconds: 500), () {
      _updateMessageStatus(messageId, chatRoomId, MessageStatus.delivered);
      final readDelay = Duration(seconds: 2 + Random().nextInt(4));
      _readReceiptTimers[messageId] = Timer(readDelay, () {
        _updateMessageStatus(messageId, chatRoomId, MessageStatus.read);
      });
    });
  }

  void _simulateGroupMessageDelivery(String messageId, String groupId, List<String> participantIds) {
    Timer(const Duration(milliseconds: 100), () {
      _updateMessageStatus(messageId, groupId, MessageStatus.sent);
    });
    Timer(const Duration(milliseconds: 500), () {
      _updateMessageStatus(messageId, groupId, MessageStatus.delivered);
    });
    for (int i = 0; i < participantIds.length; i++) {
      if (participantIds[i] != _currentUserId) {
        final delay = Duration(seconds: 2 + (i * 2) + Random().nextInt(3));
        Timer(delay, () {
          _addReadReceipt(messageId, groupId, participantIds[i]);
        });
      }
    }
  }

  void _updateMessageStatus(String messageId, String chatRoomId, MessageStatus status) {
    final messages = _messages[chatRoomId];
    if (messages == null) return;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final message = messages[messageIndex];
    DateTime? deliveredAt = message.deliveredAt;
    DateTime? readAt = message.readAt;
    if (status == MessageStatus.delivered && deliveredAt == null) deliveredAt = DateTime.now();
    else if (status == MessageStatus.read && readAt == null) readAt = DateTime.now();
    messages[messageIndex] = message.copyWith(status: status, deliveredAt: deliveredAt, readAt: readAt);
    _notifyMessageUpdate(chatRoomId);
  }

  void _addReadReceipt(String messageId, String chatRoomId, String userId) {
    final messages = _messages[chatRoomId];
    if (messages == null) return;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final message = messages[messageIndex];
    final updatedReadBy = [...message.readBy];
    if (!updatedReadBy.contains(userId)) updatedReadBy.add(userId);
    messages[messageIndex] = message.copyWith(readBy: updatedReadBy, status: updatedReadBy.isNotEmpty ? MessageStatus.read : message.status, readAt: DateTime.now());
    _notifyMessageUpdate(chatRoomId);
  }

  void _notifyMessageUpdate(String chatRoomId) {
    final controller = _messageControllers[chatRoomId];
    if (controller != null && !controller.isClosed) controller.add(_getDecryptedMessages(chatRoomId));
  }

  void _notifyChatsUpdate() {
    if (!_chatRoomsController.isClosed && _currentUserId != null) {
      final userChatRooms = _chatRooms.values.where((room) => room.participantIds.contains(_currentUserId)).toList()..sort((a, b) => (b.lastMessageTime ?? b.createdAt).compareTo(a.lastMessageTime ?? a.createdAt));
      _chatRoomsController.add(userChatRooms);
    }
  }

  void _initializeMockData() {
    final now = DateTime.now();
    final sampleUsers = [
      {'id': 'alice', 'name': 'Alice Johnson'},
      {'id': 'bob', 'name': 'Bob Smith'},
      {'id': 'carol', 'name': 'Carol Davis'},
    ];
    for (int i = 0; i < sampleUsers.length; i++) {
      final user = sampleUsers[i];
      final chatRoomId = 'mock_${user['id']}';
      final messages = [
        ChatMessage(id: 'msg_${i}_1', senderId: user['id']!, senderName: user['name']!, content: 'Hello! How are you doing today?', timestamp: now.subtract(Duration(hours: i + 1)), status: MessageStatus.read, type: MessageType.text, chatRoomId: chatRoomId, readBy: ['current_user'], deliveredAt: now.subtract(Duration(hours: i + 1, minutes: 5)), readAt: now.subtract(Duration(hours: i, minutes: 30))),
        ChatMessage(id: 'msg_${i}_2', senderId: 'current_user', senderName: 'You', content: 'I\'m doing great! Thanks for asking. How about you?', timestamp: now.subtract(Duration(hours: i, minutes: 45)), status: MessageStatus.read, type: MessageType.text, chatRoomId: chatRoomId, readBy: [user['id']!], deliveredAt: now.subtract(Duration(hours: i, minutes: 40)), readAt: now.subtract(Duration(hours: i, minutes: 30))),
      ];
      _messages[chatRoomId] = messages;
      _chatRooms[chatRoomId] = ChatRoom(id: chatRoomId, name: user['name']!, type: ChatType.oneToOne, participantIds: ['current_user', user['id']!], participantNames: {'current_user': 'You', user['id']!: user['name']!}, lastMessageId: messages.last.id, lastMessage: messages.last.content, lastMessageTime: messages.last.timestamp, lastMessageSender: messages.last.senderName, createdAt: now.subtract(Duration(days: i + 1)), createdBy: 'current_user', unreadCount: {'current_user': 0, user['id']!: 0});
    }
    const groupId = 'group_sample';
    final groupMessages = [
      ChatMessage(id: 'group_msg_1', senderId: 'alice', senderName: 'Alice Johnson', content: 'Welcome to our AFO group chat!', timestamp: now.subtract(const Duration(hours: 2)), status: MessageStatus.read, type: MessageType.text, chatRoomId: groupId, readBy: ['current_user', 'bob', 'carol']),
      ChatMessage(id: 'group_msg_2', senderId: 'bob', senderName: 'Bob Smith', content: 'Thanks Alice! Great to be part of the Afaan Oromoo community.', timestamp: now.subtract(const Duration(hours: 1, minutes: 30)), status: MessageStatus.read, type: MessageType.text, chatRoomId: groupId, readBy: ['current_user', 'alice', 'carol']),
    ];
    _messages[groupId] = groupMessages;
    _chatRooms[groupId] = ChatRoom(id: groupId, name: 'AFO Community Group', type: ChatType.group, participantIds: ['current_user', 'alice', 'bob', 'carol'], participantNames: {'current_user': 'You', 'alice': 'Alice Johnson', 'bob': 'Bob Smith', 'carol': 'Carol Davis'}, lastMessageId: groupMessages.last.id, lastMessage: groupMessages.last.content, lastMessageTime: groupMessages.last.timestamp, lastMessageSender: groupMessages.last.senderName, createdAt: now.subtract(const Duration(days: 7)), createdBy: 'alice', groupDescription: 'A community group for Afaan Oromoo speakers to connect and chat.', admins: ['alice'], unreadCount: {'current_user': 0, 'alice': 0, 'bob': 0, 'carol': 0});
  }

  Future<bool> editMessage({required String messageId, required String chatRoomId, required String newContent}) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    final messages = _messages[chatRoomId];
    if (messages == null) return false;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return false;
    final message = messages[messageIndex];
    if (message.senderId != _currentUserId) throw Exception('You can only edit your own messages');
    final timeSinceMessage = DateTime.now().difference(message.timestamp);
    if (timeSinceMessage.inMinutes > 15) throw Exception('Messages can only be edited within 15 minutes');
    if (message.type != MessageType.text) throw Exception('Only text messages can be edited');
    if (newContent.trim().isEmpty) throw Exception('Message content cannot be empty');
    try {
      final originalContent = message.isEdited ? message.originalContent : message.content;
      final encryptedContent = _encryptMessage(newContent, chatRoomId);
      final updatedMessage = message.copyWith(content: newContent.trim(), encryptedContent: encryptedContent, isEdited: true, editedAt: DateTime.now(), originalContent: originalContent);
      messages[messageIndex] = updatedMessage;
      final chatRoom = _chatRooms[chatRoomId];
      if (chatRoom != null && chatRoom.lastMessageId == messageId) await _updateChatRoom(chatRoomId, updatedMessage);
      _notifyMessageUpdate(chatRoomId);
      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  Future<bool> deleteMessage({required String messageId, required String chatRoomId, bool deleteForEveryone = false}) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    final messages = _messages[chatRoomId];
    if (messages == null) return false;
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return false;
    final message = messages[messageIndex];
    if (deleteForEveryone) {
      if (message.senderId != _currentUserId) throw Exception('You can only delete your own messages for everyone');
      final timeSinceMessage = DateTime.now().difference(message.timestamp);
      if (timeSinceMessage.inHours > 1) throw Exception('Messages can only be deleted for everyone within 1 hour');
    }
    try {
      if (deleteForEveryone) {
        final deletedMessage = message.copyWith(content: '🚫 This message was deleted', encryptedContent: _encryptMessage('🚫 This message was deleted', chatRoomId), type: MessageType.text, mediaAttachment: null, metadata: {...?message.metadata, 'deleted': true, 'deletedAt': DateTime.now().millisecondsSinceEpoch, 'deletedBy': _currentUserId});
        messages[messageIndex] = deletedMessage;
        final chatRoom = _chatRooms[chatRoomId];
        if (chatRoom != null && chatRoom.lastMessageId == messageId) await _updateChatRoom(chatRoomId, deletedMessage);
      } else {
        messages.removeAt(messageIndex);
        final chatRoom = _chatRooms[chatRoomId];
        if (chatRoom != null && chatRoom.lastMessageId == messageId) {
          if (messages.isNotEmpty) await _updateChatRoom(chatRoomId, messages.first);
          else {
            final updatedRoom = chatRoom.copyWith(lastMessageId: '', lastMessage: '', lastMessageTime: null, lastMessageSender: '');
            _chatRooms[chatRoomId] = updatedRoom;
          }
        }
      }
      _notifyMessageUpdate(chatRoomId);
      _notifyChatsUpdate();
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  Future<MessageEditHistory?> getMessageEditHistory(String messageId, String chatRoomId) async {
    final messages = _messages[chatRoomId];
    if (messages == null) return null;
    final message = messages.firstWhere((m) => m.id == messageId, orElse: () => throw Exception('Message not found'));
    if (!message.isEdited) return null;
    return MessageEditHistory(messageId: messageId, originalContent: message.originalContent ?? message.content, currentContent: message.content, editedAt: message.editedAt ?? DateTime.now(), editCount: 1);
  }

  bool canEditMessage(ChatMessage message) {
    if (_currentUserId == null || message.senderId != _currentUserId) return false;
    if (message.type != MessageType.text) return false;
    final timeSinceMessage = DateTime.now().difference(message.timestamp);
    return timeSinceMessage.inMinutes <= 15;
  }

  bool canDeleteMessage(ChatMessage message, {bool deleteForEveryone = false}) {
    if (_currentUserId == null) return false;
    if (deleteForEveryone) {
      if (message.senderId != _currentUserId) return false;
      final timeSinceMessage = DateTime.now().difference(message.timestamp);
      return timeSinceMessage.inHours <= 1;
    }
    return true;
  }

  /// Gets the message that another message is replying to.
  /// 
  /// Returns the original message if the [message] has a [replyToMessageId],
  /// null otherwise. This is used to display reply context in the UI.
  /// 
  /// [message] The message that might be a reply
  /// Returns the original message being replied to, or null
  ChatMessage? getRepliedToMessage(ChatMessage message) {
    if (message.replyToMessageId == null) return null;
    
    final messages = _messages[message.chatRoomId];
    if (messages == null) return null;
    
    try {
      return messages.firstWhere(
        (m) => m.id == message.replyToMessageId,
      );
    } catch (e) {
      // Message not found
      return null;
    }
  }

  /// Gets a message by its ID from the specified chat room.
  /// 
  /// This is useful for getting the original message when displaying
  /// reply context or when performing operations on specific messages.
  /// 
  /// [messageId] The unique identifier of the message
  /// [chatRoomId] The chat room containing the message
  /// Returns the message if found, null otherwise
  ChatMessage? getMessageById(String messageId, String chatRoomId) {
    final messages = _messages[chatRoomId];
    if (messages == null) return null;
    
    try {
      return messages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      return null;
    }
  }

  /// Sends a reply message to another message.
  /// 
  /// This is a convenience method that wraps [sendMessage] or [sendGroupMessage]
  /// with the reply functionality. It automatically sets the [replyToMessageId]
  /// parameter.
  /// 
  /// [originalMessage] The message being replied to
  /// [replyContent] The content of the reply
  /// [type] The type of message (default: text)
  /// [mediaAttachment] Optional media attachment for the reply
  /// Returns the created reply message
  Future<ChatMessage> sendReplyMessage({
    required ChatMessage originalMessage,
    required String replyContent,
    MessageType type = MessageType.text,
    MediaAttachment? mediaAttachment,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    // Determine if this is a group chat or direct chat
    final chatRoom = _chatRooms[originalMessage.chatRoomId];
    final isGroupChat = chatRoom?.type == ChatType.group;

    if (isGroupChat) {
      return await sendGroupMessage(
        groupId: originalMessage.chatRoomId,
        message: replyContent,
        type: type,
        replyToMessageId: originalMessage.id,
        mediaAttachment: mediaAttachment,
      );
    } else {
      // For direct messages, we need to determine the receiver
      // It's the other participant in the chat room
      final otherParticipantId = originalMessage.senderId == _currentUserId 
          ? _extractReceiverFromChatRoomId(originalMessage.chatRoomId, _currentUserId!)
          : originalMessage.senderId;

      return await sendMessage(
        receiverId: otherParticipantId,
        message: replyContent,
        type: type,
        replyToMessageId: originalMessage.id,
        mediaAttachment: mediaAttachment,
      );
    }
  }

  /// Extracts the receiver ID from a chat room ID for direct messages.
  /// 
  /// Chat room IDs for direct messages are typically formatted as
  /// "user1_user2" where the IDs are sorted. This method extracts
  /// the other participant's ID.
  /// 
  /// [chatRoomId] The chat room identifier
  /// [currentUserId] The current user's identifier
  /// Returns the other participant's ID
  String _extractReceiverFromChatRoomId(String chatRoomId, String currentUserId) {
    final parts = chatRoomId.split('_');
    if (parts.length == 2) {
      return parts[0] == currentUserId ? parts[1] : parts[0];
    }
    throw Exception('Invalid chat room ID format for direct message');
  }

  void dispose() {
    for (final timer in _deliveryTimers.values) timer.cancel();
    _deliveryTimers.clear();
    for (final timer in _readReceiptTimers.values) timer.cancel();
    _readReceiptTimers.clear();
    for (final controller in _messageControllers.values) if (!controller.isClosed) controller.close();
    _messageControllers.clear();
    if (!_chatRoomsController.isClosed) _chatRoomsController.close();
    _chatKeys.clear();
  }

  Future<void> _triggerMessageNotification(ChatMessage message, String receiverId) async {
    if (message.senderId == _currentUserId) return;
    try {
      final chatRoom = _chatRooms[message.chatRoomId];
      final isGroup = chatRoom?.type == ChatType.group;
      if (message.type == MessageType.text) {
        await _notificationManager.showMessageNotification(senderName: message.senderName, senderId: message.senderId, messageContent: message.content, chatRoomId: message.chatRoomId, messageId: message.id, isGroup: isGroup, groupName: isGroup ? chatRoom?.name : null);
      } else {
        final mediaType = message.type.toString().split('.').last;
        await _notificationManager.showMediaNotification(senderName: message.senderName, senderId: message.senderId, mediaType: mediaType, chatRoomId: message.chatRoomId, messageId: message.id, isGroup: isGroup, groupName: isGroup ? chatRoom?.name : null);
      }
    } catch (e) {
      debugPrint('Failed to trigger message notification: $e');
    }
  }

  Future<void> triggerCallNotification({required String callerName, required String callerId, required String callId, required bool isVideoCall, String? callerAvatar}) async {
    try {
      await _notificationManager.showCallNotification(callerName: callerName, callerId: callerId, callId: callId, isVideoCall: isVideoCall, callerAvatar: callerAvatar);
    } catch (e) {
      debugPrint('Failed to trigger call notification: $e');
    }
  }

  // ... group activity notification helper removed (unused)

  Future<void> clearNotificationsForChat(String chatRoomId) async {
    try {
      await _notificationManager.clearNotificationsForChat(chatRoomId);
    } catch (e) {
      debugPrint('Failed to clear notifications for chat: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _notificationManager.clearAllNotifications();
    } catch (e) {
      debugPrint('Failed to clear all notifications: $e');
    }
  }

  Future<void> refreshNotificationSettings() async {
    try {
      await _notificationManager.refreshSettings();
    } catch (e) {
      debugPrint('Failed to refresh notification settings: $e');
    }
  }
}
