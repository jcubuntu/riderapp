'use strict';

const announcementsService = require('./announcements.service');
const {
  successResponse,
  paginatedResponse,
  createdResponse,
  notFoundResponse,
  badRequestResponse,
  forbiddenResponse,
  calculatePagination,
  parsePaginationQuery,
} = require('../../utils/response.utils');

/**
 * Announcements Controller - Handle HTTP requests for announcements management
 */

/**
 * Get all announcements (admin view with pagination)
 * GET /announcements/admin
 */
const getAnnouncements = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query);
    const { search, category, priority, status, targetAudience, isPinned, sortBy, sortOrder } = req.query;

    const result = await announcementsService.getAnnouncements({
      page,
      limit,
      search,
      category,
      priority,
      status,
      targetAudience,
      isPinned: isPinned === 'true' ? true : isPinned === 'false' ? false : null,
      sortBy,
      sortOrder,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.announcements, pagination, 'Announcements retrieved successfully');
  } catch (error) {
    console.error('Get announcements error:', error);
    return badRequestResponse(res, 'Failed to retrieve announcements');
  }
};

/**
 * Get active announcements for users
 * GET /announcements
 */
const getActiveAnnouncements = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query);

    const result = await announcementsService.getActiveAnnouncements(
      { page, limit },
      req.user
    );

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.announcements, pagination, 'Announcements retrieved successfully');
  } catch (error) {
    console.error('Get active announcements error:', error);
    return badRequestResponse(res, 'Failed to retrieve announcements');
  }
};

/**
 * Get announcement by ID
 * GET /announcements/:id
 */
const getAnnouncementById = async (req, res) => {
  try {
    const { id } = req.params;

    const announcement = await announcementsService.getAnnouncementById(id, req.user);

    if (!announcement) {
      return notFoundResponse(res, 'Announcement not found');
    }

    return successResponse(res, announcement, 'Announcement retrieved successfully');
  } catch (error) {
    console.error('Get announcement by ID error:', error);
    return badRequestResponse(res, 'Failed to retrieve announcement');
  }
};

/**
 * Create a new announcement
 * POST /announcements
 */
const createAnnouncement = async (req, res) => {
  try {
    const announcement = await announcementsService.createAnnouncement(req.body, req.user);

    return createdResponse(res, announcement, 'Announcement created successfully');
  } catch (error) {
    console.error('Create announcement error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to create announcements');
      default:
        return badRequestResponse(res, 'Failed to create announcement');
    }
  }
};

/**
 * Update an announcement
 * PUT /announcements/:id
 */
const updateAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;

    const announcement = await announcementsService.updateAnnouncement(id, req.body, req.user);

    return successResponse(res, announcement, 'Announcement updated successfully');
  } catch (error) {
    console.error('Update announcement error:', error);

    switch (error.message) {
      case 'ANNOUNCEMENT_NOT_FOUND':
        return notFoundResponse(res, 'Announcement not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to update this announcement');
      case 'CANNOT_UPDATE_PUBLISHED':
        return forbiddenResponse(res, 'You cannot update a published announcement');
      default:
        return badRequestResponse(res, 'Failed to update announcement');
    }
  }
};

/**
 * Publish an announcement
 * POST /announcements/:id/publish
 */
const publishAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;

    const announcement = await announcementsService.publishAnnouncement(id, req.user);

    return successResponse(res, announcement, 'Announcement published successfully');
  } catch (error) {
    console.error('Publish announcement error:', error);

    switch (error.message) {
      case 'ANNOUNCEMENT_NOT_FOUND':
        return notFoundResponse(res, 'Announcement not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to publish announcements');
      case 'INVALID_STATUS_TRANSITION':
        return badRequestResponse(res, 'Only draft or scheduled announcements can be published');
      default:
        return badRequestResponse(res, 'Failed to publish announcement');
    }
  }
};

/**
 * Archive an announcement
 * POST /announcements/:id/archive
 */
const archiveAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;

    const announcement = await announcementsService.archiveAnnouncement(id, req.user);

    return successResponse(res, announcement, 'Announcement archived successfully');
  } catch (error) {
    console.error('Archive announcement error:', error);

    switch (error.message) {
      case 'ANNOUNCEMENT_NOT_FOUND':
        return notFoundResponse(res, 'Announcement not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to archive announcements');
      default:
        return badRequestResponse(res, 'Failed to archive announcement');
    }
  }
};

/**
 * Delete an announcement
 * DELETE /announcements/:id
 */
const deleteAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;

    await announcementsService.deleteAnnouncement(id, req.user);

    return successResponse(res, null, 'Announcement deleted successfully');
  } catch (error) {
    console.error('Delete announcement error:', error);

    switch (error.message) {
      case 'ANNOUNCEMENT_NOT_FOUND':
        return notFoundResponse(res, 'Announcement not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to delete announcements');
      default:
        return badRequestResponse(res, 'Failed to delete announcement');
    }
  }
};

/**
 * Mark announcement as read
 * PATCH /announcements/:id/read
 */
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await announcementsService.markAsRead(id, req.user);

    return successResponse(res, result, 'Announcement marked as read');
  } catch (error) {
    console.error('Mark as read error:', error);

    switch (error.message) {
      case 'ANNOUNCEMENT_NOT_FOUND':
        return notFoundResponse(res, 'Announcement not found');
      case 'ANNOUNCEMENT_NOT_AVAILABLE':
        return notFoundResponse(res, 'Announcement is not available');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have access to this announcement');
      default:
        return badRequestResponse(res, 'Failed to mark announcement as read');
    }
  }
};

/**
 * Get unread announcement count
 * GET /announcements/unread-count
 */
const getUnreadCount = async (req, res) => {
  try {
    const result = await announcementsService.getUnreadCount(req.user);

    return successResponse(res, result, 'Unread count retrieved successfully');
  } catch (error) {
    console.error('Get unread count error:', error);
    return badRequestResponse(res, 'Failed to retrieve unread count');
  }
};

/**
 * Get announcement statistics
 * GET /announcements/stats
 */
const getAnnouncementStats = async (req, res) => {
  try {
    const stats = await announcementsService.getAnnouncementStats(req.user);

    return successResponse(res, stats, 'Announcement statistics retrieved successfully');
  } catch (error) {
    console.error('Get announcement stats error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to view statistics');
      default:
        return badRequestResponse(res, 'Failed to retrieve announcement statistics');
    }
  }
};

module.exports = {
  getAnnouncements,
  getActiveAnnouncements,
  getAnnouncementById,
  createAnnouncement,
  updateAnnouncement,
  publishAnnouncement,
  archiveAnnouncement,
  deleteAnnouncement,
  markAsRead,
  getUnreadCount,
  getAnnouncementStats,
};
