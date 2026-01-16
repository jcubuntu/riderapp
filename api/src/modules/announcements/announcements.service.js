'use strict';

const announcementsRepository = require('./announcements.repository');
const { ROLES, hasMinimumRole } = require('../../constants/roles');

/**
 * Announcements Service - Business logic for announcements management
 */

/**
 * Get all announcements with pagination and filtering (admin view)
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getAnnouncements = async (options = {}) => {
  const { announcements, total } = await announcementsRepository.findAll(options);

  return {
    announcements: announcements.map(formatAnnouncement),
    total,
    page: options.page || 1,
    limit: options.limit || 10,
  };
};

/**
 * Get active announcements for users
 * @param {Object} options - Query options
 * @param {Object} currentUser - Current user for audience filtering
 * @returns {Promise<Object>}
 */
const getActiveAnnouncements = async (options = {}, currentUser) => {
  const { announcements, total } = await announcementsRepository.findActive({
    ...options,
    userRole: currentUser.role,
  });

  // Get read status for all announcements
  const announcementIds = announcements.map(a => a.id);
  const readStatus = await announcementsRepository.getReadStatusBatch(announcementIds, currentUser.id);

  return {
    announcements: announcements.map(a => ({
      ...formatAnnouncement(a),
      isRead: readStatus[a.id] || false,
    })),
    total,
    page: options.page || 1,
    limit: options.limit || 10,
  };
};

/**
 * Get announcement by ID
 * @param {string} id - Announcement UUID
 * @param {Object} currentUser - Current user for read status and permissions
 * @param {boolean} incrementView - Whether to increment view count
 * @returns {Promise<Object|null>}
 */
const getAnnouncementById = async (id, currentUser, incrementView = true) => {
  const announcement = await announcementsRepository.findById(id);

  if (!announcement) {
    return null;
  }

  // Check if user can view this announcement
  if (announcement.status !== 'published') {
    // Only admins+ or creator can view non-published announcements
    const isAdmin = hasMinimumRole(currentUser.role, ROLES.ADMIN);
    const isCreator = announcement.created_by === currentUser.id;

    if (!isAdmin && !isCreator) {
      return null;
    }
  } else {
    // Check audience targeting for published announcements
    const canView = checkAudienceAccess(announcement.target_audience, currentUser.role);
    if (!canView) {
      return null;
    }
  }

  // Increment view count for published announcements
  if (incrementView && announcement.status === 'published') {
    await announcementsRepository.incrementViewCount(id);
  }

  // Get read status
  const isRead = await announcementsRepository.isReadByUser(id, currentUser.id);

  return {
    ...formatAnnouncement(announcement),
    isRead,
  };
};

/**
 * Create a new announcement
 * @param {Object} data - Announcement data
 * @param {Object} currentUser - User creating the announcement
 * @returns {Promise<Object>}
 */
const createAnnouncement = async (data, currentUser) => {
  // Check permission (police+ can create)
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  // Only admins+ can create pinned announcements
  if (data.isPinned && !hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    data.isPinned = false;
  }

  // Only admins+ can publish directly
  if (data.status === 'published' && !hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    data.status = 'draft';
  }

  const announcement = await announcementsRepository.create({
    ...data,
    createdBy: currentUser.id,
  });

  return formatAnnouncement(announcement);
};

/**
 * Update an announcement
 * @param {string} id - Announcement UUID
 * @param {Object} updates - Fields to update
 * @param {Object} currentUser - User performing the update
 * @returns {Promise<Object>}
 */
const updateAnnouncement = async (id, updates, currentUser) => {
  const announcement = await announcementsRepository.findById(id);

  if (!announcement) {
    throw new Error('ANNOUNCEMENT_NOT_FOUND');
  }

  // Check permissions
  const isAdmin = hasMinimumRole(currentUser.role, ROLES.ADMIN);
  const isCreator = announcement.created_by === currentUser.id;

  if (!isAdmin && !isCreator) {
    throw new Error('ACCESS_DENIED');
  }

  // Non-admins cannot update published announcements
  if (!isAdmin && announcement.status === 'published') {
    throw new Error('CANNOT_UPDATE_PUBLISHED');
  }

  // Non-admins cannot pin announcements
  if (updates.isPinned && !isAdmin) {
    delete updates.isPinned;
  }

  // Non-admins cannot publish directly
  if (updates.status === 'published' && !isAdmin) {
    delete updates.status;
  }

  const updatedAnnouncement = await announcementsRepository.update(id, updates);

  return formatAnnouncement(updatedAnnouncement);
};

/**
 * Publish an announcement
 * @param {string} id - Announcement UUID
 * @param {Object} currentUser - User performing the publish
 * @returns {Promise<Object>}
 */
const publishAnnouncement = async (id, currentUser) => {
  const announcement = await announcementsRepository.findById(id);

  if (!announcement) {
    throw new Error('ANNOUNCEMENT_NOT_FOUND');
  }

  // Only admins+ can publish
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  // Can only publish draft or scheduled announcements
  if (announcement.status !== 'draft' && announcement.status !== 'scheduled') {
    throw new Error('INVALID_STATUS_TRANSITION');
  }

  const publishedAnnouncement = await announcementsRepository.publish(id, currentUser.id);

  return formatAnnouncement(publishedAnnouncement);
};

/**
 * Archive an announcement
 * @param {string} id - Announcement UUID
 * @param {Object} currentUser - User performing the archive
 * @returns {Promise<Object>}
 */
const archiveAnnouncement = async (id, currentUser) => {
  const announcement = await announcementsRepository.findById(id);

  if (!announcement) {
    throw new Error('ANNOUNCEMENT_NOT_FOUND');
  }

  // Only admins+ can archive
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  const archivedAnnouncement = await announcementsRepository.archive(id);

  return formatAnnouncement(archivedAnnouncement);
};

/**
 * Delete an announcement
 * @param {string} id - Announcement UUID
 * @param {Object} currentUser - User performing the deletion
 * @returns {Promise<boolean>}
 */
const deleteAnnouncement = async (id, currentUser) => {
  const announcement = await announcementsRepository.findById(id);

  if (!announcement) {
    throw new Error('ANNOUNCEMENT_NOT_FOUND');
  }

  // Only admins+ can delete
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  const result = await announcementsRepository.remove(id);

  return result.affectedRows > 0;
};

/**
 * Mark an announcement as read
 * @param {string} id - Announcement UUID
 * @param {Object} currentUser - User marking as read
 * @returns {Promise<Object>}
 */
const markAsRead = async (id, currentUser) => {
  const announcement = await announcementsRepository.findById(id);

  if (!announcement) {
    throw new Error('ANNOUNCEMENT_NOT_FOUND');
  }

  // Check if user can view this announcement
  if (announcement.status !== 'published') {
    throw new Error('ANNOUNCEMENT_NOT_AVAILABLE');
  }

  const canView = checkAudienceAccess(announcement.target_audience, currentUser.role);
  if (!canView) {
    throw new Error('ACCESS_DENIED');
  }

  const isNewRead = await announcementsRepository.markAsRead(id, currentUser.id);

  return {
    announcementId: id,
    isRead: true,
    isNewRead,
  };
};

/**
 * Get unread count for current user
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const getUnreadCount = async (currentUser) => {
  const count = await announcementsRepository.getUnreadCount(currentUser.id, currentUser.role);

  return {
    unreadCount: count,
  };
};

/**
 * Get announcement statistics
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const getAnnouncementStats = async (currentUser) => {
  // Only admins+ can view stats
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  return announcementsRepository.getStats();
};

/**
 * Check if user role has access to announcement based on target audience
 * @param {string} targetAudience - Target audience of announcement
 * @param {string} userRole - User's role
 * @returns {boolean}
 */
const checkAudienceAccess = (targetAudience, userRole) => {
  if (targetAudience === 'all') {
    return true;
  }

  if (targetAudience === 'riders' && userRole === ROLES.RIDER) {
    return true;
  }

  if (targetAudience === 'police' && (userRole === ROLES.POLICE || userRole === ROLES.VOLUNTEER)) {
    return true;
  }

  if (targetAudience === 'admin' && (userRole === ROLES.ADMIN || userRole === ROLES.SUPER_ADMIN)) {
    return true;
  }

  // Admins can always access
  if (hasMinimumRole(userRole, ROLES.ADMIN)) {
    return true;
  }

  return false;
};

/**
 * Format announcement object for response
 * @param {Object} announcement - Announcement from database
 * @returns {Object}
 */
const formatAnnouncement = (announcement) => {
  if (!announcement) return null;

  return {
    id: announcement.id,
    title: announcement.title,
    content: announcement.content,
    summary: announcement.summary,
    imageUrl: announcement.image_url,
    attachmentUrl: announcement.attachment_url,
    attachmentName: announcement.attachment_name,
    category: announcement.category,
    priority: announcement.priority,
    targetAudience: announcement.target_audience,
    targetProvince: announcement.target_province,
    status: announcement.status,
    publishAt: announcement.publish_at,
    expiresAt: announcement.expires_at,
    viewCount: announcement.view_count,
    isPinned: Boolean(announcement.is_pinned),
    publishedBy: announcement.published_by,
    publishedAt: announcement.published_at,
    publisherName: announcement.publisher_name || null,
    createdBy: announcement.created_by,
    authorName: announcement.author_name || null,
    authorRole: announcement.author_role || null,
    createdAt: announcement.created_at,
    updatedAt: announcement.updated_at,
  };
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
