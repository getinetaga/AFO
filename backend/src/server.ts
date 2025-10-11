import compression from 'compression';
import cors from 'cors';
import dotenv from 'dotenv';
import express, { Express, Request, Response } from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { createServer, Server } from 'http';
import morgan from 'morgan';
import path from 'path';
import { Server as SocketIOServer } from 'socket.io';
import connectDB from './database';
import { SocketHandler } from './socket/socketHandler';

// Import routes
import authRoutes from './routes/auth';
import chatRoutes from './routes/chat';

// Load environment variables
dotenv.config();

export class AFOBackendServer {
  private app: Express;
  private server: Server;
  private io: SocketIOServer;
  private socketHandler: SocketHandler;
  private port: number;

  constructor() {
    this.app = express();
    this.server = createServer(this.app);
    this.io = new SocketIOServer(this.server, {
      cors: {
        origin: process.env.FRONTEND_URL || "http://localhost:3000",
        methods: ["GET", "POST"],
        credentials: true
      }
    });
    this.port = parseInt(process.env.PORT || '5000');
    
    this.initializeMiddleware();
    this.initializeRoutes();
    this.initializeDatabase();
    this.initializeSocketIO();
  }

  private initializeMiddleware(): void {
    // Security middleware
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

    // CORS
    this.app.use(cors({
      origin: process.env.FRONTEND_URL || "http://localhost:3000",
      credentials: true
    }));

    // Rate limiting
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // Limit each IP to 100 requests per windowMs
      message: 'Too many requests from this IP, please try again later'
    });
    this.app.use(limiter);

    // Body parsing
    this.app.use(express.json({ limit: '50mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '50mb' }));

    // Compression
    this.app.use(compression());

    // Static file serving for uploads
    this.app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

    // Logging
    if (process.env.NODE_ENV === 'development') {
      this.app.use(morgan('dev'));
    } else {
      this.app.use(morgan('combined'));
    }
  }

  private initializeRoutes(): void {
    // Health check
    this.app.get('/health', (req: Request, res: Response) => {
      res.status(200).json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        version: process.env.npm_package_version || '1.0.0'
      });
    });

    // API routes
    this.app.use('/api/auth', authRoutes);
    this.app.use('/api/chats', chatRoutes);

    // API 404 handler
    this.app.use('/api/*', (req: Request, res: Response) => {
      res.status(404).json({
        success: false,
        message: 'API endpoint not found'
      });
    });

    // Serve React app in production
    if (process.env.NODE_ENV === 'production') {
      const frontendPath = path.join(__dirname, '../frontend/build');
      this.app.use(express.static(frontendPath));
      
      this.app.get('*', (req: Request, res: Response) => {
        res.sendFile(path.join(frontendPath, 'index.html'));
      });
    }

    // Global 404 handler
    this.app.use('*', (req: Request, res: Response) => {
      res.status(404).json({
        success: false,
        message: 'Route not found'
      });
    });

    // Global error handler
    this.app.use((error: any, req: Request, res: Response, next: any) => {
      console.error('Global error handler:', error);
      
      res.status(error.status || 500).json({
        success: false,
        message: process.env.NODE_ENV === 'production' 
          ? 'Internal server error' 
          : error.message || 'Something went wrong',
        ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
      });
    });
  }

  private async initializeDatabase(): Promise<void> {
    try {
      await connectDB();
      console.log('Database connected successfully');
    } catch (error) {
      console.error('Database connection failed:', error);
      process.exit(1);
    }
  }

  private initializeSocketIO(): void {
    this.socketHandler = new SocketHandler(this.io);
    console.log('Socket.IO initialized with authentication and event handlers');
  }

  public start(): void {
    this.server.listen(this.port, () => {
      console.log(`🚀 AFO Backend Server is running on port ${this.port}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🏥 Health check: http://localhost:${this.port}/health`);
      console.log(`� Socket.IO ready for real-time connections`);
      
      if (process.env.NODE_ENV === 'development') {
        console.log(`🔧 API Base URL: http://localhost:${this.port}/api`);
        console.log(`🔐 Auth endpoints: http://localhost:${this.port}/api/auth`);
        console.log(`💬 Chat endpoints: http://localhost:${this.port}/api/chats`);
      }
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      console.log('SIGTERM received, shutting down gracefully...');
      this.server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      console.log('SIGINT received, shutting down gracefully...');
      this.server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    });
  }

  public getApp(): Express {
    return this.app;
  }

  public getServer(): Server {
    return this.server;
  }

  public getIO(): SocketIOServer {
    return this.io;
  }

  public getSocketHandler(): SocketHandler {
    return this.socketHandler;
  }
}

// Start server if this file is run directly
if (require.main === module) {
  const server = new AFOBackendServer();
  server.start();
}

export default AFOBackendServer;