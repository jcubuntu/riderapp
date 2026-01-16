'use strict';

const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const sharp = require('sharp');
const config = require('../config');

/**
 * Upload Utility - Centralized file upload handling
 */

// Upload directories
const UPLOAD_DIRS = {
  profiles: path.join(__dirname, '../../uploads/profiles'),
  incidents: path.join(__dirname, '../../uploads/incidents'),
  chat: path.join(__dirname, '../../uploads/chat'),
  documents: path.join(__dirname, '../../uploads/documents'),
};

// File size limits (in bytes)
const FILE_SIZE_LIMITS = {
  image: 5 * 1024 * 1024,      // 5MB for images
  document: 50 * 1024 * 1024,  // 50MB for documents
  profile: 2 * 1024 * 1024,    // 2MB for profile images
};

// Allowed file types
const ALLOWED_TYPES = {
  image: {
    mimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    extensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
  },
  document: {
    mimeTypes: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
    extensions: ['.pdf', '.doc', '.docx'],
  },
  all: {
    mimeTypes: [
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      'application/pdf', 'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ],
    extensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.pdf', '.doc', '.docx'],
  },
};

/**
 * Ensure upload directories exist
 */
const ensureUploadDirs = () => {
  Object.values(UPLOAD_DIRS).forEach((dir) => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });
};

// Initialize directories on module load
ensureUploadDirs();

/**
 * Generate unique filename
 * @param {string} originalName - Original filename
 * @returns {string} Unique filename
 */
const generateFilename = (originalName) => {
  const ext = path.extname(originalName).toLowerCase();
  const timestamp = Date.now();
  const uniqueId = uuidv4().split('-')[0];
  return `${timestamp}-${uniqueId}${ext}`;
};

/**
 * Get file extension from mimetype
 * @param {string} mimetype - File mimetype
 * @returns {string} File extension
 */
const getExtensionFromMimetype = (mimetype) => {
  const mimeToExt = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'application/pdf': '.pdf',
    'application/msword': '.doc',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': '.docx',
  };
  return mimeToExt[mimetype] || '';
};

/**
 * Validate file type
 * @param {string} mimetype - File mimetype
 * @param {string} type - File category ('image', 'document', 'all')
 * @returns {boolean}
 */
const isValidFileType = (mimetype, type = 'all') => {
  const allowedTypes = ALLOWED_TYPES[type] || ALLOWED_TYPES.all;
  return allowedTypes.mimeTypes.includes(mimetype);
};

/**
 * Create multer disk storage
 * @param {string} uploadType - Type of upload ('profiles', 'incidents', 'chat', 'documents')
 * @returns {multer.StorageEngine}
 */
const createDiskStorage = (uploadType = 'incidents') => {
  const uploadDir = UPLOAD_DIRS[uploadType] || UPLOAD_DIRS.incidents;

  return multer.diskStorage({
    destination: (req, file, cb) => {
      // Ensure directory exists
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }
      cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
      const filename = generateFilename(file.originalname);
      cb(null, filename);
    },
  });
};

/**
 * Create file filter function
 * @param {string} type - File category ('image', 'document', 'all')
 * @returns {Function}
 */
const createFileFilter = (type = 'all') => {
  return (req, file, cb) => {
    if (isValidFileType(file.mimetype, type)) {
      cb(null, true);
    } else {
      const allowedTypes = ALLOWED_TYPES[type] || ALLOWED_TYPES.all;
      cb(new Error(`Invalid file type. Allowed types: ${allowedTypes.extensions.join(', ')}`), false);
    }
  };
};

/**
 * Create multer upload middleware for images
 * @param {string} uploadType - Upload type ('profiles', 'incidents', 'chat')
 * @returns {multer.Multer}
 */
const createImageUploader = (uploadType = 'incidents') => {
  const maxSize = uploadType === 'profiles' ? FILE_SIZE_LIMITS.profile : FILE_SIZE_LIMITS.image;

  return multer({
    storage: createDiskStorage(uploadType),
    fileFilter: createFileFilter('image'),
    limits: {
      fileSize: maxSize,
      files: uploadType === 'profiles' ? 1 : 10, // Single file for profiles, multiple for others
    },
  });
};

/**
 * Create multer upload middleware for documents
 * @param {string} uploadType - Upload type
 * @returns {multer.Multer}
 */
const createDocumentUploader = (uploadType = 'documents') => {
  return multer({
    storage: createDiskStorage(uploadType),
    fileFilter: createFileFilter('document'),
    limits: {
      fileSize: FILE_SIZE_LIMITS.document,
      files: 5,
    },
  });
};

/**
 * Create multer upload middleware for mixed files
 * @param {string} uploadType - Upload type
 * @returns {multer.Multer}
 */
const createMixedUploader = (uploadType = 'incidents') => {
  return multer({
    storage: createDiskStorage(uploadType),
    fileFilter: createFileFilter('all'),
    limits: {
      fileSize: FILE_SIZE_LIMITS.document,
      files: 10,
    },
  });
};

/**
 * Memory storage uploader for processing before save
 * @param {string} type - File type ('image', 'document', 'all')
 * @param {number} maxSize - Max file size in bytes
 * @returns {multer.Multer}
 */
const createMemoryUploader = (type = 'image', maxSize = FILE_SIZE_LIMITS.image) => {
  return multer({
    storage: multer.memoryStorage(),
    fileFilter: createFileFilter(type),
    limits: {
      fileSize: maxSize,
      files: 10,
    },
  });
};

/**
 * Process and save image with resizing/optimization
 * @param {Buffer} buffer - Image buffer
 * @param {string} uploadType - Upload type ('profiles', 'incidents', 'chat')
 * @param {Object} options - Processing options
 * @returns {Promise<Object>} Saved file info
 */
const processAndSaveImage = async (buffer, uploadType = 'incidents', options = {}) => {
  const {
    width = null,
    height = null,
    quality = 80,
    format = 'webp',
  } = options;

  const uploadDir = UPLOAD_DIRS[uploadType] || UPLOAD_DIRS.incidents;
  const filename = `${Date.now()}-${uuidv4().split('-')[0]}.${format}`;
  const filepath = path.join(uploadDir, filename);

  // Ensure directory exists
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }

  let sharpInstance = sharp(buffer);

  // Resize if dimensions provided
  if (width || height) {
    sharpInstance = sharpInstance.resize(width, height, {
      fit: 'inside',
      withoutEnlargement: true,
    });
  }

  // Convert to specified format
  if (format === 'webp') {
    sharpInstance = sharpInstance.webp({ quality });
  } else if (format === 'jpeg' || format === 'jpg') {
    sharpInstance = sharpInstance.jpeg({ quality });
  } else if (format === 'png') {
    sharpInstance = sharpInstance.png({ quality });
  }

  await sharpInstance.toFile(filepath);

  // Get file stats
  const stats = fs.statSync(filepath);

  return {
    filename,
    path: filepath,
    size: stats.size,
    mimetype: `image/${format}`,
    url: getFileUrl(uploadType, filename),
  };
};

/**
 * Get public URL for uploaded file
 * @param {string} uploadType - Upload type
 * @param {string} filename - Filename
 * @returns {string} Public URL
 */
const getFileUrl = (uploadType, filename) => {
  const baseUrl = process.env.BASE_URL || `http://localhost:${config.port}`;
  return `${baseUrl}/uploads/${uploadType}/${filename}`;
};

/**
 * Get relative path for file
 * @param {string} uploadType - Upload type
 * @param {string} filename - Filename
 * @returns {string} Relative path
 */
const getRelativePath = (uploadType, filename) => {
  return `/uploads/${uploadType}/${filename}`;
};

/**
 * Delete file
 * @param {string} filepath - Full file path
 * @returns {Promise<boolean>}
 */
const deleteFile = async (filepath) => {
  try {
    if (fs.existsSync(filepath)) {
      fs.unlinkSync(filepath);
      return true;
    }
    return false;
  } catch (error) {
    console.error('Error deleting file:', error);
    return false;
  }
};

/**
 * Delete file by URL
 * @param {string} url - File URL
 * @returns {Promise<boolean>}
 */
const deleteFileByUrl = async (url) => {
  try {
    if (!url) return false;

    // Extract path from URL
    const urlPath = new URL(url).pathname;
    const relativePath = urlPath.replace('/uploads/', '');
    const [uploadType, filename] = relativePath.split('/');

    if (!uploadType || !filename) return false;

    const filepath = path.join(UPLOAD_DIRS[uploadType] || path.join(__dirname, '../../uploads', uploadType), filename);
    return deleteFile(filepath);
  } catch (error) {
    console.error('Error deleting file by URL:', error);
    return false;
  }
};

/**
 * Get file path from URL
 * @param {string} url - File URL
 * @returns {string|null} File path
 */
const getFilePathFromUrl = (url) => {
  try {
    if (!url) return null;

    const urlPath = new URL(url).pathname;
    const relativePath = urlPath.replace('/uploads/', '');
    const [uploadType, filename] = relativePath.split('/');

    if (!uploadType || !filename) return null;

    return path.join(UPLOAD_DIRS[uploadType] || path.join(__dirname, '../../uploads', uploadType), filename);
  } catch (error) {
    return null;
  }
};

/**
 * Check if file exists
 * @param {string} filepath - File path
 * @returns {boolean}
 */
const fileExists = (filepath) => {
  return fs.existsSync(filepath);
};

/**
 * Get file info
 * @param {string} filepath - File path
 * @returns {Object|null}
 */
const getFileInfo = (filepath) => {
  try {
    if (!fs.existsSync(filepath)) return null;

    const stats = fs.statSync(filepath);
    const filename = path.basename(filepath);
    const ext = path.extname(filepath).toLowerCase();

    return {
      filename,
      size: stats.size,
      extension: ext,
      createdAt: stats.birthtime,
      modifiedAt: stats.mtime,
    };
  } catch (error) {
    return null;
  }
};

/**
 * Handle multer errors
 * @param {Error} err - Multer error
 * @returns {Object} Error details
 */
const handleMulterError = (err) => {
  if (err instanceof multer.MulterError) {
    switch (err.code) {
    case 'LIMIT_FILE_SIZE':
      return { status: 400, message: 'File too large. Please upload a smaller file.' };
    case 'LIMIT_FILE_COUNT':
      return { status: 400, message: 'Too many files. Please reduce the number of files.' };
    case 'LIMIT_UNEXPECTED_FILE':
      return { status: 400, message: 'Unexpected field name for file upload.' };
    case 'LIMIT_FIELD_KEY':
      return { status: 400, message: 'Field name too long.' };
    case 'LIMIT_FIELD_VALUE':
      return { status: 400, message: 'Field value too long.' };
    case 'LIMIT_FIELD_COUNT':
      return { status: 400, message: 'Too many fields.' };
    case 'LIMIT_PART_COUNT':
      return { status: 400, message: 'Too many parts.' };
    default:
      return { status: 400, message: `Upload error: ${err.message}` };
    }
  }

  return { status: 500, message: err.message || 'Unknown upload error' };
};

module.exports = {
  // Constants
  UPLOAD_DIRS,
  FILE_SIZE_LIMITS,
  ALLOWED_TYPES,

  // Functions
  ensureUploadDirs,
  generateFilename,
  getExtensionFromMimetype,
  isValidFileType,
  createDiskStorage,
  createFileFilter,
  createImageUploader,
  createDocumentUploader,
  createMixedUploader,
  createMemoryUploader,
  processAndSaveImage,
  getFileUrl,
  getRelativePath,
  deleteFile,
  deleteFileByUrl,
  getFilePathFromUrl,
  fileExists,
  getFileInfo,
  handleMulterError,
};
