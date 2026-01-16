'use strict';

const chatService = require('./chat.service');
const {
  successResponse,
  createdResponse,
  paginatedResponse,
  notFoundResponse,
  badRequestResponse,
  forbiddenResponse,
  calculatePagination,
  parsePaginationQuery,
} = require('../../utils/response.utils');

/**
 * Chat Controller - Handle HTTP requests for chat/messaging
 */

// ============= Conversation Endpoints =============

/**
 * Get user's conversations (paginated)
 * GET /chat/conversations
 */
const getConversations = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query, { page: 1, limit: 20, maxLimit: 50 });
    const { type } = req.query;

    const result = await chatService.getConversations(req.user.id, {
      page,
      limit,
      type,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.conversations, pagination, 'Conversations retrieved successfully');
  } catch (error) {
    console.error('Get conversations error:', error);
    return badRequestResponse(res, 'Failed to retrieve conversations');
  }
};

/**
 * Create a new conversation
 * POST /chat/conversations
 */
const createConversation = async (req, res) => {
  try {
    const conversation = await chatService.createConversation(req.body, req.user);

    return createdResponse(res, conversation, 'Conversation created successfully');
  } catch (error) {
    console.error('Create conversation error:', error);

    switch (error.message) {
      case 'INVALID_TYPE':
        return badRequestResponse(res, 'Invalid conversation type');
      case 'DIRECT_REQUIRES_ONE_PARTICIPANT':
        return badRequestResponse(res, 'Direct conversation requires exactly one other participant');
      case 'GROUP_REQUIRES_PARTICIPANTS':
        return badRequestResponse(res, 'Group conversation requires at least one participant');
      default:
        return badRequestResponse(res, 'Failed to create conversation');
    }
  }
};

/**
 * Get conversation by ID with participants
 * GET /chat/conversations/:id
 */
const getConversationById = async (req, res) => {
  try {
    const { id } = req.params;

    const conversation = await chatService.getConversationById(id, req.user);

    if (!conversation) {
      return notFoundResponse(res, 'Conversation not found');
    }

    return successResponse(res, conversation, 'Conversation retrieved successfully');
  } catch (error) {
    console.error('Get conversation by ID error:', error);

    switch (error.message) {
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You are not a participant in this conversation');
      default:
        return badRequestResponse(res, 'Failed to retrieve conversation');
    }
  }
};

/**
 * Leave a conversation
 * DELETE /chat/conversations/:id
 */
const leaveConversation = async (req, res) => {
  try {
    const { id } = req.params;

    await chatService.leaveConversation(id, req.user);

    return successResponse(res, null, 'Left conversation successfully');
  } catch (error) {
    console.error('Leave conversation error:', error);

    switch (error.message) {
      case 'CONVERSATION_NOT_FOUND':
        return notFoundResponse(res, 'Conversation not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You are not a participant in this conversation');
      default:
        return badRequestResponse(res, 'Failed to leave conversation');
    }
  }
};

/**
 * Mark conversation as read
 * PATCH /chat/conversations/:id/read
 */
const markConversationAsRead = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await chatService.markConversationAsRead(id, req.user);

    return successResponse(res, result, 'Conversation marked as read');
  } catch (error) {
    console.error('Mark conversation as read error:', error);

    switch (error.message) {
      case 'CONVERSATION_NOT_FOUND':
        return notFoundResponse(res, 'Conversation not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You are not a participant in this conversation');
      default:
        return badRequestResponse(res, 'Failed to mark conversation as read');
    }
  }
};

// ============= Message Endpoints =============

/**
 * Get messages for a conversation (paginated)
 * GET /chat/conversations/:id/messages
 */
const getMessages = async (req, res) => {
  try {
    const { id } = req.params;
    const { page, limit } = parsePaginationQuery(req.query, { page: 1, limit: 50, maxLimit: 100 });
    const { before, after } = req.query;

    const result = await chatService.getMessages(id, req.user, {
      page,
      limit,
      before,
      after,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.messages, pagination, 'Messages retrieved successfully');
  } catch (error) {
    console.error('Get messages error:', error);

    switch (error.message) {
      case 'CONVERSATION_NOT_FOUND':
        return notFoundResponse(res, 'Conversation not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You are not a participant in this conversation');
      default:
        return badRequestResponse(res, 'Failed to retrieve messages');
    }
  }
};

/**
 * Send a message to a conversation
 * POST /chat/conversations/:id/messages
 */
const sendMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const { content, messageType, metadata } = req.body;

    const message = await chatService.sendMessage(id, { content, messageType, metadata }, req.user);

    return createdResponse(res, message, 'Message sent successfully');
  } catch (error) {
    console.error('Send message error:', error);

    switch (error.message) {
      case 'CONVERSATION_NOT_FOUND':
        return notFoundResponse(res, 'Conversation not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You are not a participant in this conversation');
      case 'INVALID_MESSAGE_TYPE':
        return badRequestResponse(res, 'Invalid message type');
      default:
        return badRequestResponse(res, 'Failed to send message');
    }
  }
};

/**
 * Get total unread message count
 * GET /chat/unread-count
 */
const getUnreadCount = async (req, res) => {
  try {
    const result = await chatService.getUnreadCount(req.user.id);

    return successResponse(res, result, 'Unread count retrieved successfully');
  } catch (error) {
    console.error('Get unread count error:', error);
    return badRequestResponse(res, 'Failed to retrieve unread count');
  }
};

module.exports = {
  // Conversation endpoints
  getConversations,
  createConversation,
  getConversationById,
  leaveConversation,
  markConversationAsRead,
  // Message endpoints
  getMessages,
  sendMessage,
  getUnreadCount,
};
