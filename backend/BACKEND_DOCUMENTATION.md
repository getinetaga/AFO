# AFO Backend - Comprehensive File Documentation

## Table of Contents
1. [Project Structure](#project-structure)
2. [Server Architecture](#server-architecture)
3. [Database Models](#database-models)
4. [API Routes](#api-routes)
5. [Middleware](#middleware)
6. [Socket.IO Handlers](#socketio-handlers)
7. [Utilities](#utilities)
8. [Configuration](#configuration)

---

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   └── database.ts          # Database configuration
│   ├── middleware/
│   │   └── auth.ts              # Authentication middleware
│   ├── models/
│   │   ├── index.ts             # Model exports
│   │   ├── User.ts              # User data model
│   │   ├── Chat.ts              # Chat room model
│   │   ├── Message.ts           # Message model
│   │   └── FileUpload.ts        # File upload model
│   ├── routes/
│   │   ├── auth.ts              # Authentication routes
│   │   └── chat.ts              # Chat management routes
│   ├── socket/
│   │   └── socketHandler.ts     # Real-time Socket.IO handlers
│   ├── utils/
│   │   └── emailService.ts      # Email notification utilities
│   ├── database.ts              # Database connection setup
│   ├── index.ts                 # Application entry point
│   └── server.ts                # Express server setup
├── package.json                 # Dependencies and scripts
├── tsconfig.json               # TypeScript configuration
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore patterns
├── README.md                   # Project overview
└── INSTALLATION_GUIDE.md       # Setup instructions
```

---

## Server Architecture

### src/server.ts
**Purpose**: Main Express server setup with middleware, routes, and Socket.IO integration

#### Key Components:
- **Express Application**: Web server framework
- **HTTP Server**: Node.js HTTP server wrapper
- **Socket.IO Server**: Real-time communication
- **Security Middleware**: Helmet, CORS, rate limiting
- **Database Integration**: MongoDB connection
- **File Upload Handling**: Static file serving

#### Class: AFOBackendServer

```typescript
export class AFOBackendServer {
  private app: Express;
  private server: Server;
  private io: SocketIOServer;
  private socketHandler: SocketHandler;
  private port: number;
}
```

**Methods:**
- `constructor()`: Initialize server components
- `initializeMiddleware()`: Setup security and parsing middleware
- `initializeRoutes()`: Configure API endpoints
- `initializeDatabase()`: Connect to MongoDB
- `initializeSocketIO()`: Setup real-time communication
- `start()`: Start the server
- `stop()`: Graceful shutdown

**Security Features:**
- **Helmet**: Security headers protection
- **CORS**: Cross-origin resource sharing configuration
- **Rate Limiting**: API request throttling (100 requests/15 minutes)
- **Body Parsing**: JSON and URL-encoded data with 50MB limit
- **Compression**: Response compression for performance

**Health Check Endpoint:**
- `GET /health`: Server status, uptime, and environment info

---

### src/index.ts
**Purpose**: Application entry point and server initialization

#### Key Features:
- Environment variable loading
- Server instantiation
- Error handling and graceful shutdown
- Process signal handling (SIGTERM, SIGINT)

---

## Database Models

### src/models/User.ts
**Purpose**: User account management and authentication

#### Interface: IUser

```typescript
interface IUser extends Document {
  _id: Types.ObjectId;
  email: string;
  username: string;
  displayName: string;
  password: string;
  avatar?: string;
  isActive: boolean;
  isOnline: boolean;
  lastSeen: Date;
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
}
```

**Key Methods:**
- `comparePassword(candidatePassword: string)`: Password verification
- `toPublicJSON()`: Safe user data for client responses

**Indexes:**
- email (unique)
- username (unique)
- emailVerificationToken
- passwordResetToken

**Security Features:**
- Password hashing with bcrypt (12 rounds)
- Refresh token management
- Email verification system
- Password reset functionality

---

### src/models/Chat.ts
**Purpose**: Chat room and conversation management

#### Interface: IChat

```typescript
interface IChat extends Document {
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
}
```

**Participant Schema:**
```typescript
interface Participant {
  user: Types.ObjectId;
  role: 'admin' | 'member';
  joinedAt: Date;
  hasLeft: boolean;
  isActive: boolean;
  lastReadMessageId?: Types.ObjectId;
  notifications: boolean;
}
```

**Key Methods:**
- `addParticipant(userId, role)`: Add user to chat
- `removeParticipant(userId)`: Remove user from chat
- `updateLastActivity()`: Update chat activity timestamp

**Indexes:**
- participants.user
- lastActivity
- type + isActive

---

### src/models/Message.ts
**Purpose**: Message content and metadata management

#### Interface: IMessage

```typescript
interface IMessage extends Document {
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
}
```

**Key Methods:**
- `addReaction(userId, emoji)`: Add emoji reaction
- `editContent(newContent)`: Edit message content
- `softDelete()`: Mark message as deleted
- `markAsRead(userId)`: Add read receipt

**Indexes:**
- chat + createdAt
- sender
- tempId (sparse)

---

### src/models/FileUpload.ts
**Purpose**: File attachment and upload management

#### Interface: IFileUpload

```typescript
interface IFileUpload extends Document {
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
  createdAt: Date;
}
```

**Security Features:**
- File type validation
- Size limit enforcement
- Virus scanning integration
- Access control

---

## API Routes

### src/routes/auth.ts
**Purpose**: User authentication and account management

#### Endpoints:

##### POST /api/auth/register
- **Purpose**: User registration
- **Validation**: Email, username, password requirements
- **Rate Limit**: 10 requests/15 minutes
- **Response**: User data + JWT tokens

##### POST /api/auth/login
- **Purpose**: User login
- **Validation**: Email/username + password
- **Rate Limit**: 10 requests/15 minutes
- **Response**: User data + JWT tokens

##### POST /api/auth/logout
- **Purpose**: User logout
- **Authentication**: Required
- **Action**: Invalidate refresh token

##### POST /api/auth/refresh
- **Purpose**: Refresh access token
- **Input**: Refresh token
- **Response**: New access token

##### POST /api/auth/forgot-password
- **Purpose**: Request password reset
- **Rate Limit**: 3 requests/hour
- **Action**: Send reset email

##### POST /api/auth/reset-password
- **Purpose**: Reset password with token
- **Input**: Reset token + new password
- **Validation**: Token validity + password strength

##### POST /api/auth/verify-email
- **Purpose**: Verify email address
- **Input**: Verification token

##### POST /api/auth/resend-verification
- **Purpose**: Resend verification email
- **Rate Limit**: 3 requests/hour

#### Security Features:
- Input validation with express-validator
- Rate limiting per endpoint
- JWT token generation and validation
- Password strength requirements
- Email verification system

---

### src/routes/chat.ts
**Purpose**: Chat and message management

#### Endpoints:

##### GET /api/chats
- **Purpose**: Get user's chats
- **Authentication**: Required
- **Response**: List of chats with metadata

##### POST /api/chats
- **Purpose**: Create new chat
- **Input**: Chat type, participants, name (for groups)
- **Validation**: Participant existence, permissions

##### GET /api/chats/:chatId
- **Purpose**: Get specific chat details
- **Authentication**: Required
- **Authorization**: Chat membership required

##### PUT /api/chats/:chatId
- **Purpose**: Update chat settings
- **Authorization**: Admin role required for groups

##### DELETE /api/chats/:chatId
- **Purpose**: Delete/leave chat
- **Authorization**: Admin can delete, members can leave

##### POST /api/chats/:chatId/participants
- **Purpose**: Add participants to chat
- **Authorization**: Admin role required

##### DELETE /api/chats/:chatId/participants/:userId
- **Purpose**: Remove participant
- **Authorization**: Admin role or self-removal

##### GET /api/chats/:chatId/messages
- **Purpose**: Get chat messages
- **Pagination**: Offset-based with limit
- **Query Parameters**: limit, offset, before, after

##### POST /api/chats/:chatId/messages
- **Purpose**: Send message
- **Input**: Content, type, replyTo, tempId
- **File Support**: Multipart upload

##### PUT /api/chats/:chatId/messages/:messageId
- **Purpose**: Edit message
- **Authorization**: Message sender only
- **Time Limit**: 24 hours after sending

##### DELETE /api/chats/:chatId/messages/:messageId
- **Purpose**: Delete message
- **Authorization**: Sender or chat admin

##### POST /api/chats/:chatId/messages/:messageId/reactions
- **Purpose**: Add/remove reaction
- **Input**: Emoji type

##### POST /api/chats/:chatId/upload
- **Purpose**: Upload file
- **File Support**: Images, documents, audio, video
- **Security**: Type validation, size limits

---

## Middleware

### src/middleware/auth.ts
**Purpose**: JWT authentication and authorization

#### Functions:

##### auth(req, res, next)
- **Purpose**: Verify JWT access token
- **Header**: Authorization: Bearer <token>
- **Action**: Add user to request object
- **Error Handling**: 401 for invalid/expired tokens

##### optionalAuth(req, res, next)
- **Purpose**: Optional authentication
- **Behavior**: Continue without user if no token

##### requireRole(role)
- **Purpose**: Role-based authorization
- **Roles**: 'admin', 'moderator', 'user'
- **Usage**: Middleware factory function

#### JWT Token Structure:
```typescript
interface JWTPayload {
  userId: string;
  type: 'access' | 'refresh';
  iat: number;
  exp: number;
}
```

---

## Socket.IO Handlers

### src/socket/socketHandler.ts
**Purpose**: Real-time communication management

#### Class: SocketHandler

##### Authentication Middleware:
- Token verification on connection
- User session management
- Connection tracking

##### Connection Management:
- `connectedUsers`: Map<userId, socketId[]>
- User presence tracking
- Multi-device support

#### Events:

##### Connection Events:
- `connection`: New client connection
- `disconnect`: Client disconnection
- `error`: Connection errors

##### Authentication:
- `authenticate`: Socket-level auth
- User session establishment

##### Chat Management:
- `join_chat`: Join chat room
- `leave_chat`: Leave chat room
- Room-based message broadcasting

##### Messaging:
- `send_message`: Send new message
- `edit_message`: Edit existing message
- `delete_message`: Delete message
- `add_reaction`: Add emoji reaction
- `new_message`: Broadcast new message
- `message_edited`: Broadcast edit
- `message_deleted`: Broadcast deletion
- `reaction_added`: Broadcast reaction

##### Typing Indicators:
- `typing_start`: User starts typing
- `typing_stop`: User stops typing
- `user_typing`: Broadcast typing status

##### User Presence:
- `user_online`: User comes online
- `user_offline`: User goes offline
- `get_online_users`: Request online users list
- `online_users_list`: Send online users

##### WebRTC Signaling:
- `webrtc_offer`: Send call offer
- `webrtc_answer`: Send call answer
- `webrtc_ice_candidate`: Exchange ICE candidates
- `webrtc_hang_up`: End call

#### Security Features:
- Token-based authentication
- Room-based authorization
- Message validation
- Rate limiting on events

---

## Utilities

### src/utils/emailService.ts
**Purpose**: Email notification system

#### Functions:

##### sendEmail(to, subject, html, text?)
- **Purpose**: Send email via SMTP
- **Provider**: Configurable (Gmail, SendGrid, etc.)
- **Templates**: HTML and text support

##### sendVerificationEmail(user, token)
- **Purpose**: Send email verification
- **Template**: Custom HTML template
- **Link**: Frontend verification URL

##### sendPasswordResetEmail(user, token)
- **Purpose**: Send password reset email
- **Template**: Custom HTML template
- **Security**: Token expiration

##### sendWelcomeEmail(user)
- **Purpose**: Welcome new users
- **Template**: Branded welcome message

#### Configuration:
- SMTP settings from environment
- Template customization
- Error handling and logging

---

## Configuration

### src/database.ts
**Purpose**: MongoDB connection management

#### Function: connectDB()
- **Connection**: Mongoose ODM
- **URL**: Environment-based URI
- **Options**: Connection pooling, timeouts
- **Error Handling**: Retry logic
- **Logging**: Connection status

#### Features:
- Automatic reconnection
- Connection pooling
- Index creation
- Schema validation

### src/config/database.ts
**Purpose**: Database configuration settings

#### Exports:
- Connection options
- Pool settings
- Timeout configurations
- Environment-specific settings

---

## Environment Variables

### Required Variables:
```env
NODE_ENV=development|production
PORT=3000
MONGODB_URI=mongodb://localhost:27017/afo-chat
JWT_SECRET=your-jwt-secret
JWT_REFRESH_SECRET=your-refresh-secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@domain.com
EMAIL_PASS=your-app-password
EMAIL_FROM=noreply@domain.com
FRONTEND_URL=http://localhost:3000
```

### Optional Variables:
```env
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=50MB
REDIS_URL=redis://localhost:6379
LOG_LEVEL=info
```

---

## Error Handling

### Global Error Handler:
- Centralized error processing
- Environment-specific responses
- Logging and monitoring
- Client-safe error messages

### Error Types:
- ValidationError: Input validation failures
- AuthenticationError: Auth failures
- AuthorizationError: Permission denied
- NotFoundError: Resource not found
- DatabaseError: MongoDB operations
- FileUploadError: File processing

---

## Security Features

### Authentication:
- JWT-based stateless auth
- Refresh token rotation
- Password hashing (bcrypt)
- Email verification

### Authorization:
- Role-based access control
- Resource-level permissions
- Chat membership validation

### Input Validation:
- Express-validator integration
- Schema validation
- File type restrictions
- Size limitations

### Security Headers:
- Helmet middleware
- CORS configuration
- Rate limiting
- Content Security Policy

### File Security:
- Type validation
- Size restrictions
- Virus scanning
- Secure storage

---

## Performance Optimizations

### Database:
- Proper indexing
- Query optimization
- Connection pooling
- Aggregation pipelines

### Caching:
- Redis integration ready
- Memory caching
- Static file serving

### Real-time:
- Room-based broadcasting
- Event debouncing
- Connection management

---

## Monitoring and Logging

### Logging:
- Morgan HTTP logging
- Custom application logs
- Error tracking
- Performance metrics

### Health Monitoring:
- Health check endpoint
- Uptime tracking
- Resource usage
- Database connectivity

---

## Testing Strategy

### Unit Tests:
- Model validation
- Utility functions
- Middleware behavior

### Integration Tests:
- API endpoint testing
- Database operations
- Authentication flows

### Real-time Tests:
- Socket.IO events
- Connection handling
- Message broadcasting

---

## Deployment Considerations

### Production Setup:
- Environment configuration
- SSL/TLS certificates
- Load balancing
- Process management (PM2)

### Scaling:
- Horizontal scaling ready
- Database clustering
- Redis for session management
- CDN for file serving

### Security:
- Regular dependency updates
- Security audits
- Rate limiting tuning
- Monitoring alerts

---

This documentation provides a comprehensive overview of all backend files, their purposes, and how they work together to create a robust, secure, and scalable chat application backend.