'use strict';

const express = require('express');
const router = express.Router();
const announcementsController = require('./announcements.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const { adminOnly, policeOrAdmin } = require('../../middleware/role.middleware');
const {
  validate,
  listAnnouncementsSchema,
  listActiveAnnouncementsSchema,
  announcementIdSchema,
  createAnnouncementSchema,
  updateAnnouncementSchema,
} = require('./announcements.validation');

/**
 * Announcements Routes
 *
 * All routes require authentication
 *
 * Public (any authenticated user):
 *   GET  /announcements              - List active announcements for user
 *   GET  /announcements/unread-count - Get unread announcement count
 *   GET  /announcements/:id          - Get announcement by ID
 *   PATCH /announcements/:id/read    - Mark announcement as read
 *
 * Police+ routes:
 *   POST /announcements              - Create announcement (police+)
 *
 * Admin+ routes:
 *   GET  /announcements/admin        - List all announcements (admin view)
 *   GET  /announcements/stats        - Get announcement statistics
 *   PUT  /announcements/:id          - Update announcement (admin+ or creator)
 *   DELETE /announcements/:id        - Delete announcement
 *   POST /announcements/:id/publish  - Publish announcement
 *   POST /announcements/:id/archive  - Archive announcement
 */

// ============= Public Routes (any authenticated user) =============

/**
 * @route   GET /api/v1/announcements/unread-count
 * @desc    Get unread announcement count for current user
 * @access  Any authenticated
 */
router.get(
  '/unread-count',
  authenticate,
  announcementsController.getUnreadCount
);

/**
 * @route   GET /api/v1/announcements
 * @desc    List active announcements for current user (filtered by role)
 * @access  Any authenticated
 * @query   {page, limit}
 */
router.get(
  '/',
  authenticate,
  validate(listActiveAnnouncementsSchema, 'query'),
  announcementsController.getActiveAnnouncements
);

// ============= Admin Routes =============

/**
 * @route   GET /api/v1/announcements/admin
 * @desc    List all announcements (admin view with all statuses)
 * @access  Admin+
 * @query   {page, limit, search, category, priority, status, targetAudience, isPinned, sortBy, sortOrder}
 */
router.get(
  '/admin',
  authenticate,
  adminOnly,
  validate(listAnnouncementsSchema, 'query'),
  announcementsController.getAnnouncements
);

/**
 * @route   GET /api/v1/announcements/stats
 * @desc    Get announcement statistics
 * @access  Admin+
 */
router.get(
  '/stats',
  authenticate,
  adminOnly,
  announcementsController.getAnnouncementStats
);

// ============= Police+ Routes =============

/**
 * @route   POST /api/v1/announcements
 * @desc    Create a new announcement
 * @access  Police+
 * @body    {title, content, summary?, imageUrl?, attachmentUrl?, attachmentName?, category?, priority?, targetAudience?, targetProvince?, status?, publishAt?, expiresAt?, isPinned?}
 */
router.post(
  '/',
  authenticate,
  policeOrAdmin,
  validate(createAnnouncementSchema, 'body'),
  announcementsController.createAnnouncement
);

// ============= Individual Announcement Routes =============

/**
 * @route   GET /api/v1/announcements/:id
 * @desc    Get announcement by ID
 * @access  Any authenticated (filtered by audience for non-admins)
 * @params  {id} - Announcement UUID
 */
router.get(
  '/:id',
  authenticate,
  validate(announcementIdSchema, 'params'),
  announcementsController.getAnnouncementById
);

/**
 * @route   PUT /api/v1/announcements/:id
 * @desc    Update announcement
 * @access  Admin+ or creator (for non-published announcements)
 * @params  {id} - Announcement UUID
 * @body    {title?, content?, summary?, imageUrl?, attachmentUrl?, attachmentName?, category?, priority?, targetAudience?, targetProvince?, status?, publishAt?, expiresAt?, isPinned?}
 */
router.put(
  '/:id',
  authenticate,
  policeOrAdmin,
  validate(announcementIdSchema, 'params'),
  validate(updateAnnouncementSchema, 'body'),
  announcementsController.updateAnnouncement
);

/**
 * @route   DELETE /api/v1/announcements/:id
 * @desc    Delete announcement
 * @access  Admin+
 * @params  {id} - Announcement UUID
 */
router.delete(
  '/:id',
  authenticate,
  adminOnly,
  validate(announcementIdSchema, 'params'),
  announcementsController.deleteAnnouncement
);

/**
 * @route   PATCH /api/v1/announcements/:id/read
 * @desc    Mark announcement as read
 * @access  Any authenticated
 * @params  {id} - Announcement UUID
 */
router.patch(
  '/:id/read',
  authenticate,
  validate(announcementIdSchema, 'params'),
  announcementsController.markAsRead
);

/**
 * @route   POST /api/v1/announcements/:id/publish
 * @desc    Publish an announcement
 * @access  Admin+
 * @params  {id} - Announcement UUID
 */
router.post(
  '/:id/publish',
  authenticate,
  adminOnly,
  validate(announcementIdSchema, 'params'),
  announcementsController.publishAnnouncement
);

/**
 * @route   POST /api/v1/announcements/:id/archive
 * @desc    Archive an announcement
 * @access  Admin+
 * @params  {id} - Announcement UUID
 */
router.post(
  '/:id/archive',
  authenticate,
  adminOnly,
  validate(announcementIdSchema, 'params'),
  announcementsController.archiveAnnouncement
);

module.exports = router;
