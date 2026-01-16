'use strict';

const config = require('../config');
const logger = require('../utils/logger.utils');

/**
 * Custom API Error class
 */
class ApiError extends Error {
  constructor(statusCode, message, errors = null, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.errors = errors;
    this.isOperational = isOperational;

    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * 404 Not Found handler
 */
const notFoundHandler = (req, res, next) => {
  const error = new ApiError(404, `Route ${req.originalUrl} not found`);
  next(error);
};

/**
 * Handle validation errors from Joi
 */
const handleJoiError = (error) => {
  const errors = error.details.map((detail) => ({
    field: detail.path.join('.'),
    message: detail.message.replace(/['"]/g, ''),
  }));
  return new ApiError(400, 'Validation failed', errors);
};

/**
 * Handle validation errors from express-validator
 */
const handleExpressValidatorError = (errors) => {
  const formattedErrors = errors.array().map((error) => ({
    field: error.path || error.param,
    message: error.msg,
    value: error.value,
  }));
  return new ApiError(400, 'Validation failed', formattedErrors);
};

/**
 * Handle database errors
 */
const handleDatabaseError = (error) => {
  // Duplicate entry error
  if (error.code === 'ER_DUP_ENTRY' || error.errno === 1062) {
    const match = error.message.match(/Duplicate entry '(.+)' for key '(.+)'/);
    const field = match ? match[2] : 'field';
    return new ApiError(409, `Duplicate value for ${field}`);
  }

  // Foreign key constraint error
  if (error.code === 'ER_NO_REFERENCED_ROW_2' || error.errno === 1452) {
    return new ApiError(400, 'Referenced record does not exist');
  }

  // Foreign key constraint on delete
  if (error.code === 'ER_ROW_IS_REFERENCED_2' || error.errno === 1451) {
    return new ApiError(409, 'Cannot delete record because it is referenced by other records');
  }

  // Connection error
  if (error.code === 'ECONNREFUSED' || error.code === 'PROTOCOL_CONNECTION_LOST') {
    return new ApiError(503, 'Database connection error');
  }

  // Default database error
  return new ApiError(500, 'Database error');
};

/**
 * Handle JWT errors
 */
const handleJWTError = () => new ApiError(401, 'Invalid token');

/**
 * Handle JWT expired error
 */
const handleJWTExpiredError = () => new ApiError(401, 'Token has expired');

/**
 * Handle multer file upload errors
 */
const handleMulterError = (error) => {
  if (error.code === 'LIMIT_FILE_SIZE') {
    return new ApiError(400, 'File size too large');
  }
  if (error.code === 'LIMIT_FILE_COUNT') {
    return new ApiError(400, 'Too many files uploaded');
  }
  if (error.code === 'LIMIT_UNEXPECTED_FILE') {
    return new ApiError(400, 'Unexpected file field');
  }
  return new ApiError(400, 'File upload error');
};

/**
 * Send error response for development environment
 */
const sendDevError = (error, res) => {
  res.status(error.statusCode).json({
    success: false,
    status: error.status,
    message: error.message,
    errors: error.errors || null,
    stack: error.stack,
    error: error,
  });
};

/**
 * Send error response for production environment
 */
const sendProdError = (error, res) => {
  // Operational, trusted error: send message to client
  if (error.isOperational) {
    res.status(error.statusCode).json({
      success: false,
      status: error.status,
      message: error.message,
      errors: error.errors || null,
    });
  } else {
    // Programming or other unknown error: don't leak error details
    logger.error('ERROR:', error);

    res.status(500).json({
      success: false,
      status: 'error',
      message: 'Something went wrong',
    });
  }
};

/**
 * Global error handler middleware
 */
const errorHandler = (error, req, res, next) => {
  error.statusCode = error.statusCode || 500;
  error.status = error.status || 'error';

  // Log error
  logger.error({
    message: error.message,
    statusCode: error.statusCode,
    stack: error.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userId: req.user?.id,
  });

  // Handle specific error types
  let processedError = error;

  // Joi validation error
  if (error.isJoi) {
    processedError = handleJoiError(error);
  }

  // Database errors
  if (error.code && (error.code.startsWith('ER_') || error.errno)) {
    processedError = handleDatabaseError(error);
  }

  // JWT errors
  if (error.name === 'JsonWebTokenError') {
    processedError = handleJWTError();
  }
  if (error.name === 'TokenExpiredError') {
    processedError = handleJWTExpiredError();
  }

  // Multer errors
  if (error.name === 'MulterError') {
    processedError = handleMulterError(error);
  }

  // Syntax error in JSON body
  if (error instanceof SyntaxError && error.status === 400 && 'body' in error) {
    processedError = new ApiError(400, 'Invalid JSON in request body');
  }

  // Send appropriate error response
  if (config.isDevelopment) {
    sendDevError(processedError, res);
  } else {
    sendProdError(processedError, res);
  }
};

/**
 * Async handler wrapper to catch errors in async routes
 * @param {Function} fn - Async function to wrap
 * @returns {Function} Express middleware function
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = {
  ApiError,
  notFoundHandler,
  errorHandler,
  asyncHandler,
  handleJoiError,
  handleExpressValidatorError,
};
