import dotenv from 'dotenv';
import AFOBackendServer from './server';

// Load environment variables
dotenv.config();

// Start the server
const server = new AFOBackendServer();
server.start();