'use strict';

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const path = require('path');

const config = require('./config');
const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/error.middleware');
const logger = require('./utils/logger.utils');

// Initialize Express app
const app = express();

// Trust proxy (for when behind a reverse proxy like Nginx)
app.set('trust proxy', 1);

// Security middleware - Helmet
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
}));

// CORS configuration
const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);

    const allowedOrigins = config.cors.origin;
    if (allowedOrigins.includes(origin) || allowedOrigins.includes('*')) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  exposedHeaders: ['X-Total-Count', 'X-Page', 'X-Per-Page'],
  maxAge: 86400, // 24 hours
};

app.use(cors(corsOptions));

// Compression middleware
app.use(compression({
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  },
  level: 6,
}));

// Body parsing middleware
app.use(express.json({
  limit: '10mb',
  strict: true,
}));

app.use(express.urlencoded({
  extended: true,
  limit: '10mb',
}));

// Request logging with Morgan
const morganFormat = config.nodeEnv === 'production' ? 'combined' : 'dev';
const morganStream = {
  write: (message) => logger.http(message.trim()),
};

app.use(morgan(morganFormat, {
  stream: morganStream,
  skip: (req) => req.url === '/health' || req.url === '/api/health',
}));

// Static files (for uploaded files)
app.use('/uploads', express.static(path.join(__dirname, '../uploads'), {
  maxAge: '1d',
  etag: true,
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
  });
});

// API health check
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API is healthy',
    version: config.apiVersion,
    environment: config.nodeEnv,
    timestamp: new Date().toISOString(),
  });
});

// API routes
app.use(`/api/${config.apiVersion}`, routes);

// Handle 404 - Not Found
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

module.exports = app;
