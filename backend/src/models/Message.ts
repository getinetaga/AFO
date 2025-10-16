import { Document, Schema, Types, model } from 'mongoose';

export interface IMessage extends Document {
  _id: Types.ObjectId;
  chat: Types.ObjectId;
  sender: Types.ObjectId;
  content: string;
  type: 'text' | 'image' | 'video' | 'audio' | 'document' | 'location' | 'contact' | 'sticker' | 'gif';
  media?: {
    originalName: string;
    filename: string;
    mimetype: string;
    size: number;
    url: string;
    thumbnail?: string;
    duration?: number; // For audio/video
    dimensions?: {
      width: number;
      height: number;
    }; // For images/videos
  };
  location?: {
    latitude: number;
    longitude: number;
    address?: string;
  };
  contact?: {
    name: string;
    phone?: string;
    email?: string;
  };
  replyTo?: Types.ObjectId;
  reactions: {
    user: Types.ObjectId;
    emoji: string;
    createdAt: Date;
  }[];
  editHistory: {
    content: string;
    editedAt: Date;
  }[];
  isEdited: boolean;
  isDeleted: boolean;
  deletedAt?: Date;
  deliveryStatus: {
    sent: Date;
    delivered?: Date;
    read?: Date;
  };
  readBy: {
    user: Types.ObjectId;
    readAt: Date;
  }[];
  metadata: {
    deviceInfo?: string;
    ipAddress?: string;
    isForwarded: boolean;
    forwardedFrom?: Types.ObjectId;
  };
  createdAt: Date;
  updatedAt: Date;
  
  // Method signatures
  addReaction(userId: Types.ObjectId, emoji: string): Promise<any>;
  removeReaction(userId: Types.ObjectId, emoji: string): Promise<any>;
  editContent(newContent: string): Promise<any>;
  markAsRead(userId: Types.ObjectId): Promise<any>;
  softDelete(): Promise<any>;
}

const messageSchema = new Schema<IMessage>({
  chat: {
    type: Schema.Types.ObjectId,
    ref: 'Chat',
    required: true
  },
  sender: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  content: {
    type: String,
    required: function() {
      return this.type === 'text' && !this.isDeleted;
    },
    maxlength: 4000
  },
  type: {
    type: String,
    enum: ['text', 'image', 'video', 'audio', 'document', 'location', 'contact', 'sticker', 'gif'],
    default: 'text'
  },
  media: {
    originalName: String,
    filename: String,
    mimetype: String,
    size: Number,
    url: String,
    thumbnail: String,
    duration: Number,
    dimensions: {
      width: Number,
      height: Number
    }
  },
  location: {
    latitude: {
      type: Number,
      min: -90,
      max: 90
    },
    longitude: {
      type: Number,
      min: -180,
      max: 180
    },
    address: String
  },
  contact: {
    name: String,
    phone: String,
    email: String
  },
  replyTo: {
    type: Schema.Types.ObjectId,
    ref: 'Message'
  },
  reactions: [{
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    emoji: {
      type: String,
      required: true
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  editHistory: [{
    content: {
      type: String,
      required: true
    },
    editedAt: {
      type: Date,
      default: Date.now
    }
  }],
  isEdited: {
    type: Boolean,
    default: false
  },
  isDeleted: {
    type: Boolean,
    default: false
  },
  deletedAt: {
    type: Date
  },
  deliveryStatus: {
    sent: {
      type: Date,
      default: Date.now
    },
    delivered: Date,
    read: Date
  },
  readBy: [{
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }],
  metadata: {
    deviceInfo: String,
    ipAddress: String,
    isForwarded: {
      type: Boolean,
      default: false
    },
    forwardedFrom: {
      type: Schema.Types.ObjectId,
      ref: 'Message'
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes for performance
messageSchema.index({ chat: 1, createdAt: -1 });
messageSchema.index({ sender: 1 });
messageSchema.index({ type: 1 });
messageSchema.index({ isDeleted: 1 });
messageSchema.index({ 'deliveryStatus.sent': -1 });
messageSchema.index({ 'readBy.user': 1 });

// Text search index for content
messageSchema.index({ content: 'text' });

// Virtual for reaction counts
messageSchema.virtual('reactionCounts').get(function() {
  const counts: { [key: string]: number } = {};
  this.reactions.forEach(reaction => {
    counts[reaction.emoji] = (counts[reaction.emoji] || 0) + 1;
  });
  return counts;
});

// Method to add reaction
messageSchema.methods.addReaction = function(userId: Types.ObjectId, emoji: string) {
  // Remove existing reaction from this user for this emoji
  this.reactions = this.reactions.filter(r => 
    !(r.user.toString() === userId.toString() && r.emoji === emoji)
  );
  
  // Add new reaction
  this.reactions.push({
    user: userId,
    emoji,
    createdAt: new Date()
  });
  
  return this.save();
};

// Method to remove reaction
messageSchema.methods.removeReaction = function(userId: Types.ObjectId, emoji: string) {
  this.reactions = this.reactions.filter(r => 
    !(r.user.toString() === userId.toString() && r.emoji === emoji)
  );
  
  return this.save();
};

// Method to edit message
messageSchema.methods.editContent = function(newContent: string) {
  if (this.isDeleted) {
    throw new Error('Cannot edit deleted message');
  }
  
  // Save to edit history
  if (this.content !== newContent) {
    this.editHistory.push({
      content: this.content,
      editedAt: new Date()
    });
    
    this.content = newContent;
    this.isEdited = true;
  }
  
  return this.save();
};

// Method to mark as read
messageSchema.methods.markAsRead = function(userId: Types.ObjectId) {
  const existingRead = this.readBy.find(r => r.user.toString() === userId.toString());
  
  if (!existingRead) {
    this.readBy.push({
      user: userId,
      readAt: new Date()
    });
    
    // Update delivery status if this is the sender reading their own message
    if (!this.deliveryStatus.read) {
      this.deliveryStatus.read = new Date();
    }
  }
  
  return this.save();
};

// Method to soft delete
messageSchema.methods.softDelete = function() {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.content = 'This message was deleted';
  
  return this.save();
};

export const Message = model<IMessage>('Message', messageSchema);