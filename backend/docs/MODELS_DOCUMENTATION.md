# Database Models Documentation

## Overview
The AFO backend uses MongoDB with Mongoose ODM to manage data persistence. The models are designed to support a comprehensive chat application with user management, real-time messaging, file sharing, and advanced features.

---

## User Model (User.ts)

### Purpose
Manages user accounts, authentication, preferences, and status tracking for the chat application.

### Interface: IUser

```typescript
export interface IUser extends Document {
  _id: Types.ObjectId;
  email: string;
  username: string;
  displayName: string;
  password: string;
  avatar?: string;
  isActive: boolean;
  isOnline: boolean;
  lastSeen: Date;
  lastLoginAt?: Date;
  status: {
    isOnline: boolean;
    lastSeen: Date;
  };
  role: 'user' | 'admin' | 'moderator';
  isEmailVerified: boolean;
  emailVerificationToken?: string;
  passwordResetToken?: string;
  passwordResetExpires?: Date;
  refreshTokens: RefreshToken[];
  preferences: UserPreferences;
  blocked: Types.ObjectId[];
  createdAt: Date;
  updatedAt: Date;
  
  // Methods
  comparePassword(candidatePassword: string): Promise<boolean>;
  toPublicJSON(): object;
}
```

### Schema Definition

#### Core User Information
```typescript
email: {
  type: String,
  required: true,
  unique: true,
  lowercase: true,
  trim: true,
  validate: {
    validator: (email: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email),
    message: 'Invalid email format'
  }
}

username: {
  type: String,
  required: true,
  unique: true,
  trim: true,
  minlength: 3,
  maxlength: 30,
  validate: {
    validator: (username: string) => /^[a-zA-Z0-9_]+$/.test(username),
    message: 'Username can only contain letters, numbers, and underscores'
  }
}

displayName: {
  type: String,
  required: true,
  trim: true,
  minlength: 1,
  maxlength: 50
}

password: {
  type: String,
  required: true,
  minlength: 8,
  select: false  // Exclude from queries by default
}
```

#### Status and Activity Tracking
```typescript
isActive: {
  type: Boolean,
  default: true
}

status: {
  isOnline: {
    type: Boolean,
    default: false
  },
  lastSeen: {
    type: Date,
    default: Date.now
  }
}

lastLoginAt: {
  type: Date
}
```

#### Security and Authentication
```typescript
isEmailVerified: {
  type: Boolean,
  default: false
}

emailVerificationToken: {
  type: String,
  sparse: true
}

passwordResetToken: {
  type: String,
  sparse: true
}

passwordResetExpires: {
  type: Date
}

refreshTokens: [{
  token: {
    type: String,
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  expiresAt: {
    type: Date,
    required: true
  }
}]
```

#### User Preferences
```typescript
preferences: {
  language: {
    type: String,
    default: 'en',
    enum: ['en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'zh', 'ja', 'ko']
  },
  notifications: {
    messages: {
      type: Boolean,
      default: true
    },
    calls: {
      type: Boolean,
      default: true
    },
    groups: {
      type: Boolean,
      default: true
    }
  },
  privacy: {
    showOnlineStatus: {
      type: Boolean,
      default: true
    },
    showLastSeen: {
      type: Boolean,
      default: true
    }
  }
}
```

### Instance Methods

#### Password Comparison
```typescript
userSchema.methods.comparePassword = async function(candidatePassword: string): Promise<boolean> {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw new Error('Password comparison failed');
  }
};
```

#### Public JSON Representation
```typescript
userSchema.methods.toPublicJSON = function(): object {
  const userObject = this.toObject();
  delete userObject.password;
  delete userObject.emailVerificationToken;
  delete userObject.passwordResetToken;
  delete userObject.refreshTokens;
  return userObject;
};
```

### Middleware Hooks

#### Password Hashing (Pre-save)
```typescript
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});
```

#### Refresh Token Cleanup
```typescript
userSchema.pre('save', function(next) {
  // Remove expired refresh tokens
  const now = new Date();
  this.refreshTokens = this.refreshTokens.filter(token => token.expiresAt > now);
  next();
});
```

### Indexes
```typescript
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ username: 1 }, { unique: true });
userSchema.index({ emailVerificationToken: 1 }, { sparse: true });
userSchema.index({ passwordResetToken: 1 }, { sparse: true });
userSchema.index({ 'status.isOnline': 1 });
userSchema.index({ lastLoginAt: -1 });
```

---

## Chat Model (Chat.ts)

### Purpose
Manages chat rooms (both direct and group chats), participant management, and chat metadata.

### Interface: IChat

```typescript
export interface IChat extends Document {
  _id: Types.ObjectId;
  type: 'direct' | 'group';
  name?: string;
  description?: string;
  avatar?: string;
  participants: Participant[];
  lastMessage?: Types.ObjectId;
  lastActivity: Date;
  isActive: boolean;
  settings: ChatSettings;
  createdBy: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
  
  // Methods
  addParticipant(userId: Types.ObjectId, role?: string): Promise<void>;
  removeParticipant(userId: Types.ObjectId): Promise<void>;
  updateLastActivity(): Promise<void>;
}
```

### Participant Schema
```typescript
interface Participant {
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  };
  role: {
    type: String,
    enum: ['admin', 'member'],
    default: 'member'
  };
  joinedAt: {
    type: Date,
    default: Date.now
  };
  hasLeft: {
    type: Boolean,
    default: false
  };
  isActive: {
    type: Boolean,
    default: true
  };
  lastReadMessageId: {
    type: Schema.Types.ObjectId,
    ref: 'Message'
  };
  notifications: {
    type: Boolean,
    default: true
  };
}
```

### Chat Settings Schema
```typescript
settings: {
  allowInvites: {
    type: Boolean,
    default: true
  },
  muteNotifications: {
    type: Boolean,
    default: false
  },
  disappearingMessages: {
    enabled: {
      type: Boolean,
      default: false
    },
    duration: {
      type: Number,
      default: 86400000  // 24 hours in milliseconds
    }
  }
}
```

### Instance Methods

#### Add Participant
```typescript
chatSchema.methods.addParticipant = async function(userId: Types.ObjectId, role: string = 'member'): Promise<void> {
  const existingParticipant = this.participants.find(
    (p: any) => p.user.toString() === userId.toString()
  );
  
  if (existingParticipant) {
    if (existingParticipant.hasLeft) {
      existingParticipant.hasLeft = false;
      existingParticipant.isActive = true;
      existingParticipant.joinedAt = new Date();
    }
  } else {
    this.participants.push({
      user: userId,
      role,
      joinedAt: new Date(),
      hasLeft: false,
      isActive: true
    });
  }
  
  await this.save();
};
```

#### Remove Participant
```typescript
chatSchema.methods.removeParticipant = async function(userId: Types.ObjectId): Promise<void> {
  const participant = this.participants.find(
    (p: any) => p.user.toString() === userId.toString()
  );
  
  if (participant) {
    participant.hasLeft = true;
    participant.isActive = false;
    await this.save();
  }
};
```

### Indexes
```typescript
chatSchema.index({ 'participants.user': 1 });
chatSchema.index({ lastActivity: -1 });
chatSchema.index({ type: 1, isActive: 1 });
chatSchema.index({ createdBy: 1 });
```

---

## Message Model (Message.ts)

### Purpose
Manages individual messages, reactions, edit history, and message metadata.

### Interface: IMessage

```typescript
export interface IMessage extends Document {
  _id: Types.ObjectId;
  chat: Types.ObjectId;
  sender: Types.ObjectId;
  content: string;
  type: 'text' | 'image' | 'file' | 'audio' | 'video' | 'system';
  fileUrl?: string;
  fileMetadata?: FileMetadata;
  reactions: Reaction[];
  editHistory: EditRecord[];
  tempId?: string;
  isEdited: boolean;
  isDeleted: boolean;
  replyTo?: Types.ObjectId;
  readBy: ReadReceipt[];
  createdAt: Date;
  updatedAt: Date;
  
  // Methods
  addReaction(userId: Types.ObjectId, emoji: string): Promise<void>;
  editContent(newContent: string): Promise<void>;
  softDelete(): Promise<void>;
  markAsRead(userId: Types.ObjectId): Promise<void>;
}
```

### Reaction Schema
```typescript
interface Reaction {
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  };
  emoji: {
    type: String,
    required: true,
    validate: {
      validator: (emoji: string) => /^[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/u.test(emoji),
      message: 'Invalid emoji format'
    }
  };
  createdAt: {
    type: Date,
    default: Date.now
  };
}
```

### Edit History Schema
```typescript
interface EditRecord {
  content: {
    type: String,
    required: true
  };
  editedAt: {
    type: Date,
    default: Date.now
  };
}
```

### Read Receipt Schema
```typescript
interface ReadReceipt {
  user: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  };
  readAt: {
    type: Date,
    default: Date.now
  };
}
```

### File Metadata Schema
```typescript
interface FileMetadata {
  filename: {
    type: String,
    required: true
  };
  originalName: {
    type: String,
    required: true
  };
  mimeType: {
    type: String,
    required: true
  };
  size: {
    type: Number,
    required: true,
    min: 0,
    max: 52428800  // 50MB limit
  };
  dimensions?: {
    width: Number,
    height: Number
  };
  duration?: {
    type: Number,
    min: 0
  };
}
```

### Instance Methods

#### Add Reaction
```typescript
messageSchema.methods.addReaction = async function(userId: Types.ObjectId, emoji: string): Promise<void> {
  const existingReaction = this.reactions.find(
    (r: any) => r.user.toString() === userId.toString() && r.emoji === emoji
  );
  
  if (existingReaction) {
    // Remove existing reaction (toggle off)
    this.reactions = this.reactions.filter(
      (r: any) => !(r.user.toString() === userId.toString() && r.emoji === emoji)
    );
  } else {
    // Add new reaction
    this.reactions.push({ user: userId, emoji });
  }
  
  await this.save();
};
```

#### Edit Content
```typescript
messageSchema.methods.editContent = async function(newContent: string): Promise<void> {
  // Store original content in edit history
  this.editHistory.push({
    content: this.content,
    editedAt: new Date()
  });
  
  this.content = newContent;
  this.isEdited = true;
  await this.save();
};
```

#### Mark as Read
```typescript
messageSchema.methods.markAsRead = async function(userId: Types.ObjectId): Promise<void> {
  const existingReceipt = this.readBy.find(
    (r: any) => r.user.toString() === userId.toString()
  );
  
  if (!existingReceipt) {
    this.readBy.push({ user: userId, readAt: new Date() });
    await this.save();
  }
};
```

### Indexes
```typescript
messageSchema.index({ chat: 1, createdAt: -1 });
messageSchema.index({ sender: 1 });
messageSchema.index({ tempId: 1 }, { sparse: true });
messageSchema.index({ replyTo: 1 }, { sparse: true });
messageSchema.index({ isDeleted: 1, createdAt: -1 });
```

---

## FileUpload Model (FileUpload.ts)

### Purpose
Manages file uploads, metadata, and security scanning for attachments.

### Interface: IFileUpload

```typescript
export interface IFileUpload extends Document {
  _id: Types.ObjectId;
  filename: string;
  originalName: string;
  mimeType: string;
  size: number;
  path: string;
  url: string;
  uploadedBy: Types.ObjectId;
  associatedMessage?: Types.ObjectId;
  metadata: FileMetadata;
  isPublic: boolean;
  virusScanResult?: VirusScanResult;
  downloadCount: number;
  expiresAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

### Virus Scan Result Schema
```typescript
interface VirusScanResult {
  scanned: {
    type: Boolean,
    default: false
  };
  clean: {
    type: Boolean,
    default: false
  };
  scanDate: {
    type: Date
  };
  threats: [{
    name: String,
    severity: {
      type: String,
      enum: ['low', 'medium', 'high', 'critical']
    }
  }];
}
```

### File Validation Middleware
```typescript
fileUploadSchema.pre('save', function(next) {
  // Validate file type
  const allowedTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf', 'text/plain',
    'audio/mp3', 'audio/wav', 'audio/ogg',
    'video/mp4', 'video/webm'
  ];
  
  if (!allowedTypes.includes(this.mimeType)) {
    return next(new Error('File type not allowed'));
  }
  
  // Validate file size (50MB limit)
  if (this.size > 52428800) {
    return next(new Error('File size exceeds limit'));
  }
  
  next();
});
```

### Indexes
```typescript
fileUploadSchema.index({ uploadedBy: 1, createdAt: -1 });
fileUploadSchema.index({ associatedMessage: 1 });
fileUploadSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
fileUploadSchema.index({ 'virusScanResult.clean': 1 });
```

---

## Model Exports (index.ts)

### Purpose
Centralizes model exports and provides a single import point for all models.

```typescript
export { User, IUser } from './User';
export { Chat, IChat } from './Chat';
export { Message, IMessage } from './Message';
export { FileUpload, IFileUpload } from './FileUpload';

// Type exports for interfaces
export type {
  IUser,
  IChat,
  IMessage,
  IFileUpload
} from './types';
```

---

## Database Performance Considerations

### Indexing Strategy
- **Compound Indexes**: For frequently queried field combinations
- **Sparse Indexes**: For optional fields that are queried
- **TTL Indexes**: For automatic document expiration
- **Text Indexes**: For search functionality

### Query Optimization
- **Population**: Efficient use of Mongoose populate
- **Projection**: Selecting only required fields
- **Pagination**: Cursor-based pagination for large datasets
- **Aggregation**: Complex queries using aggregation pipeline

### Data Consistency
- **Transactions**: For multi-document operations
- **Validation**: Schema-level and application-level validation
- **Atomic Updates**: Using atomic operators for concurrent access
- **Referential Integrity**: Proper relationship management

This comprehensive documentation covers all database models, their relationships, and implementation details for the AFO chat application backend.