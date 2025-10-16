# AFO Backend - Installation and Setup Guide

## Overview
The AFO Backend is a comprehensive Node.js/Express server with TypeScript that provides:
- RESTful API for authentication and chat management
- Real-time messaging with Socket.IO
- MongoDB integration with Mongoose ODM
- JWT-based authentication with refresh tokens
- File upload capabilities
- Email notifications
- Security middleware (CORS, helmet, rate limiting)
- WebRTC signaling for voice/video calls

## Prerequisites
- Node.js (v16 or higher)
- npm or yarn
- MongoDB (local or cloud instance)
- TypeScript (installed globally or via npm)

## Installation

### 1. Navigate to Backend Directory
```bash
cd /path/to/AFO/AfoApplication/afo-backend
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Environment Configuration
Copy the example environment file and configure it:
```bash
cp .env.example .env
```

Edit the `.env` file with your configuration:
```env
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/afo-chat
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
EMAIL_FROM=noreply@afochat.com
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
FRONTEND_URL=http://localhost:8080
```

### 4. Database Setup
Ensure MongoDB is running locally or configure a cloud MongoDB URI in your `.env` file.

## Running the Server

### Development Mode
```bash
npm run dev
```
This starts the server with nodemon for auto-reloading on file changes.

### Production Mode
```bash
npm run build
npm start
```

### Build Only
```bash
npm run build
```

## API Endpoints

### Health Check
- **GET** `/health` - Server health status

### Authentication
- **POST** `/api/auth/register` - User registration
- **POST** `/api/auth/login` - User login
- **POST** `/api/auth/logout` - User logout
- **POST** `/api/auth/refresh` - Refresh access token
- **POST** `/api/auth/forgot-password` - Request password reset
- **POST** `/api/auth/reset-password` - Reset password with token
- **POST** `/api/auth/verify-email` - Verify email address
- **POST** `/api/auth/resend-verification` - Resend verification email

### Chat Management
- **GET** `/api/chats` - Get user's chats
- **POST** `/api/chats` - Create new chat
- **GET** `/api/chats/:chatId` - Get specific chat
- **PUT** `/api/chats/:chatId` - Update chat
- **DELETE** `/api/chats/:chatId` - Delete chat
- **POST** `/api/chats/:chatId/participants` - Add participants
- **DELETE** `/api/chats/:chatId/participants/:userId` - Remove participant
- **POST** `/api/chats/:chatId/messages` - Send message
- **GET** `/api/chats/:chatId/messages` - Get chat messages
- **PUT** `/api/chats/:chatId/messages/:messageId` - Edit message
- **DELETE** `/api/chats/:chatId/messages/:messageId` - Delete message
- **POST** `/api/chats/:chatId/messages/:messageId/reactions` - Add reaction
- **POST** `/api/chats/:chatId/upload` - Upload file

## Socket.IO Events

### Connection Events
- `connection` - User connects
- `disconnect` - User disconnects
- `error` - Connection error

### Authentication
- `authenticate` - Authenticate socket connection

### Messaging
- `join_chat` - Join chat room
- `leave_chat` - Leave chat room
- `send_message` - Send message
- `message_sent` - Message confirmation
- `new_message` - Receive new message
- `edit_message` - Edit message
- `message_edited` - Message edit confirmation
- `delete_message` - Delete message
- `message_deleted` - Message deletion confirmation
- `add_reaction` - Add reaction to message
- `reaction_added` - Reaction confirmation

### Typing Indicators
- `typing_start` - User starts typing
- `typing_stop` - User stops typing
- `user_typing` - Broadcast typing status

### User Presence
- `user_online` - User comes online
- `user_offline` - User goes offline
- `get_online_users` - Get list of online users

### WebRTC Signaling
- `webrtc_offer` - Send WebRTC offer
- `webrtc_answer` - Send WebRTC answer
- `webrtc_ice_candidate` - Send ICE candidate
- `webrtc_hang_up` - End call

## Database Models

### User Model
```typescript
interface IUser {
  username: string;
  email: string;
  password: string;
  displayName: string;
  avatar?: string;
  bio?: string;
  isEmailVerified: boolean;
  isActive: boolean;
  status: 'online' | 'offline' | 'away' | 'busy';
  lastLoginAt?: Date;
  preferences: {
    notifications: boolean;
    soundEnabled: boolean;
    theme: 'light' | 'dark' | 'auto';
  };
  refreshTokens: Array<{
    token: string;
    expiresAt: Date;
  }>;
}
```

### Chat Model
```typescript
interface IChat {
  type: 'direct' | 'group';
  name?: string;
  description?: string;
  avatar?: string;
  participants: Array<{
    user: ObjectId;
    role: 'admin' | 'member';
    joinedAt: Date;
    hasLeft: boolean;
    isActive: boolean;
  }>;
  lastMessage?: ObjectId;
  isActive: boolean;
}
```

### Message Model
```typescript
interface IMessage {
  chat: ObjectId;
  sender: ObjectId;
  content: string;
  type: 'text' | 'image' | 'file' | 'audio' | 'video' | 'system';
  fileUrl?: string;
  fileMetadata?: {
    filename: string;
    size: number;
    mimeType: string;
  };
  reactions: Array<{
    user: ObjectId;
    emoji: string;
  }>;
  editHistory: Array<{
    content: string;
    editedAt: Date;
  }>;
  tempId?: string;
  isEdited: boolean;
  isDeleted: boolean;
  replyTo?: ObjectId;
  readBy: Array<{
    user: ObjectId;
    readAt: Date;
  }>;
}
```

## Security Features
- JWT authentication with access and refresh tokens
- Password hashing with bcrypt
- CORS protection
- Helmet security headers
- Rate limiting
- Input validation and sanitization
- File upload restrictions
- XSS protection

## File Upload
- Supports multiple file types
- File size limits
- Virus scanning integration
- Secure file storage
- Metadata tracking

## Email Service
- User registration verification
- Password reset emails
- Customizable email templates
- SMTP configuration

## Development Notes

### TypeScript Compilation
The project was initially configured with strict TypeScript settings but has been adjusted for development flexibility. Key fixes included:
- JWT token generation type casting
- MongoDB ObjectId type handling
- Environment variable type assertions
- Missing interface method definitions

### Database Warnings
You may see warnings about duplicate schema indexes. These are non-critical and don't affect functionality:
```
Warning: Duplicate schema index on {"email":1} found
Warning: Duplicate schema index on {"username":1} found
```

### Server Startup
When the server starts successfully, you'll see:
```
🚀 AFO Backend Server is running on port 3000
📊 Environment: development
🏥 Health check: http://localhost:3000/health
⚡ Socket.IO ready for real-time connections
🔧 API Base URL: http://localhost:3000/api
🔐 Auth endpoints: http://localhost:3000/api/auth
💬 Chat endpoints: http://localhost:3000/api/chats
```

## Troubleshooting

### Common Issues
1. **MongoDB Connection Error**: Ensure MongoDB is running and the URI is correct
2. **Port Already in Use**: Change the PORT in .env or kill the process using port 3000
3. **TypeScript Errors**: Run `npm run build` to check for compilation issues
4. **Authentication Issues**: Verify JWT secrets are set in .env

### Logs
The server provides detailed logging for:
- Database connections
- Authentication attempts
- Socket.IO events
- API requests
- Error handling

## Integration with Flutter Frontend
The backend is designed to work seamlessly with the Flutter AFO chat application:
- CORS configured for Flutter web
- Socket.IO compatible with Flutter socket_io_client
- RESTful APIs match Flutter service expectations
- File upload endpoints support Flutter file picker

## Next Steps
1. Configure MongoDB with proper credentials
2. Set up email service with valid SMTP settings
3. Generate secure JWT secrets for production
4. Configure file storage (local or cloud)
5. Set up SSL/TLS for production deployment
6. Configure environment-specific settings

## Support
For issues or questions, refer to the source code comments or check the server logs for detailed error information.