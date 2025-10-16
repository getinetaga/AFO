import jwt from 'jsonwebtoken';
import { Types } from 'mongoose';
import { Socket, Server as SocketIOServer } from 'socket.io';
import { Chat } from '../models/Chat';
import { Message } from '../models/Message';
import { User } from '../models/User';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  user?: any;
}

export class SocketHandler {
  private io: SocketIOServer;
  private connectedUsers: Map<string, string[]> = new Map(); // userId -> [socketId]

  constructor(io: SocketIOServer) {
    this.io = io;
    this.setupMiddleware();
    this.setupEventHandlers();
  }

  private setupMiddleware() {
    // Authentication middleware
    this.io.use(async (socket: AuthenticatedSocket, next) => {
      try {
        const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
        
        if (!token) {
          return next(new Error('Authentication token required'));
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
        
        if (decoded.type !== 'access') {
          return next(new Error('Invalid token type'));
        }

        const user = await User.findById(decoded.userId);
        if (!user || !user.isActive) {
          return next(new Error('User not found or inactive'));
        }

        socket.userId = decoded.userId;
        socket.user = user;
        next();

      } catch (error) {
        next(new Error('Invalid authentication token'));
      }
    });
  }

  private setupEventHandlers() {
    this.io.on('connection', (socket: AuthenticatedSocket) => {
      console.log(`User ${socket.userId} connected with socket ${socket.id}`);
      
      this.handleUserConnection(socket);
      this.handleChatEvents(socket);
      this.handleMessageEvents(socket);
      this.handleTypingEvents(socket);
      this.handleCallEvents(socket);
      this.handleDisconnection(socket);
    });
  }

  private async handleUserConnection(socket: AuthenticatedSocket) {
    const userId = socket.userId!;

    // Add socket to connected users
    if (!this.connectedUsers.has(userId)) {
      this.connectedUsers.set(userId, []);
    }
    this.connectedUsers.get(userId)!.push(socket.id);

    // Update user online status
    await User.findByIdAndUpdate(userId, {
      'status.isOnline': true,
      'status.lastSeen': new Date()
    });

    // Join user's chat rooms
    const userChats = await Chat.find({
      'participants.user': userId,
      'participants.hasLeft': false
    });

    userChats.forEach(chat => {
      socket.join(`chat:${chat._id}`);
    });

    // Notify friends about online status
    this.broadcastUserStatus(userId, true);

    // Send initial data
    socket.emit('user:connected', {
      userId,
      timestamp: new Date()
    });
  }

  private handleChatEvents(socket: AuthenticatedSocket) {
    // Join specific chat room
    socket.on('chat:join', async (data: { chatId: string }) => {
      try {
        const { chatId } = data;
        const userId = socket.userId!;

        // Verify user is participant
        const chat = await Chat.findOne({
          _id: chatId,
          'participants.user': userId,
          'participants.hasLeft': false
        });

        if (chat) {
          socket.join(`chat:${chatId}`);
          socket.emit('chat:joined', { chatId });
          
          // Notify other participants
          socket.to(`chat:${chatId}`).emit('user:joined_chat', {
            chatId,
            userId,
            timestamp: new Date()
          });
        } else {
          socket.emit('error', { message: 'Chat not found or access denied' });
        }

      } catch (error) {
        socket.emit('error', { message: 'Failed to join chat' });
      }
    });

    // Leave chat room
    socket.on('chat:leave', (data: { chatId: string }) => {
      const { chatId } = data;
      socket.leave(`chat:${chatId}`);
      socket.emit('chat:left', { chatId });
    });

    // Mark messages as read
    socket.on('chat:mark_read', async (data: { chatId: string, messageIds: string[] }) => {
      try {
        const { chatId, messageIds } = data;
        const userId = socket.userId!;

        // Update read status for messages
        await Message.updateMany(
          {
            _id: { $in: messageIds },
            chat: chatId,
            sender: { $ne: userId }
          },
          {
            $addToSet: {
              readBy: {
                user: userId,
                readAt: new Date()
              }
            }
          }
        );

        // Notify other participants
        socket.to(`chat:${chatId}`).emit('messages:read', {
          chatId,
          messageIds,
          readBy: userId,
          timestamp: new Date()
        });

      } catch (error) {
        socket.emit('error', { message: 'Failed to mark messages as read' });
      }
    });
  }

  private handleMessageEvents(socket: AuthenticatedSocket) {
    // Send message
    socket.on('message:send', async (data: {
      chatId: string;
      content: string;
      type: string;
      replyTo?: string;
      media?: any;
      location?: any;
      contact?: any;
      tempId?: string;
    }) => {
      try {
        const { chatId, content, type, replyTo, media, location, contact } = data;
        const userId = socket.userId!;

        // Verify user is participant
        const chat = await Chat.findOne({
          _id: chatId,
          'participants.user': userId,
          'participants.hasLeft': false
        });

        if (!chat) {
          return socket.emit('error', { message: 'Chat not found or access denied' });
        }

        // Create message
        const message = new Message({
          chat: chatId,
          sender: userId,
          content,
          type,
          replyTo,
          media,
          location,
          contact
        });

        await message.save();
        await message.populate('sender', 'username profile.firstName profile.lastName profile.avatar');

        // Update chat last message
        chat.lastMessage = message._id;
        chat.lastActivity = new Date();
        await chat.save();

        // Broadcast to chat participants
        this.io.to(`chat:${chatId}`).emit('message:new', {
          message,
          timestamp: new Date()
        });

        // Send delivery confirmation to sender
        socket.emit('message:sent', {
          messageId: message._id,
          tempId: data.tempId, // Client-side temporary ID
          timestamp: new Date()
        });

      } catch (error) {
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Edit message
    socket.on('message:edit', async (data: { messageId: string; newContent: string }) => {
      try {
        const { messageId, newContent } = data;
        const userId = socket.userId!;

        const message = await Message.findOne({
          _id: messageId,
          sender: userId,
          isDeleted: false
        });

        if (!message) {
          return socket.emit('error', { message: 'Message not found or cannot be edited' });
        }

        await message.editContent(newContent);

        // Broadcast to chat participants
        this.io.to(`chat:${message.chat}`).emit('message:edited', {
          messageId,
          newContent,
          editedAt: new Date()
        });

      } catch (error) {
        socket.emit('error', { message: 'Failed to edit message' });
      }
    });

    // Delete message
    socket.on('message:delete', async (data: { messageId: string }) => {
      try {
        const { messageId } = data;
        const userId = socket.userId!;

        const message = await Message.findOne({
          _id: messageId,
          sender: userId,
          isDeleted: false
        });

        if (!message) {
          return socket.emit('error', { message: 'Message not found or cannot be deleted' });
        }

        await message.softDelete();

        // Broadcast to chat participants
        this.io.to(`chat:${message.chat}`).emit('message:deleted', {
          messageId,
          deletedAt: new Date()
        });

      } catch (error) {
        socket.emit('error', { message: 'Failed to delete message' });
      }
    });

    // Add reaction
    socket.on('message:react', async (data: { messageId: string; emoji: string }) => {
      try {
        const { messageId, emoji } = data;
        const userId = socket.userId!;

        const message = await Message.findById(messageId);
        if (!message) {
          return socket.emit('error', { message: 'Message not found' });
        }

        await message.addReaction(new Types.ObjectId(userId), emoji);

        // Broadcast to chat participants
        this.io.to(`chat:${message.chat}`).emit('message:reaction_added', {
          messageId,
          emoji,
          userId,
          timestamp: new Date()
        });

      } catch (error) {
        socket.emit('error', { message: 'Failed to add reaction' });
      }
    });
  }

  private handleTypingEvents(socket: AuthenticatedSocket) {
    // User started typing
    socket.on('typing:start', (data: { chatId: string }) => {
      const { chatId } = data;
      const userId = socket.userId!;

      socket.to(`chat:${chatId}`).emit('typing:user_started', {
        chatId,
        userId,
        timestamp: new Date()
      });
    });

    // User stopped typing
    socket.on('typing:stop', (data: { chatId: string }) => {
      const { chatId } = data;
      const userId = socket.userId!;

      socket.to(`chat:${chatId}`).emit('typing:user_stopped', {
        chatId,
        userId,
        timestamp: new Date()
      });
    });
  }

  private handleCallEvents(socket: AuthenticatedSocket) {
    // Initiate call
    socket.on('call:initiate', (data: { chatId: string; type: 'audio' | 'video' }) => {
      const { chatId, type } = data;
      const userId = socket.userId!;

      socket.to(`chat:${chatId}`).emit('call:incoming', {
        chatId,
        callerId: userId,
        type,
        timestamp: new Date()
      });
    });

    // Accept call
    socket.on('call:accept', (data: { chatId: string; callerId: string }) => {
      const { chatId, callerId } = data;
      const userId = socket.userId!;

      // Notify caller that call was accepted
      this.notifyUser(callerId, 'call:accepted', {
        chatId,
        acceptedBy: userId,
        timestamp: new Date()
      });
    });

    // Reject call
    socket.on('call:reject', (data: { chatId: string; callerId: string }) => {
      const { chatId, callerId } = data;
      const userId = socket.userId!;

      // Notify caller that call was rejected
      this.notifyUser(callerId, 'call:rejected', {
        chatId,
        rejectedBy: userId,
        timestamp: new Date()
      });
    });

    // End call
    socket.on('call:end', (data: { chatId: string }) => {
      const { chatId } = data;
      const userId = socket.userId!;

      socket.to(`chat:${chatId}`).emit('call:ended', {
        chatId,
        endedBy: userId,
        timestamp: new Date()
      });
    });

    // WebRTC signaling
    socket.on('webrtc:offer', (data: { chatId: string; offer: any; target: string }) => {
      this.notifyUser(data.target, 'webrtc:offer', {
        offer: data.offer,
        from: socket.userId
      });
    });

    socket.on('webrtc:answer', (data: { chatId: string; answer: any; target: string }) => {
      this.notifyUser(data.target, 'webrtc:answer', {
        answer: data.answer,
        from: socket.userId
      });
    });

    socket.on('webrtc:ice-candidate', (data: { chatId: string; candidate: any; target: string }) => {
      this.notifyUser(data.target, 'webrtc:ice-candidate', {
        candidate: data.candidate,
        from: socket.userId
      });
    });
  }

  private handleDisconnection(socket: AuthenticatedSocket) {
    socket.on('disconnect', async () => {
      const userId = socket.userId!;
      console.log(`User ${userId} disconnected socket ${socket.id}`);

      // Remove socket from connected users
      const userSockets = this.connectedUsers.get(userId);
      if (userSockets) {
        const index = userSockets.indexOf(socket.id);
        if (index > -1) {
          userSockets.splice(index, 1);
        }

        // If no more sockets, mark user as offline
        if (userSockets.length === 0) {
          this.connectedUsers.delete(userId);
          
          await User.findByIdAndUpdate(userId, {
            'status.isOnline': false,
            'status.lastSeen': new Date()
          });

          this.broadcastUserStatus(userId, false);
        }
      }
    });
  }

  // Utility methods
  private async broadcastUserStatus(userId: string, isOnline: boolean) {
    // Get user's contacts/friends to notify about status change
    const userChats = await Chat.find({
      'participants.user': userId,
      'participants.hasLeft': false
    });

    const participantIds = new Set<string>();
    userChats.forEach(chat => {
      chat.participants.forEach(participant => {
        if (participant.user.toString() !== userId) {
          participantIds.add(participant.user.toString());
        }
      });
    });

    // Notify online participants
    participantIds.forEach(participantId => {
      this.notifyUser(participantId, 'user:status_changed', {
        userId,
        isOnline,
        timestamp: new Date()
      });
    });
  }

  private notifyUser(userId: string, event: string, data: any) {
    const userSockets = this.connectedUsers.get(userId);
    if (userSockets) {
      userSockets.forEach(socketId => {
        this.io.to(socketId).emit(event, data);
      });
    }
  }

  // Public methods for external use
  public getConnectedUsers(): string[] {
    return Array.from(this.connectedUsers.keys());
  }

  public isUserOnline(userId: string): boolean {
    return this.connectedUsers.has(userId);
  }

  public notifyUserExternal(userId: string, event: string, data: any) {
    this.notifyUser(userId, event, data);
  }
}