import { Request, Response, Router } from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { Types } from 'mongoose';
import { auth } from '../middleware/auth';
import { Chat } from '../models/Chat';
import { Message } from '../models/Message';
import { User } from '../models/User';

const router = Router();

// Validation middleware
const createChatValidation = [
  body('participants')
    .isArray({ min: 1 })
    .withMessage('At least one participant is required')
    .custom((participants) => {
      return participants.every((p: string) => Types.ObjectId.isValid(p));
    })
    .withMessage('All participants must be valid user IDs'),
  
  body('type')
    .isIn(['direct', 'group'])
    .withMessage('Chat type must be either direct or group'),
  
  body('name')
    .optional()
    .isLength({ min: 1, max: 100 })
    .withMessage('Chat name must be between 1 and 100 characters'),
  
  body('description')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Description must be less than 500 characters')
];

const sendMessageValidation = [
  body('content')
    .optional()
    .isLength({ min: 1, max: 4000 })
    .withMessage('Message content must be between 1 and 4000 characters'),
  
  body('type')
    .isIn(['text', 'image', 'video', 'audio', 'document', 'location', 'contact', 'sticker', 'gif'])
    .withMessage('Invalid message type'),
  
  body('replyTo')
    .optional()
    .isMongoId()
    .withMessage('Reply to must be a valid message ID')
];

// Get all chats for the authenticated user
router.get('/', auth, async (req: Request, res: Response) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const userId = req.userId!;

    // Build query
    const query: any = {
      participants: {
        $elemMatch: {
          user: userId,
          hasLeft: false
        }
      }
    };

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const chats = await Chat.find(query)
      .populate('participants.user', 'username profile.firstName profile.lastName profile.avatar status.isOnline')
      .populate('lastMessage')
      .sort({ updatedAt: -1 })
      .limit(Number(limit) * Number(page))
      .skip((Number(page) - 1) * Number(limit));

    const total = await Chat.countDocuments(query);

    res.json({
      success: true,
      data: {
        chats,
        pagination: {
          current: Number(page),
          pages: Math.ceil(total / Number(limit)),
          total
        }
      }
    });

  } catch (error) {
    console.error('Get chats error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get a specific chat
router.get('/:chatId', auth, [
  param('chatId').isMongoId().withMessage('Invalid chat ID')
], async (req: Request, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { chatId } = req.params;
    const userId = req.userId!;

    const chat = await Chat.findOne({
      _id: chatId,
      'participants.user': userId,
      'participants.hasLeft': false
    })
    .populate('participants.user', 'username profile.firstName profile.lastName profile.avatar status.isOnline status.lastSeen')
    .populate('lastMessage');

    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Chat not found'
      });
    }

    res.json({
      success: true,
      data: { chat }
    });

  } catch (error) {
    console.error('Get chat error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Create a new chat
router.post('/', auth, createChatValidation, async (req: Request, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { participants, type, name, description } = req.body;
    const userId = req.userId!;

    // Add creator to participants if not already included
    const allParticipants = [...new Set([userId, ...participants])];

    // Validate participants exist
    const users = await User.find({ _id: { $in: allParticipants } });
    if (users.length !== allParticipants.length) {
      return res.status(400).json({
        success: false,
        message: 'Some participants do not exist'
      });
    }

    // For direct chats, ensure only 2 participants
    if (type === 'direct') {
      if (allParticipants.length !== 2) {
        return res.status(400).json({
          success: false,
          message: 'Direct chats must have exactly 2 participants'
        });
      }

      // Check if direct chat already exists
      const existingChat = await Chat.findOne({
        type: 'direct',
        'participants.user': { $all: allParticipants },
        'participants.hasLeft': false
      });

      if (existingChat) {
        return res.status(409).json({
          success: false,
          message: 'Direct chat already exists',
          data: { chat: existingChat }
        });
      }
    }

    // Create chat participants
    const chatParticipants = allParticipants.map(participantId => ({
      user: participantId,
      role: participantId === userId ? 'admin' : 'member',
      joinedAt: new Date(),
      hasLeft: false,
      isActive: true
    }));

    const chat = new Chat({
      type,
      name: type === 'group' ? name : undefined,
      description: type === 'group' ? description : undefined,
      participants: chatParticipants,
      createdBy: userId
    });

    await chat.save();
    await chat.populate('participants.user', 'username profile.firstName profile.lastName profile.avatar status.isOnline');

    res.status(201).json({
      success: true,
      message: 'Chat created successfully',
      data: { chat }
    });

  } catch (error) {
    console.error('Create chat error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Update chat details (group chats only)
router.put('/:chatId', auth, [
  param('chatId').isMongoId().withMessage('Invalid chat ID'),
  body('name').optional().isLength({ min: 1, max: 100 }).withMessage('Name must be between 1 and 100 characters'),
  body('description').optional().isLength({ max: 500 }).withMessage('Description must be less than 500 characters')
], async (req: Request, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { chatId } = req.params;
    const { name, description } = req.body;
    const userId = req.userId!;

    const chat = await Chat.findOne({
      _id: chatId,
      type: 'group',
      'participants.user': userId,
      'participants.hasLeft': false
    });

    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Group chat not found'
      });
    }

    // Check if user has admin privileges
    const userParticipant = chat.participants.find(p => p.user.toString() === userId);
    if (!userParticipant || !['admin', 'moderator'].includes(userParticipant.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }

    if (name !== undefined) chat.name = name;
    if (description !== undefined) chat.description = description;

    await chat.save();

    res.json({
      success: true,
      message: 'Chat updated successfully',
      data: { chat }
    });

  } catch (error) {
    console.error('Update chat error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Add participants to group chat
router.post('/:chatId/participants', auth, [
  param('chatId').isMongoId().withMessage('Invalid chat ID'),
  body('participants').isArray({ min: 1 }).withMessage('At least one participant is required')
], async (req: Request, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { chatId } = req.params;
    const { participants } = req.body;
    const userId = req.userId!;

    const chat = await Chat.findOne({
      _id: chatId,
      type: 'group',
      'participants.user': userId,
      'participants.hasLeft': false
    });

    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Group chat not found'
      });
    }

    // Check permissions
    const userParticipant = chat.participants.find(p => p.user.toString() === userId);
    if (!userParticipant || !['admin', 'moderator'].includes(userParticipant.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }

    // Validate new participants
    const users = await User.find({ _id: { $in: participants } });
    if (users.length !== participants.length) {
      return res.status(400).json({
        success: false,
        message: 'Some participants do not exist'
      });
    }

    // Add new participants
    const existingParticipantIds = chat.participants.map(p => p.user.toString());
    const newParticipants = participants.filter((p: string) => !existingParticipantIds.includes(p));

    if (newParticipants.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'All participants are already in the chat'
      });
    }

    newParticipants.forEach((participantId: string) => {
      chat.participants.push({
        user: new Types.ObjectId(participantId),
        role: 'member',
        joinedAt: new Date(),
        hasLeft: false,
        isActive: true
      });
    });

    await chat.save();

    res.json({
      success: true,
      message: 'Participants added successfully',
      data: { addedCount: newParticipants.length }
    });

  } catch (error) {
    console.error('Add participants error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Leave chat
router.post('/:chatId/leave', auth, [
  param('chatId').isMongoId().withMessage('Invalid chat ID')
], async (req: Request, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { chatId } = req.params;
    const userId = req.userId!;

    const chat = await Chat.findOne({
      _id: chatId,
      'participants.user': userId,
      'participants.hasLeft': false
    });

    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Chat not found'
      });
    }

    // Mark user as left
    const participant = chat.participants.find(p => p.user.toString() === userId);
    if (participant) {
      participant.hasLeft = true;
      participant.leftAt = new Date();
    }

    await chat.save();

    res.json({
      success: true,
      message: 'Left chat successfully'
    });

  } catch (error) {
    console.error('Leave chat error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get messages for a chat
router.get('/:chatId/messages', auth, [
  param('chatId').isMongoId().withMessage('Invalid chat ID'),
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100')
], async (req: Request, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { chatId } = req.params;
    const { page = 1, limit = 50, before } = req.query;
    const userId = req.userId!;

    // Check if user is participant
    const chat = await Chat.findOne({
      _id: chatId,
      'participants.user': userId,
      'participants.hasLeft': false
    });

    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Chat not found'
      });
    }

    // Build query
    const query: any = {
      chat: chatId,
      isDeleted: false
    };

    if (before) {
      query.createdAt = { $lt: new Date(before as string) };
    }

    const messages = await Message.find(query)
      .populate('sender', 'username profile.firstName profile.lastName profile.avatar')
      .populate('replyTo', 'content sender type')
      .sort({ createdAt: -1 })
      .limit(Number(limit))
      .skip((Number(page) - 1) * Number(limit));

    const total = await Message.countDocuments(query);

    res.json({
      success: true,
      data: {
        messages: messages.reverse(), // Reverse to show oldest first
        pagination: {
          current: Number(page),
          pages: Math.ceil(total / Number(limit)),
          total
        }
      }
    });

  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Send a message
router.post('/:chatId/messages', auth, [
  param('chatId').isMongoId().withMessage('Invalid chat ID'),
  ...sendMessageValidation
], async (req: Request, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { chatId } = req.params;
    const { content, type, replyTo, media, location, contact } = req.body;
    const userId = req.userId!;

    // Check if user is participant
    const chat = await Chat.findOne({
      _id: chatId,
      'participants.user': userId,
      'participants.hasLeft': false
    });

    if (!chat) {
      return res.status(404).json({
        success: false,
        message: 'Chat not found'
      });
    }

    // Validate reply message if provided
    if (replyTo) {
      const replyMessage = await Message.findOne({
        _id: replyTo,
        chat: chatId,
        isDeleted: false
      });

      if (!replyMessage) {
        return res.status(400).json({
          success: false,
          message: 'Reply message not found'
        });
      }
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

    // Update chat's last message and activity
    chat.lastMessage = message._id;
    chat.lastActivity = new Date();
    await chat.save();

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: { message }
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

export default router;