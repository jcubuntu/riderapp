'use strict';

const { v4: uuidv4 } = require('uuid');
const db = require('../../config/database');

/**
 * Announcements Repository - Database operations for announcements management
 */

/**
 * Find all announcements with pagination and filtering
 * @param {Object} options - Query options
 * @returns {Promise<{announcements: Array, total: number}>}
 */
const findAll = async (options = {}) => {
  const {
    page = 1,
    limit = 10,
    search = '',
    category = '',
    priority = '',
    status = '',
    targetAudience = '',
    isPinned = null,
    sortBy = 'created_at',
    sortOrder = 'DESC',
  } = options;

  const offset = (page - 1) * limit;

  // Build WHERE clause
  const conditions = [];
  const params = [];

  if (search) {
    conditions.push('(a.title LIKE ? OR a.content LIKE ? OR a.summary LIKE ?)');
    const searchTerm = `%${search}%`;
    params.push(searchTerm, searchTerm, searchTerm);
  }

  if (category) {
    conditions.push('a.category = ?');
    params.push(category);
  }

  if (priority) {
    conditions.push('a.priority = ?');
    params.push(priority);
  }

  if (status) {
    conditions.push('a.status = ?');
    params.push(status);
  }

  if (targetAudience) {
    conditions.push('a.target_audience = ?');
    params.push(targetAudience);
  }

  if (isPinned !== null) {
    conditions.push('a.is_pinned = ?');
    params.push(isPinned ? 1 : 0);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  // Validate sort column
  const allowedSortColumns = ['created_at', 'updated_at', 'title', 'priority', 'category', 'status', 'publish_at', 'is_pinned'];
  const safeSortBy = allowedSortColumns.includes(sortBy) ? sortBy : 'created_at';
  const safeSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM announcements a ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get announcements with author info
  const sql = `
    SELECT a.id, a.title, a.content, a.summary, a.image_url,
           a.attachment_url, a.attachment_name, a.category, a.priority,
           a.target_audience, a.target_province, a.status, a.publish_at,
           a.expires_at, a.view_count, a.is_pinned, a.published_by,
           a.published_at, a.created_by, a.created_at, a.updated_at,
           u.full_name as author_name, u.role as author_role,
           p.full_name as publisher_name
    FROM announcements a
    LEFT JOIN users u ON a.created_by = u.id
    LEFT JOIN users p ON a.published_by = p.id
    ${whereClause}
    ORDER BY a.is_pinned DESC, a.${safeSortBy} ${safeSortOrder}
    LIMIT ? OFFSET ?
  `;

  const announcements = await db.query(sql, [...params, limit, offset]);

  return { announcements, total };
};

/**
 * Find active announcements for a specific audience
 * @param {Object} options - Query options
 * @returns {Promise<{announcements: Array, total: number}>}
 */
const findActive = async (options = {}) => {
  const {
    page = 1,
    limit = 10,
    targetAudience = 'all',
    userRole = 'rider',
  } = options;

  const offset = (page - 1) * limit;

  // Build audience conditions based on user role
  const audienceConditions = ['target_audience = ?'];
  const params = ['all'];

  // Add role-specific targeting
  if (userRole === 'rider') {
    audienceConditions.push('target_audience = ?');
    params.push('riders');
  } else if (userRole === 'police' || userRole === 'volunteer') {
    audienceConditions.push('target_audience = ?');
    params.push('police');
  } else if (userRole === 'admin' || userRole === 'super_admin') {
    audienceConditions.push('target_audience = ?');
    params.push('admin');
  }

  const whereClause = `
    WHERE a.status = 'published'
    AND (a.publish_at IS NULL OR a.publish_at <= NOW())
    AND (a.expires_at IS NULL OR a.expires_at > NOW())
    AND (${audienceConditions.join(' OR ')})
  `;

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM announcements a ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get announcements
  const sql = `
    SELECT a.id, a.title, a.content, a.summary, a.image_url,
           a.attachment_url, a.attachment_name, a.category, a.priority,
           a.target_audience, a.target_province, a.status, a.publish_at,
           a.expires_at, a.view_count, a.is_pinned, a.published_by,
           a.published_at, a.created_by, a.created_at, a.updated_at,
           u.full_name as author_name
    FROM announcements a
    LEFT JOIN users u ON a.created_by = u.id
    ${whereClause}
    ORDER BY a.is_pinned DESC, a.priority DESC, a.published_at DESC
    LIMIT ? OFFSET ?
  `;

  const announcements = await db.query(sql, [...params, limit, offset]);

  return { announcements, total };
};

/**
 * Find announcement by ID
 * @param {string} id - Announcement UUID
 * @returns {Promise<Object|null>}
 */
const findById = async (id) => {
  const sql = `
    SELECT a.id, a.title, a.content, a.summary, a.image_url,
           a.attachment_url, a.attachment_name, a.category, a.priority,
           a.target_audience, a.target_province, a.status, a.publish_at,
           a.expires_at, a.view_count, a.is_pinned, a.published_by,
           a.published_at, a.created_by, a.created_at, a.updated_at,
           u.full_name as author_name, u.role as author_role,
           p.full_name as publisher_name
    FROM announcements a
    LEFT JOIN users u ON a.created_by = u.id
    LEFT JOIN users p ON a.published_by = p.id
    WHERE a.id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Create a new announcement
 * @param {Object} data - Announcement data
 * @returns {Promise<Object>}
 */
const create = async (data) => {
  const id = uuidv4();
  const {
    title,
    content,
    summary = null,
    imageUrl = null,
    attachmentUrl = null,
    attachmentName = null,
    category = 'general',
    priority = 'normal',
    targetAudience = 'all',
    targetProvince = null,
    status = 'draft',
    publishAt = null,
    expiresAt = null,
    isPinned = false,
    createdBy,
  } = data;

  // If status is 'published', set published_by and published_at
  const publishedBy = status === 'published' ? createdBy : null;
  const publishedAt = status === 'published' ? new Date().toISOString().slice(0, 19).replace('T', ' ') : null;

  const sql = `
    INSERT INTO announcements (
      id, title, content, summary, image_url, attachment_url, attachment_name,
      category, priority, target_audience, target_province, status,
      publish_at, expires_at, is_pinned, created_by, published_by, published_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  await db.query(sql, [
    id, title, content, summary, imageUrl, attachmentUrl, attachmentName,
    category, priority, targetAudience, targetProvince, status,
    publishAt, expiresAt, isPinned ? 1 : 0, createdBy, publishedBy, publishedAt,
  ]);

  return findById(id);
};

/**
 * Update announcement by ID
 * @param {string} id - Announcement UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>}
 */
const update = async (id, updates) => {
  const allowedFields = [
    'title', 'content', 'summary', 'image_url', 'attachment_url',
    'attachment_name', 'category', 'priority', 'target_audience',
    'target_province', 'status', 'publish_at', 'expires_at', 'is_pinned',
  ];

  const updatePairs = [];
  const values = [];

  for (const [key, value] of Object.entries(updates)) {
    // Convert camelCase to snake_case
    const dbKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
    if (allowedFields.includes(dbKey)) {
      updatePairs.push(`${dbKey} = ?`);
      // Handle boolean conversion for is_pinned
      if (dbKey === 'is_pinned') {
        values.push(value ? 1 : 0);
      } else {
        values.push(value);
      }
    }
  }

  if (updatePairs.length === 0) {
    return findById(id);
  }

  values.push(id);

  const sql = `
    UPDATE announcements
    SET ${updatePairs.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;

  await db.update(sql, values);
  return findById(id);
};

/**
 * Publish an announcement
 * @param {string} id - Announcement UUID
 * @param {string} publishedBy - User ID who published
 * @returns {Promise<Object>}
 */
const publish = async (id, publishedBy) => {
  const sql = `
    UPDATE announcements
    SET status = 'published', published_by = ?, published_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [publishedBy, id]);
  return findById(id);
};

/**
 * Archive an announcement
 * @param {string} id - Announcement UUID
 * @returns {Promise<Object>}
 */
const archive = async (id) => {
  const sql = `
    UPDATE announcements
    SET status = 'archived', updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [id]);
  return findById(id);
};

/**
 * Delete announcement
 * @param {string} id - Announcement UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const remove = async (id) => {
  // First delete related reads
  await db.remove('DELETE FROM announcement_reads WHERE announcement_id = ?', [id]);

  const sql = 'DELETE FROM announcements WHERE id = ?';
  return db.remove(sql, [id]);
};

/**
 * Increment view count
 * @param {string} id - Announcement UUID
 * @returns {Promise<void>}
 */
const incrementViewCount = async (id) => {
  const sql = `
    UPDATE announcements
    SET view_count = view_count + 1
    WHERE id = ?
  `;
  await db.update(sql, [id]);
};

/**
 * Mark announcement as read by user
 * @param {string} announcementId - Announcement UUID
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>} - True if marked as read (new), false if already read
 */
const markAsRead = async (announcementId, userId) => {
  // Check if already read
  const checkSql = `
    SELECT id FROM announcement_reads
    WHERE announcement_id = ? AND user_id = ?
  `;
  const existing = await db.queryOne(checkSql, [announcementId, userId]);

  if (existing) {
    return false; // Already read
  }

  const id = uuidv4();
  const sql = `
    INSERT INTO announcement_reads (id, announcement_id, user_id)
    VALUES (?, ?, ?)
  `;
  await db.query(sql, [id, announcementId, userId]);
  return true;
};

/**
 * Check if user has read an announcement
 * @param {string} announcementId - Announcement UUID
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>}
 */
const isReadByUser = async (announcementId, userId) => {
  const sql = `
    SELECT id FROM announcement_reads
    WHERE announcement_id = ? AND user_id = ?
  `;
  const result = await db.queryOne(sql, [announcementId, userId]);
  return !!result;
};

/**
 * Get unread count for a user
 * @param {string} userId - User UUID
 * @param {string} userRole - User's role for audience filtering
 * @returns {Promise<number>}
 */
const getUnreadCount = async (userId, userRole = 'rider') => {
  // Build audience conditions
  const audienceConditions = ['target_audience = ?'];
  const params = ['all'];

  if (userRole === 'rider') {
    audienceConditions.push('target_audience = ?');
    params.push('riders');
  } else if (userRole === 'police' || userRole === 'volunteer') {
    audienceConditions.push('target_audience = ?');
    params.push('police');
  } else if (userRole === 'admin' || userRole === 'super_admin') {
    audienceConditions.push('target_audience = ?');
    params.push('admin');
  }

  params.push(userId);

  const sql = `
    SELECT COUNT(*) as count
    FROM announcements a
    WHERE a.status = 'published'
    AND (a.publish_at IS NULL OR a.publish_at <= NOW())
    AND (a.expires_at IS NULL OR a.expires_at > NOW())
    AND (${audienceConditions.join(' OR ')})
    AND a.id NOT IN (
      SELECT announcement_id FROM announcement_reads WHERE user_id = ?
    )
  `;

  const result = await db.queryOne(sql, params);
  return result ? Number(result.count) : 0;
};

/**
 * Get read status for multiple announcements
 * @param {Array<string>} announcementIds - Array of announcement UUIDs
 * @param {string} userId - User UUID
 * @returns {Promise<Object>} - Map of announcement ID to read status
 */
const getReadStatusBatch = async (announcementIds, userId) => {
  if (announcementIds.length === 0) {
    return {};
  }

  const placeholders = announcementIds.map(() => '?').join(', ');
  const sql = `
    SELECT announcement_id, read_at
    FROM announcement_reads
    WHERE announcement_id IN (${placeholders}) AND user_id = ?
  `;

  const results = await db.query(sql, [...announcementIds, userId]);

  const readStatus = {};
  announcementIds.forEach(id => {
    readStatus[id] = false;
  });
  results.forEach(row => {
    readStatus[row.announcement_id] = true;
  });

  return readStatus;
};

/**
 * Get announcement statistics
 * @returns {Promise<Object>}
 */
const getStats = async () => {
  const statusSql = `
    SELECT status, COUNT(*) as count
    FROM announcements
    GROUP BY status
  `;
  const statusResults = await db.query(statusSql);

  const categorySql = `
    SELECT category, COUNT(*) as count
    FROM announcements
    WHERE status = 'published'
    GROUP BY category
  `;
  const categoryResults = await db.query(categorySql);

  const prioritySql = `
    SELECT priority, COUNT(*) as count
    FROM announcements
    WHERE status = 'published'
    GROUP BY priority
  `;
  const priorityResults = await db.query(prioritySql);

  const byStatus = {
    draft: 0,
    scheduled: 0,
    published: 0,
    archived: 0,
    total: 0,
  };

  statusResults.forEach(row => {
    byStatus[row.status] = Number(row.count);
    byStatus.total += Number(row.count);
  });

  const byCategory = {};
  categoryResults.forEach(row => {
    byCategory[row.category] = Number(row.count);
  });

  const byPriority = {};
  priorityResults.forEach(row => {
    byPriority[row.priority] = Number(row.count);
  });

  return {
    byStatus,
    byCategory,
    byPriority,
  };
};

module.exports = {
  findAll,
  findActive,
  findById,
  create,
  update,
  publish,
  archive,
  remove,
  incrementViewCount,
  markAsRead,
  isReadByUser,
  getUnreadCount,
  getReadStatusBatch,
  getStats,
};
