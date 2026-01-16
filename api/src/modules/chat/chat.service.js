'use strict';

const chatRepository = require('./chat.repository');

/**
 * Chat Service - Business logic for chat/messaging
 */

// ============= Constants =============

const CONVERSATION_TYPES = ['direct', 'group', 'incident'];
const MESSAGE_TYPES = ['text', 'image', 'file', 'location', 'system'];
const PARTICIPANT_ROLES = ['admin', 'member'];

// ============= Conversation Services =============

/**
 * Get user's conversations (paginated)
 * @param {string} userId - User UUID
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getConversations = async (userId, options = {}) => {
  const { conversations, total } = await chatRepository.findConversationsByUser(userId, options);

  return {
    conversations: conversations.map(formatConversation),
    total,
    page: options.page || 1,
    limit: options.limit || 20,
  };
};

/**
 * Get conversation by ID
 * @param {string} conversationId - Conversation UUID
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object|null>}
 */
const getConversationById = async (conversationId, currentUser) => {
  // Check if user is participant
  const isParticipant = await chatRepository.isParticipant(conversationId, currentUser.id);
  if (!isParticipant) {
    throw new Error('ACCESS_DENIED');
  }

  const conversation = await chatRepository.findConversationByIdWithParticipants(conversationId);
  if (!conversation) {
    return null;
  }

  return formatConversationWithParticipants(conversation);
};

/**
 * Create a new conversation
 * @param {Object} data - Conversation data
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const createConversation = async (data, currentUser) => {
  const { type, title, participantIds, incidentId } = data;

  // Validate conversation type
  if (!CONVERSATION_TYPES.includes(type)) {
    throw new Error('INVALID_TYPE');
  }

  // Validate participant count based on type
  if (type === 'direct') {
    if (!participantIds || participantIds.length !== 1) {
      throw new Error('DIRECT_REQUIRES_ONE_PARTICIPANT');
    }

    // Check if direct conversation already exists
    const existingConversation = await chatRepository.findDirectConversation(
      currentUser.id,
      participantIds[0]
    );

    if (existingConversation) {
      // Return existing conversation instead of creating new one
      const conversation = await chatRepository.findConversationByIdWithParticipants(existingConversation.id);
      return formatConversationWithParticipants(conversation);
    }
  }

  if (type === 'group' && (!participantIds || participantIds.length < 1)) {
    throw new Error('GROUP_REQUIRES_PARTICIPANTS');
  }

  // Cannot add yourself to participants
  const filteredParticipantIds = participantIds.filter(id => id !== currentUser.id);

  // Create the conversation
  const conversation = await chatRepository.createConversation({
    type,
    title: type === 'group' ? title : null,
    incidentId: type === 'incident' ? incidentId : null,
    createdBy: currentUser.id,
  });

  // Add creator as admin
  await chatRepository.addParticipant(conversation.id, currentUser.id, 'admin');

  // Add other participants as members
  for (const participantId of filteredParticipantIds) {
    await chatRepository.addParticipant(conversation.id, participantId, 'member');
  }

  // Return conversation with participants
  const fullConversation = await chatRepository.findConversationByIdWithParticipants(conversation.id);
  return formatConversationWithParticipants(fullConversation);
};

/**
 * Leave a conversation (or delete if only participant)
 * @param {string} conversationId - Conversation UUID
 * @param {Object} currentUser - Current user
 * @returns {Promise<boolean>}
 */
const leaveConversation = async (conversationId, currentUser) => {
  // Check if conversation exists
  const conversation = await chatRepository.findConversationById(conversationId);
  if (!conversation) {
    throw new Error('CONVERSATION_NOT_FOUND');
  }

  // Check if user is participant
  const isParticipant = await chatRepository.isParticipant(conversationId, currentUser.id);
  if (!isParticipant) {
    throw new Error('ACCESS_DENIED');
  }

  // For direct conversations, just mark as left
  // For group conversations, remove participant
  await chatRepository.removeParticipant(conversationId, currentUser.id);

  return true;
};

/**
 * Mark conversation as read
 * @param {string} conversationId - Conversation UUID
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const markConversationAsRead = async (conversationId, currentUser) => {
  // Check if conversation exists
  const conversation = await chatRepository.findConversationById(conversationId);
  if (!conversation) {
    throw new Error('CONVERSATION_NOT_FOUND');
  }

  // Check if user is participant
  const isParticipant = await chatRepository.isParticipant(conversationId, currentUser.id);
  if (!isParticipant) {
    throw new Error('ACCESS_DENIED');
  }

  await chatRepository.updateLastRead(conversationId, currentUser.id);

  return { conversationId, readAt: new Date().toISOString() };
};

// ============= Message Services =============

/**
 * Get messages for a conversation (paginated)
 * @param {string} conversationId - Conversation UUID
 * @param {Object} currentUser - Current user
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getMessages = async (conversationId, currentUser, options = {}) => {
  // Check if conversation exists
  const conversation = await chatRepository.findConversationById(conversationId);
  if (!conversation) {
    throw new Error('CONVERSATION_NOT_FOUND');
  }

  // Check if user is participant
  const isParticipant = await chatRepository.isParticipant(conversationId, currentUser.id);
  if (!isParticipant) {
    throw new Error('ACCESS_DENIED');
  }

  const { messages, total } = await chatRepository.findMessagesByConversationId(conversationId, options);

  return {
    messages: messages.map(formatMessage),
    total,
    page: options.page || 1,
    limit: options.limit || 50,
  };
};

/**
 * Send a message to a conversation
 * @param {string} conversationId - Conversation UUID
 * @param {Object} data - Message data
 * @param {Object} currentUser - Current user
 * @returns {Promise<Object>}
 */
const sendMessage = async (conversationId, data, currentUser) => {
  const { content, messageType = 'text', metadata } = data;

  // Check if conversation exists
  const conversation = await chatRepository.findConversationById(conversationId);
  if (!conversation) {
    throw new Error('CONVERSATION_NOT_FOUND');
  }

  // Check if user is participant
  const isParticipant = await chatRepository.isParticipant(conversationId, currentUser.id);
  if (!isParticipant) {
    throw new Error('ACCESS_DENIED');
  }

  // Validate message type
  if (!MESSAGE_TYPES.includes(messageType)) {
    throw new Error('INVALID_MESSAGE_TYPE');
  }

  // Create the message
  const message = await chatRepository.createMessage({
    conversationId,
    senderId: currentUser.id,
    content,
    messageType,
    metadata,
  });

  // Update sender's last read timestamp
  await chatRepository.updateLastRead(conversationId, currentUser.id);

  return formatMessage(message);
};

/**
 * Get total unread message count for user
 * @param {string} userId - User UUID
 * @returns {Promise<Object>}
 */
const getUnreadCount = async (userId) => {
  const totalUnread = await chatRepository.getUnreadCountForUser(userId);
  const perConversation = await chatRepository.getUnreadCountPerConversation(userId);

  return {
    total: totalUnread,
    conversations: perConversation.map(item => ({
      conversationId: item.conversation_id,
      unreadCount: Number(item.unread_count),
    })),
  };
};

// ============= Helper Functions =============

/**
 * Format conversation object for response
 * @param {Object} conversation - Conversation from database
 * @returns {Object}
 */
const formatConversation = (conversation) => {
  if (!conversation) return null;

  return {
    id: conversation.id,
    type: conversation.type,
    title: conversation.title,
    incidentId: conversation.incident_id,
    createdBy: conversation.created_by,
    creatorName: conversation.creator_name || null,
    unreadCount: Number(conversation.unread_count || 0),
    lastMessage: conversation.last_message_content ? {
      content: conversation.last_message_content,
      type: conversation.last_message_type,
      senderName: conversation.last_message_sender_name,
      createdAt: conversation.last_message_at,
    } : null,
    createdAt: conversation.created_at,
    updatedAt: conversation.updated_at,
  };
};

/**
 * Format conversation with participants for response
 * @param {Object} conversation - Conversation from database with participants
 * @returns {Object}
 */
const formatConversationWithParticipants = (conversation) => {
  if (!conversation) return null;

  const formatted = formatConversation(conversation);
  formatted.participants = (conversation.participants || []).map(formatParticipant);

  return formatted;
};

/**
 * Format participant object for response
 * @param {Object} participant - Participant from database
 * @returns {Object}
 */
const formatParticipant = (participant) => {
  if (!participant) return null;

  return {
    id: participant.id,
    conversationId: participant.conversation_id,
    userId: participant.user_id,
    role: participant.role,
    userName: participant.user_name,
    userPhone: participant.user_phone,
    userRole: participant.user_role,
    profileImageUrl: participant.profile_image_url,
    joinedAt: participant.joined_at,
    lastReadAt: participant.last_read_at,
  };
};

/**
 * Format message object for response
 * @param {Object} message - Message from database
 * @returns {Object}
 */
const formatMessage = (message) => {
  if (!message) return null;

  let metadata = message.metadata;
  if (typeof metadata === 'string') {
    try {
      metadata = JSON.parse(metadata);
    } catch {
      metadata = null;
    }
  }

  return {
    id: message.id,
    conversationId: message.conversation_id,
    senderId: message.sender_id,
    senderName: message.sender_name,
    senderAvatar: message.sender_avatar,
    content: message.content,
    messageType: message.message_type,
    metadata,
    createdAt: message.created_at,
    updatedAt: message.updated_at,
  };
};

module.exports = {
  // Constants
  CONVERSATION_TYPES,
  MESSAGE_TYPES,
  PARTICIPANT_ROLES,
  // Conversation services
  getConversations,
  getConversationById,
  createConversation,
  leaveConversation,
  markConversationAsRead,
  // Message services
  getMessages,
  sendMessage,
  getUnreadCount,
};
