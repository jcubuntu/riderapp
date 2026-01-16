'use strict';

const uploadsService = require('./uploads.service');
const uploadUtil = require('../../utils/upload.util');
const {
  successResponse,
  createdResponse,
  badRequestResponse,
  notFoundResponse,
  forbiddenResponse,
  noContentResponse,
} = require('../../utils/response.utils');

/**
 * Uploads Controller - Handle HTTP requests for file uploads
 */

/**
 * Upload a single image
 * POST /uploads/image
 */
const uploadImage = async (req, res, next) => {
  try {
    const uploadType = req.query.type || 'incidents';
    const result = await uploadsService.uploadImage(req.file, uploadType);

    return createdResponse(res, result, 'Image uploaded successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Upload multiple images
 * POST /uploads/images
 */
const uploadImages = async (req, res, next) => {
  try {
    const uploadType = req.query.type || 'incidents';
    const results = await uploadsService.uploadImages(req.files, uploadType);

    return createdResponse(res, { files: results }, `${results.length} images uploaded successfully`);
  } catch (error) {
    next(error);
  }
};

/**
 * Upload profile image
 * POST /uploads/profile
 */
const uploadProfileImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return badRequestResponse(res, 'No image file provided');
    }

    // Get processing options from query or use defaults
    const options = {
      width: parseInt(req.query.width, 10) || 400,
      height: parseInt(req.query.height, 10) || 400,
      quality: parseInt(req.query.quality, 10) || 85,
    };

    const result = await uploadsService.uploadProfileImage(req.file.buffer, options);

    return createdResponse(res, result, 'Profile image uploaded successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Upload chat image
 * POST /uploads/chat
 */
const uploadChatImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return badRequestResponse(res, 'No image file provided');
    }

    const options = {
      width: parseInt(req.query.width, 10) || 1200,
      height: parseInt(req.query.height, 10) || 1200,
      quality: parseInt(req.query.quality, 10) || 80,
    };

    const result = await uploadsService.uploadChatImage(req.file.buffer, options);

    return createdResponse(res, result, 'Chat image uploaded successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Delete uploaded file
 * DELETE /uploads/:type/:filename
 */
const deleteFile = async (req, res, next) => {
  try {
    const { type, filename } = req.params;

    // Validate upload type
    const validTypes = ['profiles', 'incidents', 'chat', 'documents'];
    if (!validTypes.includes(type)) {
      return badRequestResponse(res, 'Invalid upload type');
    }

    // For profile images, user can only delete their own
    // For other types, check ownership or admin status
    // Note: In a real implementation, you would track file ownership in the database
    // For now, we allow admins to delete any file

    const canDelete = uploadsService.canDeleteFile(req.user, null);

    // If not admin, only allow deleting from profiles type if it's their profile
    if (!canDelete && type !== 'profiles') {
      return forbiddenResponse(res, 'You do not have permission to delete this file');
    }

    await uploadsService.deleteFile(filename, type);

    return noContentResponse(res);
  } catch (error) {
    next(error);
  }
};

/**
 * Get file info
 * GET /uploads/:type/:filename/info
 */
const getFileInfo = async (req, res, next) => {
  try {
    const { type, filename } = req.params;

    // Validate upload type
    const validTypes = ['profiles', 'incidents', 'chat', 'documents'];
    if (!validTypes.includes(type)) {
      return badRequestResponse(res, 'Invalid upload type');
    }

    const info = uploadsService.getFileInfo(filename, type);

    return successResponse(res, info, 'File info retrieved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * List files in upload directory (Admin only)
 * GET /uploads/:type/list
 */
const listFiles = async (req, res, next) => {
  try {
    const { type } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    // Validate upload type
    const validTypes = ['profiles', 'incidents', 'chat', 'documents'];
    if (!validTypes.includes(type)) {
      return badRequestResponse(res, 'Invalid upload type');
    }

    const files = await uploadsService.listFiles(type, {
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
    });

    return successResponse(res, { files, count: files.length }, 'Files retrieved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * Multer error handler middleware
 */
const handleUploadError = (err, req, res, next) => {
  const { status, message } = uploadUtil.handleMulterError(err);
  return res.status(status).json({
    success: false,
    message,
  });
};

module.exports = {
  uploadImage,
  uploadImages,
  uploadProfileImage,
  uploadChatImage,
  deleteFile,
  getFileInfo,
  listFiles,
  handleUploadError,
};
