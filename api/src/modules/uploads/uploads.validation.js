'use strict';

const Joi = require('joi');

/**
 * Uploads Validation Schemas
 */

/**
 * Validate filename parameter
 */
const filenameSchema = Joi.object({
  filename: Joi.string()
    .pattern(/^[a-zA-Z0-9_\-.]+$/)
    .max(255)
    .required()
    .messages({
      'string.pattern.base': 'Invalid filename format',
      'string.max': 'Filename too long',
    }),
});

/**
 * Validate upload type query parameter
 */
const uploadTypeSchema = Joi.object({
  type: Joi.string()
    .valid('profiles', 'incidents', 'chat', 'documents')
    .default('incidents'),
});

/**
 * Validate image processing options
 */
const imageProcessingSchema = Joi.object({
  width: Joi.number().integer().min(1).max(4096).optional(),
  height: Joi.number().integer().min(1).max(4096).optional(),
  quality: Joi.number().integer().min(1).max(100).default(80),
  format: Joi.string().valid('webp', 'jpeg', 'jpg', 'png').default('webp'),
});

/**
 * Validate profile upload request
 */
const profileUploadSchema = Joi.object({
  width: Joi.number().integer().min(1).max(1024).default(400),
  height: Joi.number().integer().min(1).max(1024).default(400),
  quality: Joi.number().integer().min(1).max(100).default(85),
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
  filenameSchema,
  uploadTypeSchema,
  imageProcessingSchema,
  profileUploadSchema,
  validate,
};
