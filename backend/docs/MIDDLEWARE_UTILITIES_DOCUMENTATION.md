# Middleware and Utilities Documentation

## Overview
This document provides comprehensive documentation for the middleware components and utility functions that support the AFO backend infrastructure.

---

## Authentication Middleware (middleware/auth.ts)

### Purpose
Provides JWT-based authentication and authorization for API endpoints.

### Functions

#### auth(req, res, next)
**Purpose**: Verify JWT access token and authenticate requests

```typescript
export const auth = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        error: 'No token provided, authorization denied' 
      });
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JWTPayload;
    
    if (decoded.type !== 'access') {
      return res.status(401).json({ 
        error: 'Invalid token type' 
      });
    }
    
    const user = await User.findById(decoded.userId).select('-password');
    
    if (!user || !user.isActive) {
      return res.status(401).json({ 
        error: 'User not found or inactive' 
      });
    }
    
    req.user = user;
    req.userId = user._id.toString();
    next();
    
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      return res.status(401).json({ 
        error: 'Invalid token' 
      });
    }
    
    if (error instanceof jwt.TokenExpiredError) {
      return res.status(401).json({ 
        error: 'Token expired' 
      });
    }
    
    res.status(500).json({ 
      error: 'Authentication error' 
    });
  }
};
```

**Features**:
- Bearer token extraction from Authorization header
- JWT signature verification with secret
- Token type validation (access vs refresh)
- User existence and status verification
- Request context enrichment with user data
- Comprehensive error handling

**Usage Example**:
```typescript
router.get('/protected-route', auth, (req: AuthenticatedRequest, res) => {
  res.json({ 
    message: `Hello ${req.user.username}`,
    userId: req.userId 
  });
});
```

---

#### optionalAuth(req, res, next)
**Purpose**: Optional authentication - continues without error if no token provided

```typescript
export const optionalAuth = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return next(); // Continue without authentication
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JWTPayload;
    
    if (decoded.type === 'access') {
      const user = await User.findById(decoded.userId).select('-password');
      
      if (user && user.isActive) {
        req.user = user;
        req.userId = user._id.toString();
      }
    }
    
    next();
    
  } catch (error) {
    // Ignore authentication errors for optional auth
    next();
  }
};
```

**Use Cases**:
- Public endpoints that enhance experience for authenticated users
- Content that varies based on authentication status
- Analytics and tracking with optional user context

---

#### requireRole(role)
**Purpose**: Role-based authorization middleware factory

```typescript
export const requireRole = (role: 'admin' | 'moderator' | 'user') => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ 
        error: 'Authentication required' 
      });
    }
    
    const roleHierarchy = {
      'user': 1,
      'moderator': 2,
      'admin': 3
    };
    
    const userRole = roleHierarchy[req.user.role] || 0;
    const requiredRole = roleHierarchy[role] || 0;
    
    if (userRole < requiredRole) {
      return res.status(403).json({ 
        error: 'Insufficient permissions' 
      });
    }
    
    next();
  };
};
```

**Features**:
- Hierarchical role system (admin > moderator > user)
- Middleware factory pattern for reusability
- Clear permission error messages

**Usage Example**:
```typescript
router.delete('/admin-only', auth, requireRole('admin'), adminHandler);
router.post('/moderator-action', auth, requireRole('moderator'), modHandler);
```

---

#### Extended Request Interface
```typescript
interface AuthenticatedRequest extends Request {
  user?: IUser;
  userId?: string;
}

interface JWTPayload {
  userId: string;
  type: 'access' | 'refresh';
  iat: number;
  exp: number;
}
```

---

## Email Service (utils/emailService.ts)

### Purpose
Provides email notification functionality for user communication and system notifications.

### Configuration

#### SMTP Setup
```typescript
const transporter = nodemailer.createTransporter({
  host: process.env.EMAIL_HOST,
  port: parseInt(process.env.EMAIL_PORT || '587'),
  secure: process.env.EMAIL_PORT === '465', // SSL for port 465
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  },
  tls: {
    rejectUnauthorized: false // For development only
  }
});
```

**Supported Providers**:
- Gmail (smtp.gmail.com:587)
- SendGrid (smtp.sendgrid.net:587)
- Mailgun (smtp.mailgun.org:587)
- Custom SMTP servers

---

### Core Functions

#### sendEmail(to, subject, html, text?)
**Purpose**: Generic email sending function

```typescript
export const sendEmail = async (
  to: string,
  subject: string,
  html: string,
  text?: string
): Promise<void> => {
  try {
    const mailOptions = {
      from: `"AFO Chat" <${process.env.EMAIL_FROM}>`,
      to,
      subject,
      html,
      text: text || html.replace(/<[^>]*>/g, '') // Strip HTML for text version
    };
    
    const info = await transporter.sendMail(mailOptions);
    
    console.log('Email sent successfully:', {
      messageId: info.messageId,
      to,
      subject
    });
    
  } catch (error) {
    console.error('Email sending failed:', error);
    throw new Error('Failed to send email');
  }
};
```

**Features**:
- HTML and plain text support
- Automatic text generation from HTML
- Error handling and logging
- Message ID tracking

---

#### sendVerificationEmail(user, token)
**Purpose**: Send email address verification

```typescript
export const sendVerificationEmail = async (user: IUser, token: string): Promise<void> => {
  const verificationUrl = `${process.env.FRONTEND_URL}/verify-email?token=${token}`;
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Verify Your Email - AFO Chat</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .button { 
          display: inline-block; 
          background: #4CAF50; 
          color: white; 
          padding: 12px 24px; 
          text-decoration: none; 
          border-radius: 4px; 
          margin: 20px 0;
        }
        .footer { text-align: center; color: #666; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Welcome to AFO Chat!</h1>
        </div>
        
        <div class="content">
          <h2>Hello ${user.displayName},</h2>
          
          <p>Thank you for registering with AFO Chat. To complete your registration, please verify your email address by clicking the button below:</p>
          
          <p style="text-align: center;">
            <a href="${verificationUrl}" class="button">Verify Email Address</a>
          </p>
          
          <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
          <p><a href="${verificationUrl}">${verificationUrl}</a></p>
          
          <p>This verification link will expire in 24 hours for security reasons.</p>
          
          <p>If you didn't create an account with AFO Chat, please ignore this email.</p>
          
          <p>Best regards,<br>The AFO Chat Team</p>
        </div>
        
        <div class="footer">
          <p>© 2023 AFO Chat. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  `;
  
  await sendEmail(
    user.email,
    'Verify Your Email Address - AFO Chat',
    html
  );
};
```

**Features**:
- Professional HTML template
- Responsive design
- Security considerations (24-hour expiration)
- Branded styling

---

#### sendPasswordResetEmail(user, token)
**Purpose**: Send password reset instructions

```typescript
export const sendPasswordResetEmail = async (user: IUser, token: string): Promise<void> => {
  const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${token}`;
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Password Reset - AFO Chat</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #f44336; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .button { 
          display: inline-block; 
          background: #f44336; 
          color: white; 
          padding: 12px 24px; 
          text-decoration: none; 
          border-radius: 4px; 
          margin: 20px 0;
        }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 4px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Password Reset Request</h1>
        </div>
        
        <div class="content">
          <h2>Hello ${user.displayName},</h2>
          
          <p>We received a request to reset your password for your AFO Chat account.</p>
          
          <p style="text-align: center;">
            <a href="${resetUrl}" class="button">Reset Password</a>
          </p>
          
          <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
          <p><a href="${resetUrl}">${resetUrl}</a></p>
          
          <div class="warning">
            <strong>Security Notice:</strong>
            <ul>
              <li>This link will expire in 1 hour</li>
              <li>If you didn't request this reset, please ignore this email</li>
              <li>Your password will remain unchanged until you create a new one</li>
            </ul>
          </div>
          
          <p>Best regards,<br>The AFO Chat Team</p>
        </div>
      </div>
    </body>
    </html>
  `;
  
  await sendEmail(
    user.email,
    'Password Reset Request - AFO Chat',
    html
  );
};
```

**Security Features**:
- 1-hour token expiration
- Clear security warnings
- Visual distinction from verification emails
- Instructions for suspicious activity

---

#### sendWelcomeEmail(user)
**Purpose**: Welcome new verified users

```typescript
export const sendWelcomeEmail = async (user: IUser): Promise<void> => {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Welcome to AFO Chat!</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #2196F3; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .feature { background: white; padding: 15px; margin: 10px 0; border-radius: 4px; }
        .button { 
          display: inline-block; 
          background: #2196F3; 
          color: white; 
          padding: 12px 24px; 
          text-decoration: none; 
          border-radius: 4px; 
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🎉 Welcome to AFO Chat!</h1>
        </div>
        
        <div class="content">
          <h2>Hello ${user.displayName},</h2>
          
          <p>Your email has been verified and your AFO Chat account is now active! You can start connecting with friends and colleagues right away.</p>
          
          <div class="feature">
            <h3>🚀 Getting Started</h3>
            <ul>
              <li>Complete your profile with a photo and bio</li>
              <li>Start or join conversations with other users</li>
              <li>Create group chats for team collaboration</li>
              <li>Share files, images, and documents</li>
            </ul>
          </div>
          
          <div class="feature">
            <h3>✨ Key Features</h3>
            <ul>
              <li><strong>Real-time Messaging:</strong> Instant message delivery</li>
              <li><strong>Voice & Video Calls:</strong> High-quality communication</li>
              <li><strong>File Sharing:</strong> Share documents and media</li>
              <li><strong>Group Chats:</strong> Collaborate with teams</li>
              <li><strong>Message Reactions:</strong> Express yourself with emojis</li>
            </ul>
          </div>
          
          <p style="text-align: center;">
            <a href="${process.env.FRONTEND_URL}" class="button">Start Chatting</a>
          </p>
          
          <p>If you have any questions or need help, feel free to contact our support team.</p>
          
          <p>Happy chatting!<br>The AFO Chat Team</p>
        </div>
      </div>
    </body>
    </html>
  `;
  
  await sendEmail(
    user.email,
    'Welcome to AFO Chat - Let\'s Get Started!',
    html
  );
};
```

**Features**:
- Onboarding guidance
- Feature highlights
- Call-to-action buttons
- Support information

---

### Email Templates

#### Base Template Structure
```typescript
interface EmailTemplate {
  subject: string;
  html: string;
  text?: string;
  variables?: Record<string, string>;
}

const generateTemplate = (
  template: string, 
  variables: Record<string, string>
): string => {
  return template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
    return variables[key] || match;
  });
};
```

#### Template Variables
- `{{username}}` - User's username
- `{{displayName}}` - User's display name
- `{{email}}` - User's email address
- `{{verificationUrl}}` - Email verification link
- `{{resetUrl}}` - Password reset link
- `{{appUrl}}` - Frontend application URL

---

### Error Handling

#### Email Service Errors
```typescript
class EmailServiceError extends Error {
  constructor(message: string, public code: string) {
    super(message);
    this.name = 'EmailServiceError';
  }
}

const handleEmailError = (error: any): never => {
  if (error.code === 'EAUTH') {
    throw new EmailServiceError('SMTP authentication failed', 'AUTH_ERROR');
  }
  
  if (error.code === 'ECONNECTION') {
    throw new EmailServiceError('Failed to connect to email server', 'CONNECTION_ERROR');
  }
  
  if (error.responseCode >= 500) {
    throw new EmailServiceError('Email server error', 'SERVER_ERROR');
  }
  
  throw new EmailServiceError('Failed to send email', 'UNKNOWN_ERROR');
};
```

---

### Configuration Validation

#### Environment Variable Validation
```typescript
const validateEmailConfig = (): void => {
  const requiredVars = [
    'EMAIL_HOST',
    'EMAIL_PORT', 
    'EMAIL_USER',
    'EMAIL_PASS',
    'EMAIL_FROM'
  ];
  
  const missing = requiredVars.filter(
    varName => !process.env[varName]
  );
  
  if (missing.length > 0) {
    throw new Error(
      `Missing required email configuration: ${missing.join(', ')}`
    );
  }
};
```

---

### Testing Support

#### Email Testing Utilities
```typescript
export const createTestTransporter = () => {
  return nodemailer.createTestAccount().then(testAccount => {
    return nodemailer.createTransporter({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: {
        user: testAccount.user,
        pass: testAccount.pass
      }
    });
  });
};

export const getTestMessageUrl = (info: any): string => {
  return nodemailer.getTestMessageUrl(info);
};
```

This comprehensive middleware and utilities documentation provides detailed coverage of the authentication, authorization, and email systems that support the AFO backend application.