# AFO Chat Backend

A comprehensive Node.js/Express backend for the AFO (Afaan Oromoo) Chat Application with real-time messaging capabilities.

## Features

### 🔐 Authentication & Security
- JWT-based authentication with access and refresh tokens
- Password hashing with bcryptjs
- Rate limiting and security middleware
- User registration, login, logout, and password reset

### 💬 Real-time Messaging
- Socket.IO for real-time communication
- Direct and group chats
- Message reactions, editing, and deletion
- Typing indicators and read receipts
- User online/offline status

### 📊 Database Models
- **User Model**: Complete user management with profiles, preferences, and security
- **Chat Model**: Support for both direct and group conversations
- **Message Model**: Rich messaging with media, reactions, and threading
- **FileUpload Model**: File attachment management with metadata

### 🌐 API Endpoints

#### Authentication Routes (`/api/auth`)
- `POST /register` - User registration
- `POST /login` - User login
- `POST /refresh` - Refresh access token
- `POST /logout` - User logout
- `POST /logout-all` - Logout from all devices
- `POST /forgot-password` - Request password reset
- `POST /reset-password` - Reset password with token
- `GET /me` - Get current user profile

#### Chat Routes (`/api/chats`)
- `GET /` - Get user's chats
- `GET /:chatId` - Get specific chat details
- `POST /` - Create new chat
- `PUT /:chatId` - Update chat details (groups only)
- `POST /:chatId/participants` - Add participants to group chat
- `POST /:chatId/leave` - Leave chat
- `GET /:chatId/messages` - Get chat messages
- `POST /:chatId/messages` - Send message

### 🔌 Socket.IO Events

#### Connection Events
- `user:connected` - User comes online
- `user:status_changed` - User online/offline status updates

#### Chat Events
- `chat:join` - Join chat room
- `chat:leave` - Leave chat room
- `chat:mark_read` - Mark messages as read

#### Message Events
- `message:send` - Send new message
- `message:new` - Receive new message
- `message:edit` - Edit existing message
- `message:delete` - Delete message
- `message:react` - Add/remove reaction

#### Typing Events
- `typing:start` - User starts typing
- `typing:stop` - User stops typing

#### Call Events (WebRTC Support)
- `call:initiate` - Start voice/video call
- `call:accept` - Accept incoming call
- `call:reject` - Reject incoming call
- `call:end` - End active call
- `webrtc:offer` - WebRTC offer signaling
- `webrtc:answer` - WebRTC answer signaling
- `webrtc:ice-candidate` - ICE candidate exchange

## 🛠️ Technology Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: MongoDB with Mongoose ODM
- **Real-time**: Socket.IO
- **Authentication**: JWT (JSON Web Tokens)
- **Security**: Helmet, CORS, Rate Limiting
- **Email**: Nodemailer
- **File Upload**: Multer
- **Validation**: express-validator

## 📁 Project Structure

```
src/
├── models/           # Database models
│   ├── User.ts      # User model with authentication
│   ├── Chat.ts      # Chat room model
│   ├── Message.ts   # Message model with reactions
│   ├── FileUpload.ts # File attachment model
│   └── index.ts     # Model exports
├── routes/          # API route handlers
│   ├── auth.ts      # Authentication routes
│   └── chat.ts      # Chat and messaging routes
├── socket/          # Socket.IO event handlers
│   └── socketHandler.ts # Real-time communication logic
├── middleware/      # Express middleware
│   └── auth.ts      # Authentication middleware
├── utils/           # Utility functions
│   └── emailService.ts # Email sending service
├── database.ts      # MongoDB connection
├── server.ts        # Main server class
└── index.ts         # Application entry point
```

## 🚀 Getting Started

### Prerequisites
- Node.js (v16 or higher)
- MongoDB (local or cloud instance)
- npm or yarn

### Installation

1. Navigate to the backend directory:
   ```bash
   cd afo-backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create environment file:
   ```bash
   cp .env.example .env
   ```

4. Configure environment variables in `.env`:
   ```
   MONGODB_URI=mongodb://localhost:27017/afo_chat
   JWT_SECRET=your-super-secret-jwt-key
   JWT_REFRESH_SECRET=your-refresh-secret-key
   JWT_EXPIRES_IN=15m
   JWT_REFRESH_EXPIRES_IN=7d
   PORT=5000
   NODE_ENV=development
   FRONTEND_URL=http://localhost:3000
   EMAIL_SERVICE=gmail
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASSWORD=your-app-password
   EMAIL_FROM=AFO Chat <noreply@afochat.com>
   ```

### Development

1. Start development server:
   ```bash
   npm run dev
   ```

2. Build for production:
   ```bash
   npm run build
   ```

3. Start production server:
   ```bash
   npm start
   ```

## 📡 API Documentation

The server provides a comprehensive REST API with the following base URL: `http://localhost:5000/api`

### Health Check
- **GET** `/health` - Server health status

### Authentication Required
Most endpoints require authentication via Bearer token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## 🔧 Configuration

### Environment Variables
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret for access tokens
- `JWT_REFRESH_SECRET` - Secret for refresh tokens
- `PORT` - Server port (default: 5000)
- `NODE_ENV` - Environment (development/production)
- `FRONTEND_URL` - Frontend application URL for CORS
- `EMAIL_*` - Email service configuration

### Security Features
- Helmet for security headers
- CORS configuration
- Rate limiting (100 requests per 15 minutes)
- JWT token expiration
- Password strength validation
- Input sanitization and validation

## 🚀 Deployment

The backend is designed to be deployed on cloud platforms like:
- Heroku
- AWS (EC2, ECS, Lambda)
- Google Cloud Platform
- DigitalOcean
- Vercel (for serverless)

### Docker Support
A Dockerfile can be added for containerized deployment.

## 🧪 Testing

```bash
# Run tests
npm test

# Run tests in watch mode
npm run test:watch
```

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🤝 Support

For support and questions, please open an issue in the repository or contact the development team.

---

Built with ❤️ for the Afaan Oromoo community