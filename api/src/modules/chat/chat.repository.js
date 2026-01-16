'use strict';

const db = require('../../config/database');
const { v4: uuidv4 } = require('uuid');

/**
 * Chat Repository - Database operations for chat/messaging
 */

// ============= Conversation Repository Functions =============

/**
 * Find all conversations for a user
 * @param {string} userId - User UUID
 * @param {Object} options - Query options
 * @returns {Promise<{conversations: Array, total: number}>}
 */
const findConversationsByUser = async (userId, options = {}) => {
  const {
    page = 1,
    limit = 20,
    type = '',
  } = options;

  const offset = (page - 1) * limit;

  // Build WHERE clause
  const conditions = ['cp.user_id = ?', 'cp.left_at IS NULL'];
  const params = [userId];

  if (type) {
    conditions.push('c.type = ?');
    params.push(type);
  }

  const whereClause = `WHERE ${conditions.join(' AND ')}`;

  // Get total count
  const countSql = `
    SELECT COUNT(DISTINCT c.id) as total
    FROM conversations c
    INNER JOIN conversation_participants cp ON c.id = cp.conversation_id
    ${whereClause}
  `;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get conversations with last message and unread count
  const sql = `
    SELECT
      c.id, c.type, c.title, c.incident_id, c.created_by, c.created_at, c.updated_at,
      creator.full_name as creator_name,
      (
        SELECT COUNT(*)
        FROM messages m
        WHERE m.conversation_id = c.id
          AND m.deleted_at IS NULL
          AND m.created_at > COALESCE(cp.last_read_at, '1970-01-01')
          AND m.sender_id != ?
      ) as unread_count,
      (
        SELECT m.content
        FROM messages m
        WHERE m.conversation_id = c.id AND m.deleted_at IS NULL
        ORDER BY m.created_at DESC
        LIMIT 1
      ) as last_message_content,
      (
        SELECT m.message_type
        FROM messages m
        WHERE m.conversation_id = c.id AND m.deleted_at IS NULL
        ORDER BY m.created_at DESC
        LIMIT 1
      ) as last_message_type,
      (
        SELECT m.created_at
        FROM messages m
        WHERE m.conversation_id = c.id AND m.deleted_at IS NULL
        ORDER BY m.created_at DESC
        LIMIT 1
      ) as last_message_at,
      (
        SELECT u.full_name
        FROM messages m
        INNER JOIN users u ON m.sender_id = u.id
        WHERE m.conversation_id = c.id AND m.deleted_at IS NULL
        ORDER BY m.created_at DESC
        LIMIT 1
      ) as last_message_sender_name
    FROM conversations c
    INNER JOIN conversation_participants cp ON c.id = cp.conversation_id
    LEFT JOIN users creator ON c.created_by = creator.id
    ${whereClause}
    ORDER BY COALESCE(
      (SELECT MAX(m.created_at) FROM messages m WHERE m.conversation_id = c.id AND m.deleted_at IS NULL),
      c.created_at
    ) DESC
    LIMIT ? OFFSET ?
  `;

  const conversations = await db.query(sql, [userId, ...params, limit, offset]);

  return { conversations, total };
};

/**
 * Find conversation by ID
 * @param {string} id - Conversation UUID
 * @returns {Promise<Object|null>}
 */
const findConversationById = async (id) => {
  const sql = `
    SELECT
      c.id, c.type, c.title, c.incident_id, c.created_by, c.created_at, c.updated_at,
      creator.full_name as creator_name
    FROM conversations c
    LEFT JOIN users creator ON c.created_by = creator.id
    WHERE c.id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Find conversation by ID with participants
 * @param {string} id - Conversation UUID
 * @returns {Promise<Object|null>}
 */
const findConversationByIdWithParticipants = async (id) => {
  const conversation = await findConversationById(id);
  if (!conversation) return null;

  const participants = await findParticipantsByConversationId(id);
  return { ...conversation, participants };
};

/**
 * Find direct conversation between two users
 * @param {string} userId1 - First user UUID
 * @param {string} userId2 - Second user UUID
 * @returns {Promise<Object|null>}
 */
const findDirectConversation = async (userId1, userId2) => {
  const sql = `
    SELECT c.id, c.type, c.title, c.created_by, c.created_at, c.updated_at
    FROM conversations c
    WHERE c.type = 'direct'
      AND EXISTS (
        SELECT 1 FROM conversation_participants cp1
        WHERE cp1.conversation_id = c.id AND cp1.user_id = ? AND cp1.left_at IS NULL
      )
      AND EXISTS (
        SELECT 1 FROM conversation_participants cp2
        WHERE cp2.conversation_id = c.id AND cp2.user_id = ? AND cp2.left_at IS NULL
      )
      AND (
        SELECT COUNT(*) FROM conversation_participants cp
        WHERE cp.conversation_id = c.id AND cp.left_at IS NULL
      ) = 2
  `;
  return db.queryOne(sql, [userId1, userId2]);
};

/**
 * Create a new conversation
 * @param {Object} data - Conversation data
 * @returns {Promise<Object>}
 */
const createConversation = async (data) => {
  const id = uuidv4();
  const {
    type = 'direct',
    title = null,
    incidentId = null,
    createdBy,
  } = data;

  const sql = `
    INSERT INTO conversations (id, type, title, incident_id, created_by, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  `;

  await db.insert(sql, [id, type, title, incidentId, createdBy]);
  return findConversationById(id);
};

/**
 * Update conversation
 * @param {string} id - Conversation UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>}
 */
const updateConversation = async (id, updates) => {
  const allowedFields = ['title'];
  const updatePairs = [];
  const values = [];

  for (const [key, value] of Object.entries(updates)) {
    const dbKey = key.replace(/([A-Z])/g, '_$1').toLowerCase();
    if (allowedFields.includes(dbKey)) {
      updatePairs.push(`${dbKey} = ?`);
      values.push(value);
    }
  }

  if (updatePairs.length === 0) {
    return findConversationById(id);
  }

  values.push(id);

  const sql = `
    UPDATE conversations
    SET ${updatePairs.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `;

  await db.update(sql, values);
  return findConversationById(id);
};

// ============= Participant Repository Functions =============

/**
 * Find participants by conversation ID
 * @param {string} conversationId - Conversation UUID
 * @returns {Promise<Array>}
 */
const findParticipantsByConversationId = async (conversationId) => {
  const sql = `
    SELECT
      cp.id, cp.conversation_id, cp.user_id, cp.role, cp.joined_at, cp.left_at, cp.last_read_at,
      u.full_name as user_name, u.phone as user_phone, u.role as user_role, u.profile_image_url
    FROM conversation_participants cp
    INNER JOIN users u ON cp.user_id = u.id
    WHERE cp.conversation_id = ? AND cp.left_at IS NULL
    ORDER BY cp.joined_at ASC
  `;
  return db.query(sql, [conversationId]);
};

/**
 * Find participant by conversation and user
 * @param {string} conversationId - Conversation UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>}
 */
const findParticipant = async (conversationId, userId) => {
  const sql = `
    SELECT
      cp.id, cp.conversation_id, cp.user_id, cp.role, cp.joined_at, cp.left_at, cp.last_read_at
    FROM conversation_participants cp
    WHERE cp.conversation_id = ? AND cp.user_id = ? AND cp.left_at IS NULL
  `;
  return db.queryOne(sql, [conversationId, userId]);
};

/**
 * Check if user is participant in conversation
 * @param {string} conversationId - Conversation UUID
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>}
 */
const isParticipant = async (conversationId, userId) => {
  const participant = await findParticipant(conversationId, userId);
  return !!participant;
};

/**
 * Add participant to conversation
 * @param {string} conversationId - Conversation UUID
 * @param {string} userId - User UUID
 * @param {string} role - Participant role (admin/member)
 * @returns {Promise<Object>}
 */
const addParticipant = async (conversationId, userId, role = 'member') => {
  const id = uuidv4();

  const sql = `
    INSERT INTO conversation_participants (id, conversation_id, user_id, role, joined_at)
    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
  `;

  await db.insert(sql, [id, conversationId, userId, role]);
  return findParticipant(conversationId, userId);
};

/**
 * Remove participant from conversation (soft delete by setting left_at)
 * @param {string} conversationId - Conversation UUID
 * @param {string} userId - User UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const removeParticipant = async (conversationId, userId) => {
  const sql = `
    UPDATE conversation_participants
    SET left_at = CURRENT_TIMESTAMP
    WHERE conversation_id = ? AND user_id = ? AND left_at IS NULL
  `;
  return db.update(sql, [conversationId, userId]);
};

/**
 * Update last read timestamp for participant
 * @param {string} conversationId - Conversation UUID
 * @param {string} userId - User UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const updateLastRead = async (conversationId, userId) => {
  const sql = `
    UPDATE conversation_participants
    SET last_read_at = CURRENT_TIMESTAMP
    WHERE conversation_id = ? AND user_id = ? AND left_at IS NULL
  `;
  return db.update(sql, [conversationId, userId]);
};

/**
 * Count active participants in conversation
 * @param {string} conversationId - Conversation UUID
 * @returns {Promise<number>}
 */
const countParticipants = async (conversationId) => {
  const result = await db.queryOne(
    'SELECT COUNT(*) as count FROM conversation_participants WHERE conversation_id = ? AND left_at IS NULL',
    [conversationId]
  );
  return Number(result?.count || 0);
};

// ============= Message Repository Functions =============

/**
 * Find messages by conversation ID (paginated)
 * @param {string} conversationId - Conversation UUID
 * @param {Object} options - Query options
 * @returns {Promise<{messages: Array, total: number}>}
 */
const findMessagesByConversationId = async (conversationId, options = {}) => {
  const {
    page = 1,
    limit = 50,
    before = null,
    after = null,
  } = options;

  const offset = (page - 1) * limit;

  // Build WHERE clause
  const conditions = ['m.conversation_id = ?', 'm.deleted_at IS NULL'];
  const params = [conversationId];

  if (before) {
    conditions.push('m.created_at < ?');
    params.push(before);
  }

  if (after) {
    conditions.push('m.created_at > ?');
    params.push(after);
  }

  const whereClause = `WHERE ${conditions.join(' AND ')}`;

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM messages m ${whereClause}`;
  const countResult = await db.queryOne(countSql, params);
  const total = countResult ? Number(countResult.total) : 0;

  // Get messages with sender info
  const sql = `
    SELECT
      m.id, m.conversation_id, m.sender_id, m.content, m.message_type, m.metadata,
      m.created_at, m.updated_at,
      u.full_name as sender_name, u.profile_image_url as sender_avatar
    FROM messages m
    INNER JOIN users u ON m.sender_id = u.id
    ${whereClause}
    ORDER BY m.created_at DESC
    LIMIT ? OFFSET ?
  `;

  const messages = await db.query(sql, [...params, limit, offset]);

  // Return in chronological order (oldest first)
  return { messages: messages.reverse(), total };
};

/**
 * Find message by ID
 * @param {string} id - Message UUID
 * @returns {Promise<Object|null>}
 */
const findMessageById = async (id) => {
  const sql = `
    SELECT
      m.id, m.conversation_id, m.sender_id, m.content, m.message_type, m.metadata,
      m.created_at, m.updated_at, m.deleted_at,
      u.full_name as sender_name, u.profile_image_url as sender_avatar
    FROM messages m
    INNER JOIN users u ON m.sender_id = u.id
    WHERE m.id = ?
  `;
  return db.queryOne(sql, [id]);
};

/**
 * Create a new message
 * @param {Object} data - Message data
 * @returns {Promise<Object>}
 */
const createMessage = async (data) => {
  const id = uuidv4();
  const {
    conversationId,
    senderId,
    content,
    messageType = 'text',
    metadata = null,
  } = data;

  const sql = `
    INSERT INTO messages (id, conversation_id, sender_id, content, message_type, metadata, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  `;

  const metadataJson = metadata ? JSON.stringify(metadata) : null;
  await db.insert(sql, [id, conversationId, senderId, content, messageType, metadataJson]);

  // Update conversation updated_at
  await db.update(
    'UPDATE conversations SET updated_at = CURRENT_TIMESTAMP WHERE id = ?',
    [conversationId]
  );

  return findMessageById(id);
};

/**
 * Soft delete a message
 * @param {string} id - Message UUID
 * @returns {Promise<{affectedRows: number}>}
 */
const deleteMessage = async (id) => {
  const sql = `
    UPDATE messages
    SET deleted_at = CURRENT_TIMESTAMP, content = '[Message deleted]'
    WHERE id = ?
  `;
  return db.update(sql, [id]);
};

/**
 * Get unread message count for user across all conversations
 * @param {string} userId - User UUID
 * @returns {Promise<number>}
 */
const getUnreadCountForUser = async (userId) => {
  const sql = `
    SELECT COUNT(*) as count
    FROM messages m
    INNER JOIN conversation_participants cp ON m.conversation_id = cp.conversation_id
    WHERE cp.user_id = ?
      AND cp.left_at IS NULL
      AND m.deleted_at IS NULL
      AND m.sender_id != ?
      AND m.created_at > COALESCE(cp.last_read_at, '1970-01-01')
  `;
  const result = await db.queryOne(sql, [userId, userId]);
  return Number(result?.count || 0);
};

/**
 * Get unread message count per conversation for user
 * @param {string} userId - User UUID
 * @returns {Promise<Array>}
 */
const getUnreadCountPerConversation = async (userId) => {
  const sql = `
    SELECT
      cp.conversation_id,
      COUNT(m.id) as unread_count
    FROM conversation_participants cp
    LEFT JOIN messages m ON m.conversation_id = cp.conversation_id
      AND m.deleted_at IS NULL
      AND m.sender_id != ?
      AND m.created_at > COALESCE(cp.last_read_at, '1970-01-01')
    WHERE cp.user_id = ? AND cp.left_at IS NULL
    GROUP BY cp.conversation_id
    HAVING unread_count > 0
  `;
  return db.query(sql, [userId, userId]);
};

// ============= Role-Based Group Functions =============

/**
 * Role hierarchy levels
 */
const ROLE_LEVELS = {
  rider: 1,
  volunteer: 2,
  police: 3,
  commander: 4,
  admin: 5,
  super_admin: 6,
};

/**
 * Get role level
 * @param {string} role - Role name
 * @returns {number} Role level
 */
const getRoleLevel = (role) => ROLE_LEVELS[role] || 0;

/**
 * Find role-based groups accessible by user's role
 * @param {string} userRole - User's role
 * @returns {Promise<Array>}
 */
const findRoleBasedGroups = async (userRole) => {
  const userLevel = getRoleLevel(userRole);

  // Get all role-based groups where user's role level >= minimum role level
  const sql = `
    SELECT
      c.id, c.type, c.title, c.minimum_role, c.created_at, c.updated_at,
      (SELECT COUNT(*) FROM conversation_participants cp WHERE cp.conversation_id = c.id AND cp.left_at IS NULL) as participant_count
    FROM conversations c
    WHERE c.minimum_role IS NOT NULL
      AND c.status = 'active'
    ORDER BY
      CASE c.minimum_role
        WHEN 'rider' THEN 1
        WHEN 'volunteer' THEN 2
        WHEN 'police' THEN 3
        WHEN 'commander' THEN 4
        WHEN 'admin' THEN 5
        WHEN 'super_admin' THEN 6
      END ASC
  `;

  const groups = await db.query(sql);

  // Filter groups by user's role level
  return groups.filter(group => {
    const groupLevel = getRoleLevel(group.minimum_role);
    return userLevel >= groupLevel;
  });
};

/**
 * Join user to a role-based group
 * @param {string} conversationId - Conversation UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object>}
 */
const joinRoleBasedGroup = async (conversationId, userId) => {
  // Check if already a participant
  const existing = await findParticipant(conversationId, userId);
  if (existing) {
    return existing;
  }

  return addParticipant(conversationId, userId, 'member');
};

/**
 * Auto-join user to all accessible role-based groups
 * @param {string} userId - User UUID
 * @param {string} userRole - User's role
 * @returns {Promise<number>} Number of groups joined
 */
const autoJoinRoleBasedGroups = async (userId, userRole) => {
  const groups = await findRoleBasedGroups(userRole);
  let joinedCount = 0;

  for (const group of groups) {
    const isAlreadyMember = await isParticipant(group.id, userId);
    if (!isAlreadyMember) {
      await addParticipant(group.id, userId, 'member');
      joinedCount++;
    }
  }

  return joinedCount;
};

/**
 * Check if a conversation is a role-based group
 * @param {string} conversationId - Conversation UUID
 * @returns {Promise<boolean>}
 */
const isRoleBasedGroup = async (conversationId) => {
  const sql = `SELECT minimum_role FROM conversations WHERE id = ? AND minimum_role IS NOT NULL`;
  const result = await db.queryOne(sql, [conversationId]);
  return !!result;
};

/**
 * Check if user has access to a role-based group
 * @param {string} conversationId - Conversation UUID
 * @param {string} userRole - User's role
 * @returns {Promise<boolean>}
 */
const hasRoleBasedGroupAccess = async (conversationId, userRole) => {
  const sql = `SELECT minimum_role FROM conversations WHERE id = ? AND minimum_role IS NOT NULL`;
  const result = await db.queryOne(sql, [conversationId]);

  if (!result) {
    return false; // Not a role-based group
  }

  const userLevel = getRoleLevel(userRole);
  const groupLevel = getRoleLevel(result.minimum_role);

  return userLevel >= groupLevel;
};

module.exports = {
  // Conversation operations
  findConversationsByUser,
  findConversationById,
  findConversationByIdWithParticipants,
  findDirectConversation,
  createConversation,
  updateConversation,
  // Participant operations
  findParticipantsByConversationId,
  findParticipant,
  isParticipant,
  addParticipant,
  removeParticipant,
  updateLastRead,
  countParticipants,
  // Message operations
  findMessagesByConversationId,
  findMessageById,
  createMessage,
  deleteMessage,
  getUnreadCountForUser,
  getUnreadCountPerConversation,
  // Role-based group operations
  findRoleBasedGroups,
  joinRoleBasedGroup,
  autoJoinRoleBasedGroups,
  isRoleBasedGroup,
  hasRoleBasedGroupAccess,
  getRoleLevel,
  ROLE_LEVELS,
};
