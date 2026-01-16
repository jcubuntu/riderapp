'use strict';

const express = require('express');
const router = express.Router();

const chatController = require('./chat.controller');
const { authenticate } = require('../../middleware/auth.middleware');
const {
  validate,
  listConversationsSchema,
  conversationIdSchema,
  createConversationSchema,
  listMessagesSchema,
  sendMessageSchema,
} = require('./chat.validation');

/**
 * Chat Routes
 *
 * All routes require authentication
 *
 * Role-Based Group Endpoints:
 *   GET    /chat/groups                     - List role-based groups accessible by user
 *   POST   /chat/groups/:id/join            - Join a role-based group
 *   POST   /chat/groups/auto-join           - Auto-join all accessible groups
 *
 * Conversation Endpoints:
 *   GET    /chat/conversations              - List user's conversations
 *   POST   /chat/conversations              - Create new conversation
 *   GET    /chat/conversations/:id          - Get conversation by ID (participant only)
 *   DELETE /chat/conversations/:id          - Leave conversation (participant only)
 *   PATCH  /chat/conversations/:id/read     - Mark conversation as read (participant only)
 *
 * Message Endpoints:
 *   GET    /chat/conversations/:id/messages - Get messages (participant only)
 *   POST   /chat/conversations/:id/messages - Send message (participant only)
 *
 * Unread Count:
 *   GET    /chat/unread-count               - Get total unread message count
 */

// ============= Role-Based Group Routes =============

/**
 * @route   GET /api/v1/chat/groups
 * @desc    List role-based chat groups accessible by current user
 * @access  Any authenticated user
 */
router.get(
  '/groups',
  authenticate,
  chatController.getRoleBasedGroups
);

/**
 * @route   POST /api/v1/chat/groups/auto-join
 * @desc    Auto-join user to all accessible role-based groups
 * @access  Any authenticated user
 */
router.post(
  '/groups/auto-join',
  authenticate,
  chatController.autoJoinAllGroups
);

/**
 * @route   POST /api/v1/chat/groups/:id/join
 * @desc    Join a specific role-based chat group
 * @access  Any authenticated user with sufficient role
 * @params  {id} - Conversation UUID
 */
router.post(
  '/groups/:id/join',
  authenticate,
  validate(conversationIdSchema, 'params'),
  chatController.joinRoleBasedGroup
);

// ============= Unread Count Route =============

/**
 * @route   GET /api/v1/chat/unread-count
 * @desc    Get total unread message count for current user
 * @access  Any authenticated user
 */
router.get(
  '/unread-count',
  authenticate,
  chatController.getUnreadCount
);

// ============= Conversation Routes =============

/**
 * @route   GET /api/v1/chat/conversations
 * @desc    List user's conversations (paginated)
 * @access  Any authenticated user
 * @query   {page, limit, type}
 */
router.get(
  '/conversations',
  authenticate,
  validate(listConversationsSchema, 'query'),
  chatController.getConversations
);

/**
 * @route   POST /api/v1/chat/conversations
 * @desc    Create a new conversation
 * @access  Any authenticated user
 * @body    {type: 'direct'|'group'|'incident', title?, participantIds: string[], incidentId?}
 */
router.post(
  '/conversations',
  authenticate,
  validate(createConversationSchema, 'body'),
  chatController.createConversation
);

/**
 * @route   GET /api/v1/chat/conversations/:id
 * @desc    Get conversation by ID with participants
 * @access  Participant only
 * @params  {id} - Conversation UUID
 */
router.get(
  '/conversations/:id',
  authenticate,
  validate(conversationIdSchema, 'params'),
  chatController.getConversationById
);

/**
 * @route   DELETE /api/v1/chat/conversations/:id
 * @desc    Leave a conversation
 * @access  Participant only
 * @params  {id} - Conversation UUID
 */
router.delete(
  '/conversations/:id',
  authenticate,
  validate(conversationIdSchema, 'params'),
  chatController.leaveConversation
);

/**
 * @route   PATCH /api/v1/chat/conversations/:id/read
 * @desc    Mark conversation as read
 * @access  Participant only
 * @params  {id} - Conversation UUID
 */
router.patch(
  '/conversations/:id/read',
  authenticate,
  validate(conversationIdSchema, 'params'),
  chatController.markConversationAsRead
);

// ============= Message Routes =============

/**
 * @route   GET /api/v1/chat/conversations/:id/messages
 * @desc    Get messages for a conversation (paginated)
 * @access  Participant only
 * @params  {id} - Conversation UUID
 * @query   {page, limit, before?, after?}
 */
router.get(
  '/conversations/:id/messages',
  authenticate,
  validate(conversationIdSchema, 'params'),
  validate(listMessagesSchema, 'query'),
  chatController.getMessages
);

/**
 * @route   POST /api/v1/chat/conversations/:id/messages
 * @desc    Send a message to a conversation
 * @access  Participant only
 * @params  {id} - Conversation UUID
 * @body    {content: string, messageType?: 'text'|'image'|'file'|'location'|'system', metadata?: object}
 */
router.post(
  '/conversations/:id/messages',
  authenticate,
  validate(conversationIdSchema, 'params'),
  validate(sendMessageSchema, 'body'),
  chatController.sendMessage
);

module.exports = router;
