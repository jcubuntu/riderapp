'use strict';

const Joi = require('joi');

/**
 * Chat Validation Schemas
 */

// Conversation types enum
const CONVERSATION_TYPES = ['direct', 'group', 'incident'];

// Message types enum
const MESSAGE_TYPES = ['text', 'image', 'file', 'location', 'system'];

/**
 * Query params for listing conversations
 */
const listConversationsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(20),
  type: Joi.string().valid(...CONVERSATION_TYPES).allow(''),
});

/**
 * Path params for conversation ID
 */
const conversationIdSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

/**
 * Create conversation body
 */
const createConversationSchema = Joi.object({
  type: Joi.string().valid(...CONVERSATION_TYPES).required()
    .messages({
      'any.only': `Type must be one of: ${CONVERSATION_TYPES.join(', ')}`,
      'any.required': 'Conversation type is required',
    }),
  title: Joi.string().max(255).allow(null, '')
    .when('type', {
      is: 'group',
      then: Joi.string().max(255).required(),
      otherwise: Joi.string().max(255).allow(null, ''),
    })
    .messages({
      'string.max': 'Title cannot exceed 255 characters',
      'any.required': 'Title is required for group conversations',
    }),
  participantIds: Joi.array().items(Joi.string().uuid()).min(1).required()
    .messages({
      'array.min': 'At least one participant is required',
      'any.required': 'Participant IDs are required',
    }),
  incidentId: Joi.string().uuid().allow(null)
    .when('type', {
      is: 'incident',
      then: Joi.string().uuid().required(),
      otherwise: Joi.string().uuid().allow(null),
    })
    .messages({
      'any.required': 'Incident ID is required for incident conversations',
    }),
});

/**
 * Query params for listing messages
 */
const listMessagesSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(50),
  before: Joi.date().iso().allow(''),
  after: Joi.date().iso().allow(''),
});

/**
 * Send message body
 */
const sendMessageSchema = Joi.object({
  content: Joi.string().min(1).max(5000).required()
    .messages({
      'string.min': 'Message content is required',
      'string.max': 'Message content cannot exceed 5000 characters',
      'any.required': 'Message content is required',
    }),
  messageType: Joi.string().valid(...MESSAGE_TYPES).default('text')
    .messages({
      'any.only': `Message type must be one of: ${MESSAGE_TYPES.join(', ')}`,
    }),
  metadata: Joi.object().allow(null)
    .messages({
      'object.base': 'Metadata must be an object',
    }),
});

/**
 * Validation middleware factory
 * @param {Joi.Schema} schema - Joi schema to validate against
 * @param {string} property - Request property to validate ('body', 'query', 'params')
 */
const validate = (schema, property = 'body') => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[property], {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors,
      });
    }

    // Replace request property with validated value
    req[property] = value;
    next();
  };
};

module.exports = {
  // Constants
  CONVERSATION_TYPES,
  MESSAGE_TYPES,
  // Schemas
  listConversationsSchema,
  conversationIdSchema,
  createConversationSchema,
  listMessagesSchema,
  sendMessageSchema,
  // Middleware
  validate,
};
