'use strict';

const express = require('express');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const router = express.Router();

const incidentsController = require('./incidents.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const {
  adminOnly,
  policeOrAdmin,
  volunteerOrHigher,
} = require('../../middleware/role.middleware');
const {
  validate,
  listIncidentsSchema,
  listMyIncidentsSchema,
  incidentIdSchema,
  attachmentIdSchema,
  createIncidentSchema,
  updateIncidentSchema,
  updateStatusSchema,
  assignIncidentSchema,
  uploadAttachmentSchema,
} = require('./incidents.validation');

// ============= Multer Configuration =============

// Configure storage for incident attachments
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../../../uploads/incidents'));
  },
  filename: (req, file, cb) => {
    // Generate unique filename with original extension
    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;
    cb(null, filename);
  },
});

// File filter - allow images, videos, audio, and documents
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    // Images
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/heic',
    'image/heif',
    // Videos
    'video/mp4',
    'video/quicktime',
    'video/x-msvideo',
    'video/webm',
    // Audio
    'audio/mpeg',
    'audio/wav',
    'audio/ogg',
    'audio/mp4',
    // Documents
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];

  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`File type ${file.mimetype} is not allowed`), false);
  }
};

// Multer upload configuration
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB max file size
    files: 5, // Max 5 files per request
  },
});

// Error handling middleware for multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    switch (err.code) {
      case 'LIMIT_FILE_SIZE':
        return res.status(400).json({
          success: false,
          message: 'File size exceeds the limit (50MB)',
        });
      case 'LIMIT_FILE_COUNT':
        return res.status(400).json({
          success: false,
          message: 'Too many files. Maximum 5 files allowed per request',
        });
      case 'LIMIT_UNEXPECTED_FILE':
        return res.status(400).json({
          success: false,
          message: 'Unexpected field name for file upload',
        });
      default:
        return res.status(400).json({
          success: false,
          message: `Upload error: ${err.message}`,
        });
    }
  } else if (err) {
    return res.status(400).json({
      success: false,
      message: err.message || 'File upload failed',
    });
  }
  next();
};

/**
 * Incidents Routes
 *
 * All routes require authentication
 *
 * Any Authenticated User:
 *   GET  /incidents/my     - List own incidents
 *   POST /incidents        - Create new incident
 *
 * Volunteer+ routes:
 *   GET  /incidents        - List all incidents (filtered)
 *   GET  /incidents/stats  - Get incident statistics
 *   GET  /incidents/:id    - Get incident by ID (owner or volunteer+)
 *   GET  /incidents/:id/attachments - Get incident attachments (owner or volunteer+)
 *
 * Police+ routes:
 *   PATCH /incidents/:id/status - Update incident status
 *   POST  /incidents/:id/assign - Assign incident to officer
 *   DELETE /incidents/:id/assign - Unassign incident
 *
 * Owner Only:
 *   PUT   /incidents/:id       - Update own incident (pending only)
 *   POST  /incidents/:id/attachments - Upload attachments
 *
 * Admin+ routes:
 *   DELETE /incidents/:id  - Delete incident
 */

// ============= Any Authenticated User Routes =============

/**
 * @route   GET /api/v1/incidents/my
 * @desc    List own incidents (paginated)
 * @access  Any authenticated user
 * @query   {page, limit, search, category, status, priority, sortBy, sortOrder}
 */
router.get(
  '/my',
  authenticate,
  validate(listMyIncidentsSchema, 'query'),
  incidentsController.getMyIncidents
);

/**
 * @route   POST /api/v1/incidents
 * @desc    Create new incident
 * @access  Any authenticated user
 * @body    {title, description, category?, priority?, location*, incidentDate?, isAnonymous?}
 */
router.post(
  '/',
  authenticate,
  validate(createIncidentSchema, 'body'),
  incidentsController.createIncident
);

// ============= Volunteer+ Routes =============

/**
 * @route   GET /api/v1/incidents
 * @desc    List all incidents (paginated, filtered)
 * @access  Volunteer+
 * @query   {page, limit, search, category, status, priority, province, assignedTo, reportedBy, dateFrom, dateTo, sortBy, sortOrder}
 */
router.get(
  '/',
  authenticate,
  volunteerOrHigher,
  validate(listIncidentsSchema, 'query'),
  incidentsController.getIncidents
);

/**
 * @route   GET /api/v1/incidents/stats
 * @desc    Get incident statistics
 * @access  Volunteer+
 */
router.get(
  '/stats',
  authenticate,
  volunteerOrHigher,
  incidentsController.getIncidentStats
);

/**
 * @route   GET /api/v1/incidents/:id
 * @desc    Get incident by ID
 * @access  Owner or Volunteer+
 * @params  {id} - Incident UUID
 * @query   {includeDetails} - Include reporter/assignee details (default: true)
 */
router.get(
  '/:id',
  authenticate,
  validate(incidentIdSchema, 'params'),
  incidentsController.getIncidentById
);

/**
 * @route   GET /api/v1/incidents/:id/attachments
 * @desc    Get incident attachments
 * @access  Owner or Volunteer+
 * @params  {id} - Incident UUID
 */
router.get(
  '/:id/attachments',
  authenticate,
  validate(incidentIdSchema, 'params'),
  incidentsController.getAttachments
);

// ============= Police+ Routes =============

/**
 * @route   PATCH /api/v1/incidents/:id/status
 * @desc    Update incident status
 * @access  Police+
 * @params  {id} - Incident UUID
 * @body    {status: 'pending'|'reviewing'|'verified'|'resolved'|'rejected', notes?}
 */
router.patch(
  '/:id/status',
  authenticate,
  policeOrAdmin,
  validate(incidentIdSchema, 'params'),
  validate(updateStatusSchema, 'body'),
  incidentsController.updateIncidentStatus
);

/**
 * @route   POST /api/v1/incidents/:id/assign
 * @desc    Assign incident to officer
 * @access  Police+
 * @params  {id} - Incident UUID
 * @body    {assigneeId: UUID}
 */
router.post(
  '/:id/assign',
  authenticate,
  policeOrAdmin,
  validate(incidentIdSchema, 'params'),
  validate(assignIncidentSchema, 'body'),
  incidentsController.assignIncident
);

/**
 * @route   DELETE /api/v1/incidents/:id/assign
 * @desc    Unassign incident
 * @access  Police+
 * @params  {id} - Incident UUID
 */
router.delete(
  '/:id/assign',
  authenticate,
  policeOrAdmin,
  validate(incidentIdSchema, 'params'),
  incidentsController.unassignIncident
);

// ============= Owner Routes =============

/**
 * @route   PUT /api/v1/incidents/:id
 * @desc    Update incident (owner can only update pending incidents)
 * @access  Owner or Admin+
 * @params  {id} - Incident UUID
 * @body    {title?, description?, category?, priority?, location*, incidentDate?, isAnonymous?}
 */
router.put(
  '/:id',
  authenticate,
  validate(incidentIdSchema, 'params'),
  validate(updateIncidentSchema, 'body'),
  incidentsController.updateIncident
);

/**
 * @route   POST /api/v1/incidents/:id/attachments
 * @desc    Upload attachments to incident (max 5 files per request)
 * @access  Owner only
 * @params  {id} - Incident UUID
 * @body    FormData with files[] and optional description
 */
router.post(
  '/:id/attachments',
  authenticate,
  validate(incidentIdSchema, 'params'),
  upload.array('files', 5),
  handleMulterError,
  validate(uploadAttachmentSchema, 'body'),
  incidentsController.uploadAttachments
);

// ============= Admin+ Routes =============

/**
 * @route   DELETE /api/v1/incidents/:id
 * @desc    Delete incident (hard delete)
 * @access  Admin+
 * @params  {id} - Incident UUID
 */
router.delete(
  '/:id',
  authenticate,
  adminOnly,
  validate(incidentIdSchema, 'params'),
  incidentsController.deleteIncident
);

/**
 * @route   DELETE /api/v1/incidents/:id/attachments/:attachmentId
 * @desc    Delete attachment
 * @access  Owner or Admin+
 * @params  {id} - Incident UUID, {attachmentId} - Attachment UUID
 */
router.delete(
  '/:id/attachments/:attachmentId',
  authenticate,
  validate(attachmentIdSchema, 'params'),
  incidentsController.deleteAttachment
);

module.exports = router;
