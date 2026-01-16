'use strict';

const express = require('express');
const router = express.Router();

const uploadsController = require('./uploads.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const { requireRole } = require('../../middleware/role.middleware');
const uploadUtil = require('../../utils/upload.util');
const { validate, uploadTypeSchema, filenameSchema } = require('./uploads.validation');

/**
 * Uploads Routes
 * Base path: /api/v1/uploads
 */

// Create upload middleware instances
const imageUploader = uploadUtil.createImageUploader('incidents');
const profileUploader = uploadUtil.createMemoryUploader('image', uploadUtil.FILE_SIZE_LIMITS.profile);
const chatUploader = uploadUtil.createMemoryUploader('image', uploadUtil.FILE_SIZE_LIMITS.image);

/**
 * @route POST /uploads/image
 * @desc Upload a single image (authenticated)
 * @access Private
 * @query {string} type - Upload type (profiles, incidents, chat, documents)
 */
router.post(
  '/image',
  authenticate,
  validate(uploadTypeSchema, 'query'),
  (req, res, next) => {
    // Dynamic uploader based on type
    const uploadType = req.query.type || 'incidents';
    const uploader = uploadUtil.createImageUploader(uploadType);
    uploader.single('image')(req, res, (err) => {
      if (err) {
        return uploadsController.handleUploadError(err, req, res, next);
      }
      next();
    });
  },
  uploadsController.uploadImage
);

/**
 * @route POST /uploads/images
 * @desc Upload multiple images (authenticated)
 * @access Private
 * @query {string} type - Upload type (profiles, incidents, chat, documents)
 */
router.post(
  '/images',
  authenticate,
  validate(uploadTypeSchema, 'query'),
  (req, res, next) => {
    const uploadType = req.query.type || 'incidents';
    const uploader = uploadUtil.createImageUploader(uploadType);
    uploader.array('images', 10)(req, res, (err) => {
      if (err) {
        return uploadsController.handleUploadError(err, req, res, next);
      }
      next();
    });
  },
  uploadsController.uploadImages
);

/**
 * @route POST /uploads/profile
 * @desc Upload profile image with processing (authenticated)
 * @access Private
 * @query {number} width - Target width (max 1024)
 * @query {number} height - Target height (max 1024)
 * @query {number} quality - Image quality (1-100)
 */
router.post(
  '/profile',
  authenticate,
  (req, res, next) => {
    profileUploader.single('image')(req, res, (err) => {
      if (err) {
        return uploadsController.handleUploadError(err, req, res, next);
      }
      next();
    });
  },
  uploadsController.uploadProfileImage
);

/**
 * @route POST /uploads/chat
 * @desc Upload chat image with processing (authenticated)
 * @access Private
 * @query {number} width - Target width (max 4096)
 * @query {number} height - Target height (max 4096)
 * @query {number} quality - Image quality (1-100)
 */
router.post(
  '/chat',
  authenticate,
  (req, res, next) => {
    chatUploader.single('image')(req, res, (err) => {
      if (err) {
        return uploadsController.handleUploadError(err, req, res, next);
      }
      next();
    });
  },
  uploadsController.uploadChatImage
);

/**
 * @route DELETE /uploads/:type/:filename
 * @desc Delete uploaded file (owner or admin)
 * @access Private
 * @param {string} type - Upload type
 * @param {string} filename - Filename to delete
 */
router.delete(
  '/:type/:filename',
  authenticate,
  uploadsController.deleteFile
);

/**
 * @route GET /uploads/:type/:filename/info
 * @desc Get file info (authenticated)
 * @access Private
 * @param {string} type - Upload type
 * @param {string} filename - Filename
 */
router.get(
  '/:type/:filename/info',
  authenticate,
  uploadsController.getFileInfo
);

/**
 * @route GET /uploads/:type/list
 * @desc List files in upload directory (admin only)
 * @access Admin
 * @param {string} type - Upload type
 * @query {number} limit - Number of files to return
 * @query {number} offset - Offset for pagination
 */
router.get(
  '/:type/list',
  authenticate,
  requireRole('admin'),
  uploadsController.listFiles
);

module.exports = router;
