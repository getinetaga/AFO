import { Document, Schema, Types, model } from 'mongoose';

export interface IChat extends Document {
  _id: Types.ObjectId;
  name?: string;
  description?: string;
  type: 'direct' | 'group';
  participants: {
    user: Types.ObjectId;
    role: 'admin' | 'member' | 'moderator';
    joinedAt: Date;
    leftAt?: Date;
    hasLeft: boolean;
    isActive: boolean;
  }[];
  avatar?: string;
  lastMessage?: Types.ObjectId;
  lastActivity: Date;
  isArchived: boolean;
  settings: {
    allowMembersToAddOthers: boolean;
    allowMembersToEditGroupInfo: boolean;
    messageRetentionDays: number;
  };
  createdBy: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const chatSchema = new Schema<IChat>({
  name: {
    type: String,
    trim: true,
    maxlength: 100
  },
  description: {
    type: String,
    trim: true,
    maxlength: 500
  },
  type: {
    type: String,
    enum: ['direct', 'group'],
    required: true
  },
  participants: [{
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    role: {
      type: String,
      enum: ['admin', 'member', 'moderator'],
      default: 'member'
    },
    joinedAt: {
      type: Date,
      default: Date.now
    },
    leftAt: {
      type: Date
    },
    hasLeft: {
      type: Boolean,
      default: false
    },
    isActive: {
      type: Boolean,
      default: true
    }
  }],
  avatar: {
    type: String
  },
  lastMessage: {
    type: Schema.Types.ObjectId,
    ref: 'Message'
  },
  lastActivity: {
    type: Date,
    default: Date.now
  },
  isArchived: {
    type: Boolean,
    default: false
  },
  settings: {
    allowMembersToAddOthers: {
      type: Boolean,
      default: false
    },
    allowMembersToEditGroupInfo: {
      type: Boolean,
      default: false
    },
    messageRetentionDays: {
      type: Number,
      default: 365 // 1 year
    }
  },
  createdBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
chatSchema.index({ type: 1 });
chatSchema.index({ 'participants.user': 1 });
chatSchema.index({ lastActivity: -1 });
chatSchema.index({ createdAt: -1 });
chatSchema.index({ isArchived: 1 });

// For direct chats, ensure only 2 participants
chatSchema.pre('save', function(next) {
  if (this.type === 'direct' && this.participants.length !== 2) {
    const error = new Error('Direct chats must have exactly 2 participants');
    return next(error as any);
  }
  
  // For direct chats, don't allow name or description
  if (this.type === 'direct') {
    this.name = undefined;
    this.description = undefined;
  }
  
  next();
});

// Virtual for active participants count
chatSchema.virtual('activeParticipantsCount').get(function() {
  return this.participants.filter(p => p.isActive).length;
});

// Method to add participant
chatSchema.methods.addParticipant = function(userId: Types.ObjectId, role: string = 'member') {
  const existingParticipant = this.participants.find(p => 
    p.user.toString() === userId.toString()
  );
  
  if (existingParticipant) {
    if (!existingParticipant.isActive) {
      existingParticipant.isActive = true;
      existingParticipant.joinedAt = new Date();
      existingParticipant.leftAt = undefined;
    }
    return this;
  }
  
  this.participants.push({
    user: userId,
    role,
    joinedAt: new Date(),
    isActive: true
  });
  
  return this;
};

// Method to remove participant
chatSchema.methods.removeParticipant = function(userId: Types.ObjectId) {
  const participant = this.participants.find(p => 
    p.user.toString() === userId.toString()
  );
  
  if (participant) {
    participant.isActive = false;
    participant.leftAt = new Date();
  }
  
  return this;
};

// Method to update last activity
chatSchema.methods.updateLastActivity = function() {
  this.lastActivity = new Date();
  return this.save();
};

export const Chat = model<IChat>('Chat', chatSchema);