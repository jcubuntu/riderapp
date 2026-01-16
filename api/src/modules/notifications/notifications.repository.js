'use strict';

const db = require('../../config/database');
const { v4: uuidv4 } = require('uuid');

/**
 * Notifications Repository - Database operations for notifications
 */

/**
 * Find all notifications for a user with pagination and filtering
 * @param {string} userId - User ID
 * @param {Object} options - Query options
 * @returns {Promise<{notifications: Array, total: number}>}
 */
const findAllByUserId = async (userId, options = {}) => {
  const {
    page = 1,
    limit = 10,
    category = '',
    type = '',
    isRead = null,
    sortBy = 'created_at',
    sortOrder = 'DESC',
  } = options;

  const offset = (page - 1) * limit;

  // Build WHERE clause
  const conditions = ['user_id = ?', 'is_dismissed = FALSE'];
  const params = [userId];

  if (category) {
    conditions.push('category = ?');
    params.push(category);
  }

  if (type) {
    conditions.push('type = ?');
    params.push(type);
  }

  if (isRead !== null && isRead !== undefined && isRead !== '') {
    conditions.push('is_read = ?');
    params.push(isRead === true || isRead === 'true' ? 1 : 0);
  }

  // Filter out expired notifications
  conditions.push('(expires_at IS NULL OR expires_at > NOW())');

  const whereClause = `WHERE ${conditions.join(' AND ')}`;

  // Validate sort column
  const allowedSortColumns = ['created_at', 'priority', 'type', 'category', 'is_read'];
  const safeSortBy = allowedSortColumns.includes(sortBy) ? sortBy : 'created_at';
  const safeSortOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM notifications ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get notifications
  const sql = `
    SELECT id, user_id, title, body, summary,
           type, category, entity_type, entity_id,
           action_url, action_type, image_url, icon,
           is_read, read_at, priority, sender_id, data,
           created_at, updated_at
    FROM notifications
    ${whereClause}
    ORDER BY ${safeSortBy} ${safeSortOrder}
    LIMIT ? OFFSET ?
  `;

  const notifications = await db.query(sql, [...params, limit, offset]);

  return { notifications, total };
};

/**
 * Find notification by ID
 * @param {string} id - Notification UUID
 * @returns {Promise<Object|null>}
 */
const findById = async (id) => {
  const sql = `
    SELECT id, user_id, title, body, summary,
           type, category, entity_type, entity_id,
           action_url, action_type, image_url, icon,
           is_read, read_at, is_dismissed, dismissed_at,
           is_push_sent, push_sent_at, push_error,
           scheduled_at, expires_at, priority, sender_id, data,
           created_at, updated_at
    FROM notifications
    WHERE id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Find notification by ID and user ID (for ownership check)
 * @param {string} id - Notification UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>}
 */
const findByIdAndUserId = async (id, userId) => {
  const sql = `
    SELECT id, user_id, title, body, summary,
           type, category, entity_type, entity_id,
           action_url, action_type, image_url, icon,
           is_read, read_at, is_dismissed, dismissed_at,
           priority, sender_id, data,
           created_at, updated_at
    FROM notifications
    WHERE id = ? AND user_id = ?
  `;
  return db.queryOne(sql, [id, userId]);
};

/**
 * Create a new notification
 * @param {Object} data - Notification data
 * @returns {Promise<Object>}
 */
const create = async (data) => {
  const id = uuidv4();

  const sql = `
    INSERT INTO notifications (
      id, user_id, title, body, summary,
      type, category, entity_type, entity_id,
      action_url, action_type, image_url, icon,
      priority, sender_id, data, scheduled_at, expires_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  const params = [
    id,
    data.userId,
    data.title,
    data.body,
    data.summary || null,
    data.type || 'info',
    data.category || 'system',
    data.entityType || null,
    data.entityId || null,
    data.actionUrl || null,
    data.actionType || null,
    data.imageUrl || null,
    data.icon || null,
    data.priority || 'normal',
    data.senderId || null,
    data.data ? JSON.stringify(data.data) : null,
    data.scheduledAt || null,
    data.expiresAt || null,
  ];

  await db.insert(sql, params);
  return findById(id);
};

/**
 * Create multiple notifications at once
 * @param {Array<Object>} notifications - Array of notification data
 * @returns {Promise<number>} Number of created notifications
 */
const createMany = async (notifications) => {
  if (!notifications || notifications.length === 0) {
    return 0;
  }

  const sql = `
    INSERT INTO notifications (
      id, user_id, title, body, summary,
      type, category, entity_type, entity_id,
      action_url, action_type, image_url, icon,
      priority, sender_id, data, scheduled_at, expires_at
    ) VALUES ?
  `;

  const values = notifications.map(data => [
    uuidv4(),
    data.userId,
    data.title,
    data.body,
    data.summary || null,
    data.type || 'info',
    data.category || 'system',
    data.entityType || null,
    data.entityId || null,
    data.actionUrl || null,
    data.actionType || null,
    data.imageUrl || null,
    data.icon || null,
    data.priority || 'normal',
    data.senderId || null,
    data.data ? JSON.stringify(data.data) : null,
    data.scheduledAt || null,
    data.expiresAt || null,
  ]);

  // Build batch insert query
  const placeholders = values.map(() => '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').join(', ');
  const flatValues = values.flat();

  const batchSql = `
    INSERT INTO notifications (
      id, user_id, title, body, summary,
      type, category, entity_type, entity_id,
      action_url, action_type, image_url, icon,
      priority, sender_id, data, scheduled_at, expires_at
    ) VALUES ${placeholders}
  `;

  const result = await db.insert(batchSql, flatValues);
  return result.affectedRows;
};

/**
 * Mark notification as read
 * @param {string} id - Notification UUID
 * @returns {Promise<Object>}
 */
const markAsRead = async (id) => {
  const sql = `
    UPDATE notifications
    SET is_read = TRUE, read_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [id]);
  return findById(id);
};

/**
 * Mark all notifications as read for a user
 * @param {string} userId - User UUID
 * @returns {Promise<number>} Number of updated notifications
 */
const markAllAsRead = async (userId) => {
  const sql = `
    UPDATE notifications
    SET is_read = TRUE, read_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE user_id = ? AND is_read = FALSE AND is_dismissed = FALSE
  `;
  const result = await db.update(sql, [userId]);
  return result.affectedRows;
};

/**
 * Delete notification (soft delete by dismissing)
 * @param {string} id - Notification UUID
 * @returns {Promise<Object>}
 */
const dismiss = async (id) => {
  const sql = `
    UPDATE notifications
    SET is_dismissed = TRUE, dismissed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [id]);
  return findById(id);
};

/**
 * Hard delete notification
 * @param {string} id - Notification UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const remove = async (id) => {
  const sql = 'DELETE FROM notifications WHERE id = ?';
  return db.remove(sql, [id]);
};

/**
 * Get unread count for a user
 * @param {string} userId - User UUID
 * @returns {Promise<number>}
 */
const getUnreadCount = async (userId) => {
  const sql = `
    SELECT COUNT(*) as count
    FROM notifications
    WHERE user_id = ?
      AND is_read = FALSE
      AND is_dismissed = FALSE
      AND (expires_at IS NULL OR expires_at > NOW())
  `;
  const result = await db.queryOne(sql, [userId]);
  return result ? Number(result.count) : 0;
};

/**
 * Get unread count by category for a user
 * @param {string} userId - User UUID
 * @returns {Promise<Object>}
 */
const getUnreadCountByCategory = async (userId) => {
  const sql = `
    SELECT category, COUNT(*) as count
    FROM notifications
    WHERE user_id = ?
      AND is_read = FALSE
      AND is_dismissed = FALSE
      AND (expires_at IS NULL OR expires_at > NOW())
    GROUP BY category
  `;
  const results = await db.query(sql, [userId]);

  const counts = {
    system: 0,
    incident: 0,
    chat: 0,
    announcement: 0,
    approval: 0,
    alert: 0,
    reminder: 0,
    total: 0,
  };

  results.forEach(row => {
    counts[row.category] = Number(row.count);
    counts.total += Number(row.count);
  });

  return counts;
};

/**
 * Update push notification status
 * @param {string} id - Notification UUID
 * @param {boolean} success - Whether push was successful
 * @param {string} error - Error message if failed
 * @returns {Promise<Object>}
 */
const updatePushStatus = async (id, success, error = null) => {
  const sql = `
    UPDATE notifications
    SET is_push_sent = ?, push_sent_at = CURRENT_TIMESTAMP, push_error = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;
  await db.update(sql, [success, error, id]);
  return findById(id);
};

/**
 * Get pending push notifications
 * @param {number} limit - Maximum number to fetch
 * @returns {Promise<Array>}
 */
const getPendingPushNotifications = async (limit = 100) => {
  const sql = `
    SELECT n.id, n.user_id, n.title, n.body, n.summary,
           n.type, n.category, n.entity_type, n.entity_id,
           n.action_url, n.action_type, n.image_url, n.icon,
           n.priority, n.data, n.created_at,
           u.device_token
    FROM notifications n
    INNER JOIN users u ON n.user_id = u.id
    WHERE n.is_push_sent = FALSE
      AND n.is_dismissed = FALSE
      AND (n.scheduled_at IS NULL OR n.scheduled_at <= NOW())
      AND (n.expires_at IS NULL OR n.expires_at > NOW())
      AND u.device_token IS NOT NULL
      AND u.device_token != ''
    ORDER BY n.priority DESC, n.created_at ASC
    LIMIT ?
  `;
  return db.query(sql, [limit]);
};

/**
 * Delete expired notifications
 * @returns {Promise<number>} Number of deleted notifications
 */
const deleteExpired = async () => {
  const sql = `
    DELETE FROM notifications
    WHERE expires_at IS NOT NULL AND expires_at < NOW()
  `;
  const result = await db.remove(sql);
  return result.affectedRows;
};

/**
 * Delete old read notifications (cleanup)
 * @param {number} daysOld - Delete notifications older than this many days
 * @returns {Promise<number>} Number of deleted notifications
 */
const deleteOldRead = async (daysOld = 30) => {
  const sql = `
    DELETE FROM notifications
    WHERE is_read = TRUE
      AND is_dismissed = FALSE
      AND created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
  `;
  const result = await db.remove(sql, [daysOld]);
  return result.affectedRows;
};

module.exports = {
  findAllByUserId,
  findById,
  findByIdAndUserId,
  create,
  createMany,
  markAsRead,
  markAllAsRead,
  dismiss,
  remove,
  getUnreadCount,
  getUnreadCountByCategory,
  updatePushStatus,
  getPendingPushNotifications,
  deleteExpired,
  deleteOldRead,
};
