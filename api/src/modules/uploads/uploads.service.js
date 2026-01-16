'use strict';

const path = require('path');
const fs = require('fs');
const uploadUtil = require('../../utils/upload.util');
const { ApiError } = require('../../middleware/error.middleware');

/**
 * Uploads Service - Business logic for file uploads
 */

/**
 * Upload a single image
 * @param {Object} file - Multer file object
 * @param {string} uploadType - Upload type ('profiles', 'incidents', 'chat')
 * @returns {Promise<Object>} Upload result
 */
const uploadImage = async (file, uploadType = 'incidents') => {
  if (!file) {
    throw new ApiError(400, 'No file provided');
  }

  // File was already saved by multer disk storage
  const filename = file.filename;
  const url = uploadUtil.getFileUrl(uploadType, filename);
  const relativePath = uploadUtil.getRelativePath(uploadType, filename);

  return {
    filename,
    originalName: file.originalname,
    mimetype: file.mimetype,
    size: file.size,
    url,
    path: relativePath,
    uploadType,
  };
};

/**
 * Upload multiple images
 * @param {Array} files - Array of multer file objects
 * @param {string} uploadType - Upload type
 * @returns {Promise<Array>} Array of upload results
 */
const uploadImages = async (files, uploadType = 'incidents') => {
  if (!files || files.length === 0) {
    throw new ApiError(400, 'No files provided');
  }

  const results = files.map((file) => ({
    filename: file.filename,
    originalName: file.originalname,
    mimetype: file.mimetype,
    size: file.size,
    url: uploadUtil.getFileUrl(uploadType, file.filename),
    path: uploadUtil.getRelativePath(uploadType, file.filename),
    uploadType,
  }));

  return results;
};

/**
 * Upload and process profile image
 * @param {Buffer} buffer - Image buffer
 * @param {Object} options - Processing options
 * @returns {Promise<Object>} Upload result
 */
const uploadProfileImage = async (buffer, options = {}) => {
  const {
    width = 400,
    height = 400,
    quality = 85,
  } = options;

  const result = await uploadUtil.processAndSaveImage(buffer, 'profiles', {
    width,
    height,
    quality,
    format: 'webp',
  });

  return {
    filename: result.filename,
    mimetype: result.mimetype,
    size: result.size,
    url: result.url,
    path: uploadUtil.getRelativePath('profiles', result.filename),
    uploadType: 'profiles',
  };
};

/**
 * Upload chat image with processing
 * @param {Buffer} buffer - Image buffer
 * @param {Object} options - Processing options
 * @returns {Promise<Object>} Upload result
 */
const uploadChatImage = async (buffer, options = {}) => {
  const {
    width = 1200,
    height = 1200,
    quality = 80,
  } = options;

  const result = await uploadUtil.processAndSaveImage(buffer, 'chat', {
    width,
    height,
    quality,
    format: 'webp',
  });

  return {
    filename: result.filename,
    mimetype: result.mimetype,
    size: result.size,
    url: result.url,
    path: uploadUtil.getRelativePath('chat', result.filename),
    uploadType: 'chat',
  };
};

/**
 * Delete file by filename and type
 * @param {string} filename - Filename
 * @param {string} uploadType - Upload type
 * @returns {Promise<boolean>}
 */
const deleteFile = async (filename, uploadType) => {
  const uploadDir = uploadUtil.UPLOAD_DIRS[uploadType];
  if (!uploadDir) {
    throw new ApiError(400, 'Invalid upload type');
  }

  const filepath = path.join(uploadDir, filename);

  // Check if file exists
  if (!uploadUtil.fileExists(filepath)) {
    throw new ApiError(404, 'File not found');
  }

  const deleted = await uploadUtil.deleteFile(filepath);
  if (!deleted) {
    throw new ApiError(500, 'Failed to delete file');
  }

  return true;
};

/**
 * Delete file by URL
 * @param {string} url - File URL
 * @returns {Promise<boolean>}
 */
const deleteFileByUrl = async (url) => {
  if (!url) {
    throw new ApiError(400, 'File URL is required');
  }

  const deleted = await uploadUtil.deleteFileByUrl(url);
  if (!deleted) {
    throw new ApiError(404, 'File not found or already deleted');
  }

  return true;
};

/**
 * Get file info
 * @param {string} filename - Filename
 * @param {string} uploadType - Upload type
 * @returns {Object} File information
 */
const getFileInfo = (filename, uploadType) => {
  const uploadDir = uploadUtil.UPLOAD_DIRS[uploadType];
  if (!uploadDir) {
    throw new ApiError(400, 'Invalid upload type');
  }

  const filepath = path.join(uploadDir, filename);
  const info = uploadUtil.getFileInfo(filepath);

  if (!info) {
    throw new ApiError(404, 'File not found');
  }

  return {
    ...info,
    url: uploadUtil.getFileUrl(uploadType, filename),
    path: uploadUtil.getRelativePath(uploadType, filename),
    uploadType,
  };
};

/**
 * Verify file ownership or admin access
 * @param {string} filename - Filename
 * @param {string} uploadType - Upload type
 * @param {Object} user - User object
 * @param {string} ownerId - Owner user ID (if known)
 * @returns {boolean}
 */
const canDeleteFile = (user, ownerId = null) => {
  // Admins and super admins can delete any file
  if (user.role === 'admin' || user.role === 'super_admin') {
    return true;
  }

  // Users can delete their own files
  if (ownerId && user.userId === ownerId) {
    return true;
  }

  return false;
};

/**
 * Get list of files in upload directory
 * @param {string} uploadType - Upload type
 * @param {Object} options - List options
 * @returns {Promise<Array>} List of files
 */
const listFiles = async (uploadType, options = {}) => {
  const { limit = 50, offset = 0 } = options;

  const uploadDir = uploadUtil.UPLOAD_DIRS[uploadType];
  if (!uploadDir) {
    throw new ApiError(400, 'Invalid upload type');
  }

  if (!fs.existsSync(uploadDir)) {
    return [];
  }

  const files = fs.readdirSync(uploadDir)
    .filter((filename) => !filename.startsWith('.'))
    .map((filename) => {
      const filepath = path.join(uploadDir, filename);
      const stats = fs.statSync(filepath);
      return {
        filename,
        size: stats.size,
        createdAt: stats.birthtime,
        url: uploadUtil.getFileUrl(uploadType, filename),
      };
    })
    .sort((a, b) => b.createdAt - a.createdAt)
    .slice(offset, offset + limit);

  return files;
};

module.exports = {
  uploadImage,
  uploadImages,
  uploadProfileImage,
  uploadChatImage,
  deleteFile,
  deleteFileByUrl,
  getFileInfo,
  canDeleteFile,
  listFiles,
};
