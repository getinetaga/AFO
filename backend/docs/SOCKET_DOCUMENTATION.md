# Socket.IO Handler Documentation

## Overview
The `socketHandler.ts` file implements real-time communication for the AFO chat application using Socket.IO. It manages user connections, authentication, messaging, presence tracking, and WebRTC signaling.

## Class: SocketHandler

### Purpose
Orchestrates all real-time features including:
- User authentication and session management
- Real-time messaging with delivery confirmation
- User presence and typing indicators
- WebRTC call signaling
- Chat room management
- Message reactions and editing

### Architecture

```typescript
export class SocketHandler {
  private io: SocketIOServer;                    // Socket.IO server instance
  private connectedUsers: Map<string, string[]>; // userId -> [socketId1, socketId2, ...]
  
  constructor(io: SocketIOServer) {
    this.io = io;
    this.setupMiddleware();
    this.setupEventHandlers();
  }
}
```

## Authentication Middleware

### Token Verification
```typescript
this.io.use(async (socket: AuthenticatedSocket, next) => {
  try {
    const token = socket.handshake.auth.token || 
                  socket.handshake.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return next(new Error('Authentication token required'));
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JWTPayload;
    const user = await User.findById(decoded.userId);
    
    if (!user || !user.isActive) {
      return next(new Error('Invalid user or inactive account'));
    }
    
    socket.userId = user._id.toString();
    socket.user = user;
    next();
  } catch (error) {
    next(new Error('Authentication failed'));
  }
});
```

**Features**:
- JWT token validation from header or handshake
- User existence and status verification
- Socket context enrichment with user data
- Error handling for invalid tokens

### Extended Socket Interface
```typescript
interface AuthenticatedSocket extends Socket {
  userId?: string;
  user?: any;
}
```

## Connection Management

### User Connection Tracking
```typescript
private handleConnection(socket: AuthenticatedSocket): void {
  const userId = socket.userId!;
  
  // Track multiple connections per user (multi-device support)
  if (!this.connectedUsers.has(userId)) {
    this.connectedUsers.set(userId, []);
  }
  this.connectedUsers.get(userId)!.push(socket.id);
  
  // Update user online status
  this.updateUserOnlineStatus(userId, true);
  
  // Notify other users
  socket.broadcast.emit('user_online', { userId });
}
```

**Features**:
- Multi-device connection support
- Online status management
- Presence broadcasting
- Connection state tracking

### Disconnection Handling
```typescript
private handleDisconnection(socket: AuthenticatedSocket): void {
  const userId = socket.userId;
  if (!userId) return;
  
  const userSockets = this.connectedUsers.get(userId);
  if (userSockets) {
    const index = userSockets.indexOf(socket.id);
    if (index > -1) {
      userSockets.splice(index, 1);
    }
    
    // If no more connections, mark user offline
    if (userSockets.length === 0) {
      this.connectedUsers.delete(userId);
      this.updateUserOnlineStatus(userId, false);
      socket.broadcast.emit('user_offline', { userId });
    }
  }
}
```

**Features**:
- Connection cleanup
- Multi-device session management
- Offline status updates
- Presence notification

## Chat Room Management

### Joining Chat Rooms
```typescript
socket.on('join_chat', async (data: { chatId: string }) => {
  try {
    const { chatId } = data;
    
    // Verify chat membership
    const chat = await Chat.findById(chatId);
    if (!chat) {
      return socket.emit('error', { message: 'Chat not found' });
    }
    
    const isParticipant = chat.participants.some(
      p => p.user.toString() === socket.userId && p.isActive
    );
    
    if (!isParticipant) {
      return socket.emit('error', { message: 'Not authorized to join this chat' });
    }
    
    // Join Socket.IO room
    await socket.join(chatId);
    
    // Notify user of successful join
    socket.emit('chat_joined', { chatId });
    
    // Notify other participants
    socket.to(chatId).emit('user_joined_chat', {
      chatId,
      userId: socket.userId,
      username: socket.user.username
    });
    
  } catch (error) {
    socket.emit('error', { message: 'Failed to join chat' });
  }
});
```

**Features**:
- Chat membership verification
- Room-based messaging setup
- Join confirmation
- Participant notification

### Leaving Chat Rooms
```typescript
socket.on('leave_chat', async (data: { chatId: string }) => {
  const { chatId } = data;
  
  await socket.leave(chatId);
  
  socket.emit('chat_left', { chatId });
  socket.to(chatId).emit('user_left_chat', {
    chatId,
    userId: socket.userId,
    username: socket.user.username
  });
});
```

## Real-time Messaging

### Message Sending
```typescript
socket.on('send_message', async (data: MessageData) => {
  try {
    const { chatId, content, type = 'text', replyTo, tempId } = data;
    
    // Validate chat membership
    const chat = await Chat.findById(chatId);
    if (!chat || !this.isParticipant(chat, socket.userId!)) {
      return socket.emit('error', { message: 'Not authorized to send messages' });
    }
    
    // Create message
    const message = new Message({
      chat: chatId,
      sender: socket.userId,
      content,
      type,
      replyTo: replyTo ? new Types.ObjectId(replyTo) : undefined,
      tempId
    });
    
    await message.save();
    await message.populate('sender', 'username displayName avatar');
    
    // Update chat last activity
    await Chat.findByIdAndUpdate(chatId, {
      lastMessage: message._id,
      lastActivity: new Date()
    });
    
    // Confirm to sender
    socket.emit('message_sent', {
      tempId,
      message: message.toObject()
    });
    
    // Broadcast to chat participants
    socket.to(chatId).emit('new_message', {
      chatId,
      message: message.toObject()
    });
    
  } catch (error) {
    socket.emit('error', { 
      message: 'Failed to send message',
      tempId: data.tempId 
    });
  }
});
```

**Features**:
- Authorization verification
- Message validation and creation
- Database persistence
- Sender confirmation with tempId mapping
- Real-time broadcasting to participants
- Error handling with tempId tracking

### Message Editing
```typescript
socket.on('edit_message', async (data: EditMessageData) => {
  try {
    const { messageId, newContent, chatId } = data;
    
    const message = await Message.findById(messageId);
    if (!message) {
      return socket.emit('error', { message: 'Message not found' });
    }
    
    // Verify sender permission
    if (message.sender.toString() !== socket.userId) {
      return socket.emit('error', { message: 'Not authorized to edit this message' });
    }
    
    // Check edit time limit (24 hours)
    const editTimeLimit = 24 * 60 * 60 * 1000;
    if (Date.now() - message.createdAt.getTime() > editTimeLimit) {
      return socket.emit('error', { message: 'Edit time limit exceeded' });
    }
    
    // Store edit history
    message.editHistory.push({
      content: message.content,
      editedAt: new Date()
    });
    
    message.content = newContent;
    message.isEdited = true;
    await message.save();
    
    // Broadcast edit
    this.io.to(chatId).emit('message_edited', {
      messageId,
      newContent,
      editedAt: new Date(),
      chatId
    });
    
  } catch (error) {
    socket.emit('error', { message: 'Failed to edit message' });
  }
});
```

**Features**:
- Sender authorization
- Time-based edit restrictions
- Edit history preservation
- Real-time edit broadcasting
- Error handling

### Message Reactions
```typescript
socket.on('add_reaction', async (data: ReactionData) => {
  try {
    const { messageId, emoji, chatId } = data;
    
    const message = await Message.findById(messageId);
    if (!message) {
      return socket.emit('error', { message: 'Message not found' });
    }
    
    const userId = new Types.ObjectId(socket.userId!);
    const existingReaction = message.reactions.find(
      r => r.user.equals(userId) && r.emoji === emoji
    );
    
    if (existingReaction) {
      // Remove existing reaction
      message.reactions = message.reactions.filter(
        r => !(r.user.equals(userId) && r.emoji === emoji)
      );
    } else {
      // Add new reaction
      message.reactions.push({ user: userId, emoji });
    }
    
    await message.save();
    
    // Broadcast reaction update
    this.io.to(chatId).emit('reaction_added', {
      messageId,
      userId: socket.userId,
      emoji,
      action: existingReaction ? 'removed' : 'added',
      chatId
    });
    
  } catch (error) {
    socket.emit('error', { message: 'Failed to add reaction' });
  }
});
```

**Features**:
- Toggle reaction functionality
- Duplicate reaction prevention
- Real-time reaction broadcasting
- User-specific reaction tracking

## Typing Indicators

### Typing Start/Stop
```typescript
socket.on('typing_start', (data: { chatId: string }) => {
  const { chatId } = data;
  
  socket.to(chatId).emit('user_typing', {
    userId: socket.userId,
    username: socket.user.username,
    chatId,
    isTyping: true
  });
});

socket.on('typing_stop', (data: { chatId: string }) => {
  const { chatId } = data;
  
  socket.to(chatId).emit('user_typing', {
    userId: socket.userId,
    username: socket.user.username,
    chatId,
    isTyping: false
  });
});
```

**Features**:
- Real-time typing status
- Chat-specific indicators
- User identification
- Start/stop event handling

## User Presence Management

### Online Users Query
```typescript
socket.on('get_online_users', () => {
  const onlineUserIds = Array.from(this.connectedUsers.keys());
  socket.emit('online_users_list', { userIds: onlineUserIds });
});
```

### Status Updates
```typescript
private async updateUserOnlineStatus(userId: string, isOnline: boolean): Promise<void> {
  try {
    await User.findByIdAndUpdate(userId, {
      'status.isOnline': isOnline,
      'status.lastSeen': new Date()
    });
  } catch (error) {
    console.error('Failed to update user online status:', error);
  }
}
```

**Features**:
- Real-time presence tracking
- Database status synchronization
- Last seen timestamps
- Multi-device status management

## WebRTC Call Signaling

### Call Offer/Answer Exchange
```typescript
socket.on('webrtc_offer', (data: WebRTCSignalData) => {
  const { targetUserId, offer, chatId } = data;
  
  const targetSockets = this.connectedUsers.get(targetUserId);
  if (targetSockets) {
    targetSockets.forEach(socketId => {
      this.io.to(socketId).emit('webrtc_offer', {
        fromUserId: socket.userId,
        offer,
        chatId
      });
    });
  }
});

socket.on('webrtc_answer', (data: WebRTCSignalData) => {
  const { targetUserId, answer, chatId } = data;
  
  const targetSockets = this.connectedUsers.get(targetUserId);
  if (targetSockets) {
    targetSockets.forEach(socketId => {
      this.io.to(socketId).emit('webrtc_answer', {
        fromUserId: socket.userId,
        answer,
        chatId
      });
    });
  }
});
```

### ICE Candidate Exchange
```typescript
socket.on('webrtc_ice_candidate', (data: ICECandidateData) => {
  const { targetUserId, candidate, chatId } = data;
  
  const targetSockets = this.connectedUsers.get(targetUserId);
  if (targetSockets) {
    targetSockets.forEach(socketId => {
      this.io.to(socketId).emit('webrtc_ice_candidate', {
        fromUserId: socket.userId,
        candidate,
        chatId
      });
    });
  }
});
```

### Call Termination
```typescript
socket.on('webrtc_hang_up', (data: { targetUserId: string, chatId: string }) => {
  const { targetUserId, chatId } = data;
  
  const targetSockets = this.connectedUsers.get(targetUserId);
  if (targetSockets) {
    targetSockets.forEach(socketId => {
      this.io.to(socketId).emit('webrtc_hang_up', {
        fromUserId: socket.userId,
        chatId
      });
    });
  }
});
```

**Features**:
- Peer-to-peer call setup
- Multi-device call handling
- ICE candidate relay
- Call state management
- Graceful call termination

## Error Handling

### Socket Error Management
```typescript
socket.on('error', (error: Error) => {
  console.error('Socket error:', error);
  socket.emit('error', { 
    message: 'An error occurred',
    code: 'SOCKET_ERROR'
  });
});
```

### Database Error Handling
```typescript
try {
  // Database operations
} catch (error) {
  console.error('Database error in socket handler:', error);
  socket.emit('error', { 
    message: 'Database operation failed',
    code: 'DATABASE_ERROR'
  });
}
```

**Features**:
- Centralized error logging
- Client error notification
- Error code classification
- Graceful degradation

## Security Considerations

### Authorization Checks
- Chat membership verification
- Message sender validation
- Edit permission enforcement
- Reaction authorization

### Input Validation
- Message content sanitization
- Chat ID validation
- User ID verification
- File type restrictions

### Rate Limiting
- Message frequency limits
- Reaction rate limits
- Typing indicator throttling
- Connection attempt limits

## Performance Optimizations

### Efficient Broadcasting
- Room-based message delivery
- Targeted user notifications
- Connection pooling
- Event debouncing

### Memory Management
- Connection cleanup on disconnect
- Efficient data structures
- Garbage collection optimization
- Resource pooling

### Database Optimization
- Efficient queries
- Index utilization
- Connection pooling
- Query result caching

This documentation provides comprehensive coverage of the Socket.IO handler implementation, showcasing the real-time communication capabilities of the AFO chat application.