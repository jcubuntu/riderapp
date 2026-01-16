'use strict';

/**
 * Standard success response
 * @param {Object} res - Express response object
 * @param {*} data - Response data
 * @param {string} message - Success message
 * @param {number} statusCode - HTTP status code (default: 200)
 * @returns {Object} JSON response
 */
const successResponse = (res, data = null, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

/**
 * Standard error response
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @param {number} statusCode - HTTP status code (default: 500)
 * @param {Array|Object} errors - Detailed errors (optional)
 * @returns {Object} JSON response
 */
const errorResponse = (res, message = 'Error', statusCode = 500, errors = null) => {
  const response = {
    success: false,
    message,
  };

  if (errors) {
    response.errors = errors;
  }

  return res.status(statusCode).json(response);
};

/**
 * Paginated response
 * @param {Object} res - Express response object
 * @param {Array} data - Response data array
 * @param {Object} pagination - Pagination info
 * @param {string} message - Success message
 * @returns {Object} JSON response
 */
const paginatedResponse = (res, data, pagination, message = 'Success') => {
  // Set pagination headers
  res.set('X-Total-Count', pagination.total);
  res.set('X-Page', pagination.page);
  res.set('X-Per-Page', pagination.limit);
  res.set('X-Total-Pages', pagination.totalPages);

  return res.status(200).json({
    success: true,
    message,
    data,
    pagination: {
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasNextPage: pagination.page < pagination.totalPages,
      hasPrevPage: pagination.page > 1,
    },
  });
};

/**
 * Created response (201)
 * @param {Object} res - Express response object
 * @param {*} data - Created resource data
 * @param {string} message - Success message
 * @returns {Object} JSON response
 */
const createdResponse = (res, data = null, message = 'Resource created successfully') => {
  return successResponse(res, data, message, 201);
};

/**
 * No content response (204)
 * @param {Object} res - Express response object
 * @returns {Object} Empty response
 */
const noContentResponse = (res) => {
  return res.status(204).send();
};

/**
 * Bad request response (400)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @param {Array|Object} errors - Validation errors
 * @returns {Object} JSON response
 */
const badRequestResponse = (res, message = 'Bad request', errors = null) => {
  return errorResponse(res, message, 400, errors);
};

/**
 * Unauthorized response (401)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @returns {Object} JSON response
 */
const unauthorizedResponse = (res, message = 'Unauthorized') => {
  return errorResponse(res, message, 401);
};

/**
 * Forbidden response (403)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @returns {Object} JSON response
 */
const forbiddenResponse = (res, message = 'Forbidden') => {
  return errorResponse(res, message, 403);
};

/**
 * Not found response (404)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @returns {Object} JSON response
 */
const notFoundResponse = (res, message = 'Resource not found') => {
  return errorResponse(res, message, 404);
};

/**
 * Conflict response (409)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @returns {Object} JSON response
 */
const conflictResponse = (res, message = 'Resource already exists') => {
  return errorResponse(res, message, 409);
};

/**
 * Validation error response (422)
 * @param {Object} res - Express response object
 * @param {Array} errors - Validation errors
 * @param {string} message - Error message
 * @returns {Object} JSON response
 */
const validationErrorResponse = (res, errors, message = 'Validation failed') => {
  return errorResponse(res, message, 422, errors);
};

/**
 * Internal server error response (500)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @returns {Object} JSON response
 */
const serverErrorResponse = (res, message = 'Internal server error') => {
  return errorResponse(res, message, 500);
};

/**
 * Service unavailable response (503)
 * @param {Object} res - Express response object
 * @param {string} message - Error message
 * @returns {Object} JSON response
 */
const serviceUnavailableResponse = (res, message = 'Service temporarily unavailable') => {
  return errorResponse(res, message, 503);
};

/**
 * Calculate pagination values
 * @param {number} page - Current page (1-based)
 * @param {number} limit - Items per page
 * @param {number} total - Total items
 * @returns {Object} Pagination object
 */
const calculatePagination = (page, limit, total) => {
  const totalPages = Math.ceil(total / limit);
  const offset = (page - 1) * limit;

  return {
    page: parseInt(page, 10),
    limit: parseInt(limit, 10),
    total: parseInt(total, 10),
    totalPages,
    offset,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
  };
};

/**
 * Parse pagination query parameters
 * @param {Object} query - Express request query
 * @param {Object} defaults - Default values
 * @returns {Object} Parsed pagination values
 */
const parsePaginationQuery = (query, defaults = { page: 1, limit: 10, maxLimit: 100 }) => {
  let page = parseInt(query.page, 10) || defaults.page;
  let limit = parseInt(query.limit, 10) || defaults.limit;

  // Ensure positive values
  page = Math.max(1, page);
  limit = Math.max(1, Math.min(limit, defaults.maxLimit));

  return { page, limit, offset: (page - 1) * limit };
};

module.exports = {
  successResponse,
  errorResponse,
  paginatedResponse,
  createdResponse,
  noContentResponse,
  badRequestResponse,
  unauthorizedResponse,
  forbiddenResponse,
  notFoundResponse,
  conflictResponse,
  validationErrorResponse,
  serverErrorResponse,
  serviceUnavailableResponse,
  calculatePagination,
  parsePaginationQuery,
};
