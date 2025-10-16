# API Routes Documentation

## Overview
The AFO backend provides comprehensive RESTful API endpoints for authentication, user management, and chat functionality. All endpoints follow REST conventions and include proper error handling, validation, and security measures.

---

## Authentication Routes (auth.ts)

### Base URL: `/api/auth`

#### Security Features
- Rate limiting per endpoint
- Input validation with express-validator
- Password strength requirements
- Email verification system
- JWT token management

---

### POST /api/auth/register

#### Purpose
Register a new user account with email verification.

#### Request Body
```typescript
{
  "username": "string",     // 3-30 chars, alphanumeric + underscore
  "email": "string",        // Valid email format
  "password": "string",     // Min 8 chars, must include uppercase, lowercase, number
  "displayName": "string"   // 1-50 chars, display name for the user
}
```

#### Validation Rules
```typescript
const registerValidation = [
  body('username')
    .isLength({ min: 3, max: 30 })
    .withMessage('Username must be between 3 and 30 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores'),
  
  body('email')
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail(),
  
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
  
  body('displayName')
    .isLength({ min: 1, max: 50 })
    .withMessage('Display name must be between 1 and 50 characters')
    .trim()
];
```

#### Response (201 Created)
```typescript
{
  "message": "User registered successfully. Please check your email for verification.",
  "user": {
    "_id": "user_id",
    "username": "johndoe",
    "email": "john@example.com",
    "displayName": "John Doe",
    "isEmailVerified": false,
    "isActive": true,
    "role": "user",
    "preferences": {
      "language": "en",
      "notifications": {
        "messages": true,
        "calls": true,
        "groups": true
      },
      "privacy": {
        "showOnlineStatus": true,
        "showLastSeen": true
      }
    },
    "createdAt": "2023-10-15T10:30:00.000Z"
  },
  "tokens": {
    "accessToken": "jwt_access_token",
    "refreshToken": "jwt_refresh_token"
  }
}
```

#### Error Responses
- **400 Bad Request**: Validation errors, duplicate username/email
- **429 Too Many Requests**: Rate limit exceeded (10 requests/15 minutes)
- **500 Internal Server Error**: Server error

#### Rate Limiting
- **Limit**: 10 requests per 15 minutes per IP
- **Reset**: Window resets every 15 minutes

---

### POST /api/auth/login

#### Purpose
Authenticate user and return JWT tokens.

#### Request Body
```typescript
{
  "login": "string",        // Username or email
  "password": "string"      // User password
}
```

#### Validation Rules
```typescript
const loginValidation = [
  body('login')
    .notEmpty()
    .withMessage('Username or email is required'),
  
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];
```

#### Response (200 OK)
```typescript
{
  "message": "Login successful",
  "user": {
    "_id": "user_id",
    "username": "johndoe",
    "email": "john@example.com",
    "displayName": "John Doe",
    "avatar": "avatar_url",
    "isEmailVerified": true,
    "status": {
      "isOnline": true,
      "lastSeen": "2023-10-15T10:30:00.000Z"
    },
    "role": "user",
    "preferences": { /* user preferences */ },
    "lastLoginAt": "2023-10-15T10:30:00.000Z"
  },
  "tokens": {
    "accessToken": "jwt_access_token",
    "refreshToken": "jwt_refresh_token"
  }
}
```

#### Error Responses
- **400 Bad Request**: Validation errors
- **401 Unauthorized**: Invalid credentials, unverified email, inactive account
- **429 Too Many Requests**: Rate limit exceeded

---

### POST /api/auth/logout

#### Purpose
Logout user and invalidate refresh token.

#### Authentication
- **Required**: Yes (Bearer token in Authorization header)

#### Request Body
```typescript
{
  "refreshToken": "string"  // Optional: specific refresh token to invalidate
}
```

#### Response (200 OK)
```typescript
{
  "message": "Logout successful"
}
```

#### Behavior
- Removes specified refresh token from user's active tokens
- If no refresh token provided, removes all refresh tokens
- Updates user's online status to offline

---

### POST /api/auth/refresh

#### Purpose
Refresh access token using refresh token.

#### Request Body
```typescript
{
  "refreshToken": "string"  // Valid refresh token
}
```

#### Response (200 OK)
```typescript
{
  "accessToken": "new_jwt_access_token",
  "refreshToken": "new_jwt_refresh_token"  // Optional: token rotation
}
```

#### Error Responses
- **400 Bad Request**: Missing refresh token
- **401 Unauthorized**: Invalid or expired refresh token

#### Security Features
- Refresh token rotation (optional)
- Automatic cleanup of expired tokens
- Single-use refresh tokens (if rotation enabled)

---

### POST /api/auth/forgot-password

#### Purpose
Request password reset email.

#### Request Body
```typescript
{
  "email": "string"  // Registered email address
}
```

#### Validation Rules
```typescript
const forgotPasswordValidation = [
  body('email')
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail()
];
```

#### Response (200 OK)
```typescript
{
  "message": "If an account with that email exists, a password reset link has been sent."
}
```

#### Rate Limiting
- **Limit**: 3 requests per hour per IP
- **Security**: Always returns success message to prevent email enumeration

#### Email Content
- Password reset link with unique token
- Token expiration (1 hour)
- Security instructions

---

### POST /api/auth/reset-password

#### Purpose
Reset password using reset token.

#### Request Body
```typescript
{
  "token": "string",        // Password reset token from email
  "newPassword": "string"   // New password meeting requirements
}
```

#### Validation Rules
```typescript
const resetPasswordValidation = [
  body('token')
    .notEmpty()
    .withMessage('Reset token is required'),
  
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number')
];
```

#### Response (200 OK)
```typescript
{
  "message": "Password reset successful"
}
```

#### Error Responses
- **400 Bad Request**: Invalid or expired token, validation errors
- **404 Not Found**: Token not found

#### Security Features
- Token expiration (1 hour)
- Single-use tokens
- Password strength validation
- Automatic token cleanup

---

### POST /api/auth/verify-email

#### Purpose
Verify user email address.

#### Request Body
```typescript
{
  "token": "string"  // Email verification token
}
```

#### Response (200 OK)
```typescript
{
  "message": "Email verified successfully",
  "user": {
    "_id": "user_id",
    "isEmailVerified": true,
    // ... other user data
  }
}
```

#### Error Responses
- **400 Bad Request**: Invalid or expired token
- **404 Not Found**: Token not found

---

### POST /api/auth/resend-verification

#### Purpose
Resend email verification email.

#### Request Body
```typescript
{
  "email": "string"  // Registered email address
}
```

#### Response (200 OK)
```typescript
{
  "message": "Verification email sent successfully"
}
```

#### Rate Limiting
- **Limit**: 3 requests per hour per IP

---

## Chat Routes (chat.ts)

### Base URL: `/api/chats`

#### Authentication
All chat endpoints require authentication (Bearer token).

---

### GET /api/chats

#### Purpose
Get list of user's chats with pagination and filtering.

#### Query Parameters
```typescript
{
  "limit": "number",      // Default: 20, Max: 100
  "offset": "number",     // Default: 0
  "type": "string",       // Optional: "direct" | "group"
  "search": "string"      // Optional: Search chat names/participants
}
```

#### Response (200 OK)
```typescript
{
  "chats": [
    {
      "_id": "chat_id",
      "type": "group",
      "name": "Project Team",
      "description": "Team collaboration chat",
      "avatar": "avatar_url",
      "participants": [
        {
          "user": {
            "_id": "user_id",
            "username": "johndoe",
            "displayName": "John Doe",
            "avatar": "avatar_url"
          },
          "role": "admin",
          "joinedAt": "2023-10-15T10:30:00.000Z",
          "isActive": true,
          "lastReadMessageId": "message_id"
        }
      ],
      "lastMessage": {
        "_id": "message_id",
        "content": "Hello everyone!",
        "sender": {
          "_id": "user_id",
          "username": "johndoe",
          "displayName": "John Doe"
        },
        "type": "text",
        "createdAt": "2023-10-15T11:00:00.000Z"
      },
      "lastActivity": "2023-10-15T11:00:00.000Z",
      "unreadCount": 5,
      "createdAt": "2023-10-15T10:30:00.000Z"
    }
  ],
  "pagination": {
    "total": 15,
    "limit": 20,
    "offset": 0,
    "hasMore": false
  }
}
```

---

### POST /api/chats

#### Purpose
Create a new chat (direct or group).

#### Request Body

##### Direct Chat
```typescript
{
  "type": "direct",
  "participantId": "user_id"  // ID of the other participant
}
```

##### Group Chat
```typescript
{
  "type": "group",
  "name": "string",           // Chat name (required for groups)
  "description": "string",    // Optional description
  "participantIds": ["user_id1", "user_id2"]  // Array of participant IDs
}
```

#### Validation Rules
```typescript
const createChatValidation = [
  body('type')
    .isIn(['direct', 'group'])
    .withMessage('Chat type must be either "direct" or "group"'),
  
  body('name')
    .if(body('type').equals('group'))
    .notEmpty()
    .withMessage('Group chat name is required')
    .isLength({ min: 1, max: 100 })
    .withMessage('Chat name must be between 1 and 100 characters'),
  
  body('participantIds')
    .if(body('type').equals('group'))
    .isArray({ min: 1 })
    .withMessage('At least one participant is required for group chats'),
  
  body('participantId')
    .if(body('type').equals('direct'))
    .notEmpty()
    .withMessage('Participant ID is required for direct chats')
];
```

#### Response (201 Created)
```typescript
{
  "message": "Chat created successfully",
  "chat": {
    "_id": "chat_id",
    "type": "group",
    "name": "Project Team",
    "description": "Team collaboration chat",
    "participants": [
      {
        "user": "user_id",
        "role": "admin",
        "joinedAt": "2023-10-15T10:30:00.000Z",
        "isActive": true
      }
    ],
    "createdBy": "user_id",
    "createdAt": "2023-10-15T10:30:00.000Z"
  }
}
```

#### Error Responses
- **400 Bad Request**: Validation errors, duplicate direct chat
- **404 Not Found**: Participant not found
- **403 Forbidden**: Cannot create chat with blocked users

---

### GET /api/chats/:chatId

#### Purpose
Get specific chat details with participants and recent messages.

#### Path Parameters
- `chatId`: MongoDB ObjectId of the chat

#### Query Parameters
```typescript
{
  "includeMessages": "boolean",    // Default: false
  "messageLimit": "number"         // Default: 50, Max: 100
}
```

#### Response (200 OK)
```typescript
{
  "chat": {
    "_id": "chat_id",
    "type": "group",
    "name": "Project Team",
    "description": "Team collaboration chat",
    "avatar": "avatar_url",
    "participants": [
      {
        "user": {
          "_id": "user_id",
          "username": "johndoe",
          "displayName": "John Doe",
          "avatar": "avatar_url",
          "status": {
            "isOnline": true,
            "lastSeen": "2023-10-15T11:30:00.000Z"
          }
        },
        "role": "admin",
        "joinedAt": "2023-10-15T10:30:00.000Z",
        "isActive": true,
        "lastReadMessageId": "message_id",
        "notifications": true
      }
    ],
    "settings": {
      "allowInvites": true,
      "muteNotifications": false,
      "disappearingMessages": {
        "enabled": false,
        "duration": 86400000
      }
    },
    "createdBy": "user_id",
    "createdAt": "2023-10-15T10:30:00.000Z"
  },
  "messages": [
    // Array of recent messages (if includeMessages=true)
  ]
}
```

#### Error Responses
- **404 Not Found**: Chat not found
- **403 Forbidden**: User not a participant

---

### PUT /api/chats/:chatId

#### Purpose
Update chat settings (admin only for groups).

#### Request Body
```typescript
{
  "name": "string",           // Optional: New chat name
  "description": "string",    // Optional: New description
  "avatar": "string",         // Optional: New avatar URL
  "settings": {
    "allowInvites": "boolean",
    "muteNotifications": "boolean",
    "disappearingMessages": {
      "enabled": "boolean",
      "duration": "number"
    }
  }
}
```

#### Authorization
- **Direct Chats**: Any participant can update settings
- **Group Chats**: Only admins can update name, description, avatar
- **Personal Settings**: Any participant can update their notification preferences

#### Response (200 OK)
```typescript
{
  "message": "Chat updated successfully",
  "chat": {
    // Updated chat object
  }
}
```

---

### DELETE /api/chats/:chatId

#### Purpose
Delete chat (admin) or leave chat (member).

#### Behavior
- **Admin in Group**: Deletes entire chat for all participants
- **Member in Group**: Removes user from participants
- **Direct Chat**: Marks chat as inactive for the user

#### Response (200 OK)
```typescript
{
  "message": "Left chat successfully"  // or "Chat deleted successfully"
}
```

---

### POST /api/chats/:chatId/participants

#### Purpose
Add participants to group chat (admin only).

#### Request Body
```typescript
{
  "userIds": ["user_id1", "user_id2"],  // Array of user IDs to add
  "role": "member"                       // Optional: Default role for new participants
}
```

#### Response (200 OK)
```typescript
{
  "message": "Participants added successfully",
  "addedUsers": [
    {
      "_id": "user_id",
      "username": "newuser",
      "displayName": "New User"
    }
  ]
}
```

---

### DELETE /api/chats/:chatId/participants/:userId

#### Purpose
Remove participant from group chat.

#### Authorization
- **Admin**: Can remove any participant
- **Self**: Can remove themselves (leave chat)

#### Response (200 OK)
```typescript
{
  "message": "Participant removed successfully"
}
```

---

### GET /api/chats/:chatId/messages

#### Purpose
Get chat messages with pagination.

#### Query Parameters
```typescript
{
  "limit": "number",        // Default: 50, Max: 100
  "offset": "number",       // Default: 0
  "before": "string",       // Message ID: Get messages before this message
  "after": "string",        // Message ID: Get messages after this message
  "search": "string"        // Search message content
}
```

#### Response (200 OK)
```typescript
{
  "messages": [
    {
      "_id": "message_id",
      "chat": "chat_id",
      "sender": {
        "_id": "user_id",
        "username": "johndoe",
        "displayName": "John Doe",
        "avatar": "avatar_url"
      },
      "content": "Hello everyone!",
      "type": "text",
      "reactions": [
        {
          "user": "user_id",
          "emoji": "👍",
          "createdAt": "2023-10-15T11:05:00.000Z"
        }
      ],
      "readBy": [
        {
          "user": "user_id",
          "readAt": "2023-10-15T11:10:00.000Z"
        }
      ],
      "isEdited": false,
      "isDeleted": false,
      "createdAt": "2023-10-15T11:00:00.000Z",
      "updatedAt": "2023-10-15T11:00:00.000Z"
    }
  ],
  "pagination": {
    "total": 150,
    "limit": 50,
    "offset": 0,
    "hasMore": true
  }
}
```

---

### POST /api/chats/:chatId/messages

#### Purpose
Send a new message to the chat.

#### Request Body

##### Text Message
```typescript
{
  "content": "string",        // Message content
  "type": "text",            // Default: "text"
  "replyTo": "message_id",   // Optional: Reply to message ID
  "tempId": "string"         // Optional: Client-generated temporary ID
}
```

##### File Message (multipart/form-data)
```typescript
{
  "file": File,              // File upload
  "type": "image|file|audio|video",
  "content": "string",       // Optional caption
  "replyTo": "message_id",   // Optional
  "tempId": "string"         // Optional
}
```

#### File Upload Validation
- **Max Size**: 50MB
- **Allowed Types**: 
  - Images: JPEG, PNG, GIF, WebP
  - Documents: PDF, TXT
  - Audio: MP3, WAV, OGG
  - Video: MP4, WebM

#### Response (201 Created)
```typescript
{
  "message": "Message sent successfully",
  "data": {
    "_id": "message_id",
    "chat": "chat_id",
    "sender": {
      "_id": "user_id",
      "username": "johndoe",
      "displayName": "John Doe",
      "avatar": "avatar_url"
    },
    "content": "Hello everyone!",
    "type": "text",
    "tempId": "temp_123",
    "createdAt": "2023-10-15T11:00:00.000Z"
  }
}
```

---

### PUT /api/chats/:chatId/messages/:messageId

#### Purpose
Edit an existing message (sender only).

#### Request Body
```typescript
{
  "content": "string"  // New message content
}
```

#### Restrictions
- Only message sender can edit
- Edit time limit: 24 hours after sending
- Cannot edit deleted messages
- File messages cannot be edited (content only)

#### Response (200 OK)
```typescript
{
  "message": "Message updated successfully",
  "data": {
    "_id": "message_id",
    "content": "Updated message content",
    "isEdited": true,
    "editHistory": [
      {
        "content": "Original content",
        "editedAt": "2023-10-15T11:00:00.000Z"
      }
    ],
    "updatedAt": "2023-10-15T11:30:00.000Z"
  }
}
```

---

### DELETE /api/chats/:chatId/messages/:messageId

#### Purpose
Delete a message (soft delete).

#### Authorization
- **Message Sender**: Can delete their own messages
- **Chat Admin**: Can delete any message in group chats

#### Response (200 OK)
```typescript
{
  "message": "Message deleted successfully"
}
```

#### Behavior
- **Soft Delete**: Message marked as deleted but preserved in database
- **Content Replacement**: Message content replaced with "Message deleted"
- **File Cleanup**: Associated files marked for deletion

---

### POST /api/chats/:chatId/messages/:messageId/reactions

#### Purpose
Add or remove reaction to a message.

#### Request Body
```typescript
{
  "emoji": "string"  // Emoji character (Unicode)
}
```

#### Validation
- Valid Unicode emoji characters only
- Single emoji per request

#### Response (200 OK)
```typescript
{
  "message": "Reaction added successfully",  // or "Reaction removed successfully"
  "data": {
    "messageId": "message_id",
    "userId": "user_id",
    "emoji": "👍",
    "action": "added"  // or "removed"
  }
}
```

#### Behavior
- **Toggle**: Adding same emoji removes existing reaction
- **Multiple Reactions**: Users can have multiple different emoji reactions
- **Real-time**: Reaction changes broadcast via Socket.IO

---

### POST /api/chats/:chatId/upload

#### Purpose
Upload files for chat messages.

#### Request (multipart/form-data)
```typescript
{
  "file": File,              // File to upload
  "messageContent": "string" // Optional: Message content/caption
}
```

#### Response (201 Created)
```typescript
{
  "message": "File uploaded successfully",
  "data": {
    "fileId": "file_id",
    "filename": "document.pdf",
    "originalName": "My Document.pdf",
    "mimeType": "application/pdf",
    "size": 1024000,
    "url": "/uploads/files/document.pdf",
    "metadata": {
      "dimensions": {      // For images/videos
        "width": 1920,
        "height": 1080
      },
      "duration": 120      // For audio/video (seconds)
    }
  }
}
```

---

## Error Handling

### Standard Error Response Format
```typescript
{
  "error": {
    "message": "string",         // Human-readable error message
    "code": "string",           // Error code for client handling
    "details": "object",        // Additional error details
    "timestamp": "string",      // ISO timestamp
    "path": "string"           // API endpoint path
  }
}
```

### Common HTTP Status Codes
- **200 OK**: Successful request
- **201 Created**: Resource created successfully
- **400 Bad Request**: Validation errors, malformed request
- **401 Unauthorized**: Authentication required or failed
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **409 Conflict**: Resource conflict (e.g., duplicate)
- **422 Unprocessable Entity**: Validation errors
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Unexpected server error

### Rate Limiting Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1634567890
```

This comprehensive API documentation covers all endpoints, request/response formats, validation rules, and error handling for the AFO chat application backend.