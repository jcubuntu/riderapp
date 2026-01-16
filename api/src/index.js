'use strict';

require('dotenv').config();

const http = require('http');
const app = require('./app');
const config = require('./config');
const { pool } = require('./config/database');
const logger = require('./utils/logger.utils');
const socketManager = require('./socket');

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO with authentication and event handlers
const io = socketManager.initialize(server);

// Make io accessible to routes via app
app.set('io', io);

// Make socket manager accessible to routes
app.set('socketManager', socketManager);

// Test database connection
const testDatabaseConnection = async () => {
  try {
    const connection = await pool.getConnection();
    logger.info('Database connection established successfully');
    connection.release();
    return true;
  } catch (error) {
    logger.error('Database connection failed:', error.message);
    return false;
  }
};

// Graceful shutdown handler
const gracefulShutdown = async (signal) => {
  logger.info(`${signal} received. Starting graceful shutdown...`);

  // Close Socket.IO connections
  if (io) {
    io.close(() => {
      logger.info('Socket.IO connections closed');
    });
  }

  // Close HTTP server
  server.close(async () => {
    logger.info('HTTP server closed');

    // Close database pool
    try {
      await pool.end();
      logger.info('Database pool closed');
    } catch (error) {
      logger.error('Error closing database pool:', error);
    }

    process.exit(0);
  });

  // Force close after 10 seconds
  setTimeout(() => {
    logger.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

// Register shutdown handlers
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Start server
const startServer = async () => {
  // Test database connection
  const dbConnected = await testDatabaseConnection();
  if (!dbConnected) {
    logger.warn('Starting server without database connection. Some features may not work.');
  }

  server.listen(config.port, () => {
    logger.info(`Server is running on port ${config.port}`);
    logger.info(`Environment: ${config.nodeEnv}`);
    logger.info(`API Version: ${config.apiVersion}`);
    logger.info('Socket.IO initialized with JWT authentication');

    // PM2 ready signal
    if (process.send) {
      process.send('ready');
    }
  });
};

startServer();

module.exports = { server, io, socketManager };
