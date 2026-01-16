'use strict';

const winston = require('winston');
const path = require('path');
const config = require('../config');

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

// Define console format for development
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ level, message, timestamp, stack, ...meta }) => {
    let msg = `${timestamp} [${level}]: ${message}`;
    if (stack) {
      msg += `\n${stack}`;
    }
    if (Object.keys(meta).length > 0) {
      msg += ` ${JSON.stringify(meta)}`;
    }
    return msg;
  })
);

// Create transports array
const transports = [];

// Console transport (always enabled)
transports.push(
  new winston.transports.Console({
    format: config.isDevelopment ? consoleFormat : logFormat,
  })
);

// File transports (only in non-test environments)
if (!config.isTest) {
  // Error log file
  transports.push(
    new winston.transports.File({
      filename: path.join(config.logging.dir, 'error.log'),
      level: 'error',
      format: logFormat,
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    })
  );

  // Combined log file
  transports.push(
    new winston.transports.File({
      filename: path.join(config.logging.dir, 'combined.log'),
      format: logFormat,
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    })
  );
}

// Create logger instance
const logger = winston.createLogger({
  level: config.logging.level,
  format: logFormat,
  transports,
  exitOnError: false,
});

// Add HTTP stream for Morgan
logger.stream = {
  write: (message) => {
    logger.http(message.trim());
  },
};

// Custom log methods for specific use cases
logger.request = (req, message = 'Request received') => {
  logger.info(message, {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    userId: req.user?.id,
  });
};

logger.response = (req, res, message = 'Response sent') => {
  logger.info(message, {
    method: req.method,
    url: req.originalUrl,
    statusCode: res.statusCode,
    userId: req.user?.id,
  });
};

logger.database = (operation, table, message = 'Database operation') => {
  logger.debug(message, {
    operation,
    table,
  });
};

logger.auth = (action, userId, message = 'Auth action') => {
  logger.info(message, {
    action,
    userId,
  });
};

logger.socket = (event, socketId, data = {}) => {
  logger.debug('Socket event', {
    event,
    socketId,
    ...data,
  });
};

module.exports = logger;
