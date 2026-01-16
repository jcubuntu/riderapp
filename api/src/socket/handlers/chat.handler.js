'use strict';

const logger = require('../../utils/logger.utils');

/**
 * Chat Socket Handler
 * Handles real-time chat events: messages, typing indicators, read receipts
 */

// Track typing users per conversation
// Map of conversationId -> Map of userId -> timeout
const typingUsers = new Map();

// Typing timeout in milliseconds (stop typing indicator after this time)
const TYPING_TIMEOUT = 3000;

/**
 * Register chat event handlers on a socket
 * @param {Socket} socket - Socket.IO socket instance
 * @param {Server} io - Socket.IO server instance
 */
const register = (socket, io) => {
  const { user } = socket;

  // ============= Message Events =============

  /**
   * Handle new message event
   * Broadcasts the message to all participants in the conversation
   */
  socket.on('message:new', (data) => {
    try {
      const { conversationId, message } = data;

      if (!conversationId || !message) {
        socket.emit('error', { message: 'Invalid message data' });
        return;
      }

      logger.socket('message:new', socket.id, { conversationId, senderId: user.id });

      // Broadcast to conversation room (excluding sender)
      socket.to(`conversation:${conversationId}`).emit('message:new', {
        conversationId,
        message: {
          ...message,
          senderId: user.id,
          timestamp: new Date().toISOString(),
        },
      });

      // Clear typing indicator for this user
      clearTyping(conversationId, user.id, io);

      // Acknowledge message sent
      socket.emit('message:sent', {
        conversationId,
        messageId: message.id,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling message:new', error);
      socket.emit('error', { message: 'Failed to send message' });
    }
  });

  /**
   * Handle message read event
   * Notifies sender that their message has been read
   */
  socket.on('message:read', (data) => {
    try {
      const { conversationId, messageId, readAt } = data;

      if (!conversationId) {
        socket.emit('error', { message: 'Conversation ID required' });
        return;
      }

      logger.socket('message:read', socket.id, { conversationId, userId: user.id });

      // Broadcast read receipt to conversation room
      socket.to(`conversation:${conversationId}`).emit('message:read', {
        conversationId,
        messageId,
        readBy: user.id,
        readAt: readAt || new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling message:read', error);
    }
  });

  /**
   * Handle messages read (bulk) event
   * Marks all messages in conversation as read
   */
  socket.on('messages:read', (data) => {
    try {
      const { conversationId, lastMessageId } = data;

      if (!conversationId) {
        socket.emit('error', { message: 'Conversation ID required' });
        return;
      }

      logger.socket('messages:read', socket.id, { conversationId, userId: user.id });

      // Broadcast bulk read to conversation room
      socket.to(`conversation:${conversationId}`).emit('messages:read', {
        conversationId,
        readBy: user.id,
        lastMessageId,
        readAt: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling messages:read', error);
    }
  });

  // ============= Typing Events =============

  /**
   * Handle typing start event
   * Notifies other participants that user is typing
   */
  socket.on('typing:start', (data) => {
    try {
      const { conversationId } = data;

      if (!conversationId) {
        socket.emit('error', { message: 'Conversation ID required' });
        return;
      }

      logger.socket('typing:start', socket.id, { conversationId, userId: user.id });

      // Set typing state with auto-clear timeout
      setTyping(conversationId, user.id, io);

      // Broadcast typing indicator to conversation room
      socket.to(`conversation:${conversationId}`).emit('typing:start', {
        conversationId,
        userId: user.id,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling typing:start', error);
    }
  });

  /**
   * Handle typing stop event
   * Notifies other participants that user stopped typing
   */
  socket.on('typing:stop', (data) => {
    try {
      const { conversationId } = data;

      if (!conversationId) {
        socket.emit('error', { message: 'Conversation ID required' });
        return;
      }

      logger.socket('typing:stop', socket.id, { conversationId, userId: user.id });

      // Clear typing state
      clearTyping(conversationId, user.id, io);

      // Broadcast typing stop to conversation room
      socket.to(`conversation:${conversationId}`).emit('typing:stop', {
        conversationId,
        userId: user.id,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling typing:stop', error);
    }
  });

  // ============= Conversation Events =============

  /**
   * Handle join conversation event
   * Joins the user to a conversation room
   */
  socket.on('conversation:join', (data) => {
    try {
      const { conversationId } = data;

      if (!conversationId) {
        socket.emit('error', { message: 'Conversation ID required' });
        return;
      }

      const room = `conversation:${conversationId}`;
      socket.join(room);

      logger.socket('conversation:join', socket.id, { conversationId, userId: user.id });

      // Notify others in conversation that user joined
      socket.to(room).emit('conversation:user:joined', {
        conversationId,
        userId: user.id,
        timestamp: new Date().toISOString(),
      });

      // Acknowledge join
      socket.emit('conversation:joined', {
        conversationId,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling conversation:join', error);
    }
  });

  /**
   * Handle leave conversation event
   * Removes user from conversation room
   */
  socket.on('conversation:leave', (data) => {
    try {
      const { conversationId } = data;

      if (!conversationId) {
        socket.emit('error', { message: 'Conversation ID required' });
        return;
      }

      const room = `conversation:${conversationId}`;

      // Clear typing indicator before leaving
      clearTyping(conversationId, user.id, io);

      // Notify others in conversation that user left
      socket.to(room).emit('conversation:user:left', {
        conversationId,
        userId: user.id,
        timestamp: new Date().toISOString(),
      });

      socket.leave(room);

      logger.socket('conversation:leave', socket.id, { conversationId, userId: user.id });

      // Acknowledge leave
      socket.emit('conversation:left', {
        conversationId,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling conversation:leave', error);
    }
  });

  /**
   * Handle get typing users event
   * Returns list of currently typing users in a conversation
   */
  socket.on('conversation:typing:list', (data) => {
    try {
      const { conversationId } = data;

      if (!conversationId) {
        socket.emit('error', { message: 'Conversation ID required' });
        return;
      }

      const typing = getTypingUsers(conversationId);

      socket.emit('conversation:typing:list', {
        conversationId,
        typingUsers: typing,
      });
    } catch (error) {
      logger.error('Error handling conversation:typing:list', error);
    }
  });

  // Clean up on disconnect
  socket.on('disconnect', () => {
    // Clear all typing indicators for this user
    clearAllTypingForUser(user.id, io);
  });
};

// ============= Typing State Management =============

/**
 * Set typing state for a user in a conversation
 * @param {string} conversationId - Conversation ID
 * @param {string} userId - User ID
 * @param {Server} io - Socket.IO server instance
 */
const setTyping = (conversationId, userId, io) => {
  if (!typingUsers.has(conversationId)) {
    typingUsers.set(conversationId, new Map());
  }

  const conversationTyping = typingUsers.get(conversationId);

  // Clear existing timeout if any
  if (conversationTyping.has(userId)) {
    clearTimeout(conversationTyping.get(userId));
  }

  // Set new timeout to auto-clear typing
  const timeout = setTimeout(() => {
    clearTyping(conversationId, userId, io);
    // Broadcast auto-clear
    io.to(`conversation:${conversationId}`).emit('typing:stop', {
      conversationId,
      userId,
      timestamp: new Date().toISOString(),
    });
  }, TYPING_TIMEOUT);

  conversationTyping.set(userId, timeout);
};

/**
 * Clear typing state for a user in a conversation
 * @param {string} conversationId - Conversation ID
 * @param {string} userId - User ID
 * @param {Server} io - Socket.IO server instance (unused but kept for consistency)
 */
const clearTyping = (conversationId, userId, io) => {
  if (!typingUsers.has(conversationId)) return;

  const conversationTyping = typingUsers.get(conversationId);
  if (conversationTyping.has(userId)) {
    clearTimeout(conversationTyping.get(userId));
    conversationTyping.delete(userId);
  }

  // Clean up empty conversation map
  if (conversationTyping.size === 0) {
    typingUsers.delete(conversationId);
  }
};

/**
 * Clear all typing states for a user (on disconnect)
 * @param {string} userId - User ID
 * @param {Server} io - Socket.IO server instance
 */
const clearAllTypingForUser = (userId, io) => {
  for (const [conversationId, conversationTyping] of typingUsers) {
    if (conversationTyping.has(userId)) {
      clearTimeout(conversationTyping.get(userId));
      conversationTyping.delete(userId);

      // Broadcast typing stop
      io.to(`conversation:${conversationId}`).emit('typing:stop', {
        conversationId,
        userId,
        timestamp: new Date().toISOString(),
      });

      // Clean up empty conversation map
      if (conversationTyping.size === 0) {
        typingUsers.delete(conversationId);
      }
    }
  }
};

/**
 * Get list of typing users in a conversation
 * @param {string} conversationId - Conversation ID
 * @returns {string[]} Array of user IDs
 */
const getTypingUsers = (conversationId) => {
  if (!typingUsers.has(conversationId)) return [];
  return Array.from(typingUsers.get(conversationId).keys());
};

// ============= Emit Helpers for External Use =============

/**
 * Emit new message event to a conversation (from server/service)
 * @param {Server} io - Socket.IO server instance
 * @param {string} conversationId - Conversation ID
 * @param {Object} message - Message data
 */
const emitNewMessage = (io, conversationId, message) => {
  io.to(`conversation:${conversationId}`).emit('message:new', {
    conversationId,
    message,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Emit conversation update event
 * @param {Server} io - Socket.IO server instance
 * @param {string} conversationId - Conversation ID
 * @param {Object} updates - Update data
 */
const emitConversationUpdate = (io, conversationId, updates) => {
  io.to(`conversation:${conversationId}`).emit('conversation:updated', {
    conversationId,
    updates,
    timestamp: new Date().toISOString(),
  });
};

module.exports = {
  register,
  emitNewMessage,
  emitConversationUpdate,
};
