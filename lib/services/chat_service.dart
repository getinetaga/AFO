// ============================================================================
// AFO Chat Application - Chat Service
// ============================================================================
// This service provides chat messaging functionality for the
// AFO (Afaan Oromoo Chat Services) application as a mock replacement for
// Firebase Firestore. It simulates real-time messaging behavior including:
// - Message sending and receiving
// - Chat room management
// - Real-time message streaming
// - User presence tracking
// - Message persistence (mock)
//
// NOTE: This is a MOCK implementation that simulates real messaging functionality
// without requiring Firebase or external dependencies. For production,
// integrate with actual Firebase Firestore or similar real-time database.
// ============================================================================

// lib/services/chat_service.dart

import 'dart:async';

// ========================================================================
// Data Models - Chat Message Structure
// ========================================================================

/// Chat message model representing individual messages
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      message: json['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

// Mock chat room model
class ChatRoom {
  final String id;
  final List<String> users;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatRoom({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}

class ChatService {
  // Mock data storage
  static final Map<String, List<ChatMessage>> _messages = {};
  static final Map<String, ChatRoom> _chatRooms = {};
  
  // Stream controllers for real-time updates
  final Map<String, StreamController<List<ChatMessage>>> _messageControllers = {};
  final StreamController<List<ChatRoom>> _chatRoomsController = StreamController<List<ChatRoom>>.broadcast();

  // Mock current user ID (in real app, this would come from AuthService)
  String? _currentUserId;

  /// ChatService Constructor
  /// 
  /// Initializes the mock chat service with sample data for development
  /// and testing. In a production environment, this would connect to
  /// Firebase Firestore, WebSocket servers, or other real-time messaging APIs.
  ChatService() {
    _initializeMockData();
  }

  /// Set Current User ID
  /// 
  /// Sets the current authenticated user for the chat service. This method
  /// should be called after user authentication to enable message sending
  /// and proper message attribution.
  /// 
  /// @param userId - The authenticated user's unique identifier
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  /// Send Message
  /// 
  /// Sends a message from the current authenticated user to another user.
  /// Creates or updates the chat room between the users and notifies
  /// all listeners of the message update.
  /// 
  /// @param receiverId - The recipient user's unique identifier
  /// @param message - The message content to send
  /// @throws Exception if user is not authenticated
  Future<void> sendMessage({
    required String receiverId,
    required String message,
  }) async {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    final timestamp = DateTime.now();
    final senderId = _currentUserId!;
    final messageId = '${DateTime.now().millisecondsSinceEpoch}';

    // Generate a chat room ID based on users (sorted to ensure consistency)
    final chatRoomId = _getChatRoomId(senderId, receiverId);

    final chatMessage = ChatMessage(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // Add message to storage
    _messages[chatRoomId] ??= [];
    _messages[chatRoomId]!.add(chatMessage);

    // Update chat room
    _chatRooms[chatRoomId] = ChatRoom(
      id: chatRoomId,
      users: [senderId, receiverId],
      lastMessage: message,
      lastMessageTime: timestamp,
    );

    // Notify listeners
    _messageControllers[chatRoomId]?.add(_messages[chatRoomId]!.reversed.toList());
    _chatRoomsController.add(_chatRooms.values.toList()..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime)));

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Get Messages Stream
  /// 
  /// Returns a real-time stream of messages between the current user
  /// and another specified user. This stream automatically updates
  /// when new messages are sent or received.
  /// 
  /// @param userId - The other user's unique identifier
  /// @return Stream<List<ChatMessage>> - Real-time stream of messages
  /// @throws Exception if user is not authenticated
  Stream<List<ChatMessage>> getMessagesStream({
    required String userId,
  }) {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    final chatRoomId = _getChatRoomId(_currentUserId!, userId);

    // Create controller if it doesn't exist
    _messageControllers[chatRoomId] ??= StreamController<List<ChatMessage>>.broadcast();

    // Send initial data
    final messages = _messages[chatRoomId]?.reversed.toList() ?? [];
    Future.microtask(() {
      if (!_messageControllers[chatRoomId]!.isClosed) {
        _messageControllers[chatRoomId]!.add(messages);
      }
    });

    return _messageControllers[chatRoomId]!.stream;
  }

  /// Get User Chats
  /// 
  /// Returns a real-time stream of all chat rooms/conversations for the
  /// current authenticated user. Used to populate the chat list on the
  /// home screen with recent conversations.
  /// 
  /// @return Stream<List<ChatRoom>> - Real-time stream of user's chat rooms
  /// @throws Exception if user is not authenticated
  Stream<List<ChatRoom>> getUserChats() {
    if (_currentUserId == null) {
      throw Exception("User not authenticated");
    }

    // Filter chat rooms for current user
    final userChatRooms = _chatRooms.values
        .where((room) => room.users.contains(_currentUserId))
        .toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    // Send initial data
    Future.microtask(() {
      if (!_chatRoomsController.isClosed) {
        _chatRoomsController.add(userChatRooms);
      }
    });

    return _chatRoomsController.stream;
  }

  /// Generate Chat Room ID
  /// 
  /// Creates a consistent chat room identifier for two users.
  /// The ID is generated by sorting user IDs alphabetically
  /// to ensure the same room ID regardless of message direction.
  /// 
  /// @param user1 - First user's unique identifier
  /// @param user2 - Second user's unique identifier
  /// @return String - Consistent chat room identifier
  String _getChatRoomId(String user1, String user2) {
    List<String> users = [user1, user2];
    users.sort(); // Ensures same room ID regardless of sender/receiver order
    return users.join('_');
  }

  /// Initialize Mock Data
  /// 
  /// Creates sample chat rooms and messages for development and testing.
  /// In production, this would be replaced with actual data loading
  /// from Firebase Firestore, WebSocket connections, or REST APIs.
  void _initializeMockData() {
    // Add some sample chat rooms and messages for demo
    final now = DateTime.now();
    
    // Sample users
    const users = ['user1', 'user2', 'user3', 'alice', 'bob'];
    
    for (int i = 0; i < users.length - 1; i++) {
      final user1 = users[i];
      final user2 = users[i + 1];
      final chatRoomId = _getChatRoomId(user1, user2);
      
      // Create sample messages
      final messages = [
        ChatMessage(
          id: 'msg_${i}_1',
          senderId: user1,
          receiverId: user2,
          message: 'Hello there!',
          timestamp: now.subtract(Duration(minutes: i * 10 + 5)),
        ),
        ChatMessage(
          id: 'msg_${i}_2',
          senderId: user2,
          receiverId: user1,
          message: 'Hi! How are you?',
          timestamp: now.subtract(Duration(minutes: i * 10)),
        ),
      ];
      
      _messages[chatRoomId] = messages;
      
      // Create chat room
      _chatRooms[chatRoomId] = ChatRoom(
        id: chatRoomId,
        users: [user1, user2],
        lastMessage: messages.last.message,
        lastMessageTime: messages.last.timestamp,
      );
    }
  }

  /// Dispose Resources
  /// 
  /// Properly closes all stream controllers and cleans up resources
  /// to prevent memory leaks. Should be called when the service
  /// is no longer needed or when the app is being terminated.
  void dispose() {
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
    _chatRoomsController.close();
  }
}
