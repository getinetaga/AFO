# Server.ts - Express Server Documentation

## Overview
The `server.ts` file is the core of the AFO Backend application, implementing an Express.js server with comprehensive middleware, security features, and Socket.IO integration for real-time communication.

## Class: AFOBackendServer

### Purpose
Orchestrates the entire backend server infrastructure, including:
- Express application setup
- HTTP server creation
- Socket.IO real-time communication
- Middleware configuration
- Route initialization
- Database connection
- Security implementation

### Architecture

```typescript
export class AFOBackendServer {
  private app: Express;              // Express application instance
  private server: Server;            // HTTP server wrapper
  private io: SocketIOServer;        // Socket.IO server for real-time
  private socketHandler: SocketHandler; // Custom Socket.IO event handler
  private port: number;              // Server port configuration
}
```

## Constructor

### Initialization Flow
1. **Express App Creation**: Initialize Express application
2. **HTTP Server Setup**: Wrap Express app in HTTP server
3. **Socket.IO Configuration**: Setup real-time communication with CORS
4. **Port Configuration**: Set port from environment or default to 5000
5. **Component Initialization**: Call initialization methods in sequence

### Socket.IO Configuration
```typescript
this.io = new SocketIOServer(this.server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST"],
    credentials: true
  }
});
```

## Middleware Initialization

### Security Middleware

#### Helmet Configuration
```typescript
this.app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));
```

**Purpose**: Adds security headers to protect against common vulnerabilities
- XSS protection
- Content type sniffing prevention
- Frame options for clickjacking protection
- Content Security Policy implementation

#### CORS Configuration
```typescript
this.app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:3000",
  credentials: true
}));
```

**Purpose**: Configure Cross-Origin Resource Sharing
- Allow specific frontend origin
- Enable credential sharing for authentication
- Support for preflight requests

#### Rate Limiting
```typescript
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,                  // 100 requests per window
  message: 'Too many requests from this IP, please try again later'
});
```

**Purpose**: Prevent abuse and DoS attacks
- Time-based request limiting
- IP-based tracking
- Configurable error messages

### Body Parsing Middleware

```typescript
this.app.use(express.json({ limit: '50mb' }));
this.app.use(express.urlencoded({ extended: true, limit: '50mb' }));
```

**Features**:
- JSON payload parsing with 50MB limit
- URL-encoded form data support
- Large file upload support

### Performance Middleware

#### Compression
```typescript
this.app.use(compression());
```

**Purpose**: Compress HTTP responses for better performance
- Gzip compression for text responses
- Automatic content-type detection
- Configurable compression levels

#### Static File Serving
```typescript
this.app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
```

**Purpose**: Serve uploaded files efficiently
- Direct file serving without application processing
- Proper MIME type detection
- Cache headers for performance

### Logging Middleware

#### Development Logging
```typescript
if (process.env.NODE_ENV === 'development') {
  this.app.use(morgan('dev'));
} else {
  this.app.use(morgan('combined'));
}
```

**Purpose**: HTTP request logging
- Development: Concise colored output
- Production: Combined Apache format
- Request timing and status codes

## Route Initialization

### Health Check Endpoint
```typescript
this.app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0'
  });
});
```

**Purpose**: Server health monitoring
- Current status verification
- Uptime tracking
- Environment information
- Version information

### API Routes Registration
```typescript
this.app.use('/api/auth', authRoutes);
this.app.use('/api/chats', chatRoutes);
```

**Structure**:
- `/api/auth/*`: Authentication and user management
- `/api/chats/*`: Chat and messaging functionality

### Error Handling
```typescript
this.app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error('Server error:', err);
  res.status(500).json({
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});
```

**Features**:
- Global error catching
- Environment-specific error responses
- Error logging
- Consistent error format

## Database Initialization

### Connection Setup
```typescript
private async initializeDatabase(): Promise<void> {
  try {
    await connectDB();
    console.log('📊 Database connected successfully');
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    process.exit(1);
  }
}
```

**Features**:
- Asynchronous connection handling
- Error logging and process termination
- Connection status reporting

## Socket.IO Initialization

### Handler Setup
```typescript
private initializeSocketIO(): void {
  this.socketHandler = new SocketHandler(this.io);
  console.log('Socket.IO initialized with authentication and event handlers');
}
```

**Purpose**: Initialize real-time communication
- Custom event handler setup
- Authentication middleware
- Event listener registration

## Server Lifecycle Management

### Start Method
```typescript
public start(): void {
  this.server.listen(this.port, () => {
    console.log(`🚀 AFO Backend Server is running on port ${this.port}`);
    console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🏥 Health check: http://localhost:${this.port}/health`);
    console.log(`⚡ Socket.IO ready for real-time connections`);
    console.log(`🔧 API Base URL: http://localhost:${this.port}/api`);
    console.log(`🔐 Auth endpoints: http://localhost:${this.port}/api/auth`);
    console.log(`💬 Chat endpoints: http://localhost:${this.port}/api/chats`);
  });
}
```

**Features**:
- Server startup logging
- Environment information
- Endpoint documentation
- Status indicators

### Graceful Shutdown
```typescript
public async stop(): Promise<void> {
  return new Promise((resolve) => {
    console.log('SIGINT received, shutting down gracefully...');
    
    this.server.close(() => {
      console.log('HTTP server closed');
      // Close database connections
      // Close Socket.IO connections
      resolve();
    });
  });
}
```

**Features**:
- Signal handling (SIGINT, SIGTERM)
- Connection cleanup
- Database disconnection
- Graceful process termination

## Security Features

### Input Validation
- Request size limits (50MB)
- Content-type validation
- Parameter sanitization

### Authentication Integration
- JWT token verification
- Session management
- User context injection

### File Upload Security
- File type validation
- Size restrictions
- Secure storage paths
- Access control

## Performance Considerations

### Middleware Ordering
1. Security headers (Helmet)
2. CORS configuration
3. Rate limiting
4. Body parsing
5. Compression
6. Static file serving
7. Logging
8. Route handlers
9. Error handling

### Resource Management
- Connection pooling for database
- Memory-efficient file streaming
- Response compression
- Static asset caching

## Configuration Management

### Environment Variables
```typescript
const requiredEnvVars = [
  'MONGODB_URI',
  'JWT_SECRET',
  'JWT_REFRESH_SECRET'
];

// Validation and defaults
this.port = parseInt(process.env.PORT || '5000');
const frontendUrl = process.env.FRONTEND_URL || "http://localhost:3000";
```

### Default Values
- Port: 5000
- Frontend URL: http://localhost:3000
- Node Environment: development

## Error Handling Strategy

### Application Errors
- Try-catch blocks for async operations
- Promise rejection handling
- Database connection error recovery

### HTTP Errors
- Proper status codes
- Consistent error format
- Development vs production messages

### Socket.IO Errors
- Connection error handling
- Event error catching
- Client disconnection management

## Monitoring and Observability

### Health Metrics
- Server uptime
- Process memory usage
- Database connection status
- Active Socket.IO connections

### Logging Strategy
- Request/response logging
- Error tracking
- Performance metrics
- Security events

## Deployment Considerations

### Production Setup
- Environment variable validation
- SSL/TLS termination
- Load balancer compatibility
- Process management integration

### Scaling Preparation
- Stateless design
- External session storage readiness
- Database connection optimization
- Socket.IO clustering support

This documentation provides a comprehensive understanding of the server.ts file's role, implementation, and considerations for the AFO Backend application.