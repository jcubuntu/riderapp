'use strict';

const { Server } = require('socket.io');
const { verifyAccessToken } = require('../utils/jwt.utils');
const { ROLES, hasMinimumRole } = require('../constants/roles');
const logger = require('../utils/logger.utils');
const config = require('../config');

/**
 * Socket.IO Manager
 * Handles WebSocket connections, authentication, and event routing
 */

// Store for connected users
// Map of userId -> Set of socketIds
const connectedUsers = new Map();

// Store for socket -> user mapping
// Map of socketId -> { userId, role }
const socketToUser = new Map();

// Socket.io instance (will be set by initialize)
let io = null;

/**
 * Initialize Socket.IO with HTTP server
 * @param {http.Server} server - HTTP server instance
 * @returns {Server} Socket.IO server instance
 */
const initialize = (server) => {
  io = new Server(server, {
    cors: {
      origin: config.socket.corsOrigin,
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingTimeout: 60000,
    pingInterval: 25000,
    transports: ['websocket', 'polling'],
  });

  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.query.token;

      if (!token) {
        return next(new Error('AUTHENTICATION_REQUIRED'));
      }

      const decoded = verifyAccessToken(token);
      if (!decoded) {
        return next(new Error('INVALID_TOKEN'));
      }

      // Attach user info to socket
      socket.user = {
        id: decoded.userId,
        email: decoded.email,
        role: decoded.role,
      };

      logger.socket('auth:success', socket.id, { userId: decoded.userId, role: decoded.role });
      next();
    } catch (error) {
      logger.socket('auth:failed', socket.id, { error: error.message });

      if (error.name === 'TokenExpiredError') {
        return next(new Error('TOKEN_EXPIRED'));
      }
      return next(new Error('AUTHENTICATION_FAILED'));
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    handleConnection(socket);
  });

  logger.info('Socket.IO initialized');
  return io;
};

/**
 * Handle new socket connection
 * @param {Socket} socket - Socket.IO socket instance
 */
const handleConnection = (socket) => {
  const { user } = socket;

  logger.info(`Socket connected: ${socket.id}, userId: ${user.id}, role: ${user.role}`);

  // Store user connection
  addUserConnection(user.id, socket.id, user.role);

  // Auto-join user to their personal room
  socket.join(`user:${user.id}`);

  // Auto-join role-based room
  socket.join(`role:${user.role}`);

  // If police/admin/volunteer, join monitoring rooms
  if (hasMinimumRole(user.role, ROLES.VOLUNTEER)) {
    socket.join('monitoring');
  }

  // Emit connection success
  socket.emit('connected', {
    socketId: socket.id,
    userId: user.id,
    role: user.role,
    timestamp: new Date().toISOString(),
  });

  // Register event handlers
  registerEventHandlers(socket);

  // Handle disconnection
  socket.on('disconnect', (reason) => {
    handleDisconnection(socket, reason);
  });

  // Handle errors
  socket.on('error', (error) => {
    logger.error(`Socket error for ${socket.id}:`, error);
  });
};

/**
 * Handle socket disconnection
 * @param {Socket} socket - Socket.IO socket instance
 * @param {string} reason - Disconnection reason
 */
const handleDisconnection = (socket, reason) => {
  const { user } = socket;

  logger.info(`Socket disconnected: ${socket.id}, userId: ${user.id}, reason: ${reason}`);

  // Remove user connection
  removeUserConnection(user.id, socket.id);

  // Emit user offline event to monitoring room if no more connections
  if (!isUserOnline(user.id)) {
    io.to('monitoring').emit('user:offline', {
      userId: user.id,
      timestamp: new Date().toISOString(),
    });
  }
};

/**
 * Register event handlers for a socket
 * @param {Socket} socket - Socket.IO socket instance
 */
const registerEventHandlers = (socket) => {
  // Import and register handlers
  const chatHandler = require('./handlers/chat.handler');
  const notificationHandler = require('./handlers/notification.handler');
  const locationHandler = require('./handlers/location.handler');

  // Register all handlers
  chatHandler.register(socket, io);
  notificationHandler.register(socket, io);
  locationHandler.register(socket, io);

  // Common room management handlers
  registerRoomHandlers(socket);
};

/**
 * Register room management handlers
 * @param {Socket} socket - Socket.IO socket instance
 */
const registerRoomHandlers = (socket) => {
  // Join a room
  socket.on('room:join', (room) => {
    // Validate room name (prevent joining arbitrary rooms)
    if (!isValidRoom(room, socket.user)) {
      socket.emit('error', { message: 'Cannot join this room' });
      return;
    }

    socket.join(room);
    logger.socket('room:join', socket.id, { room, userId: socket.user.id });
    socket.emit('room:joined', { room, timestamp: new Date().toISOString() });
  });

  // Leave a room
  socket.on('room:leave', (room) => {
    socket.leave(room);
    logger.socket('room:leave', socket.id, { room, userId: socket.user.id });
    socket.emit('room:left', { room, timestamp: new Date().toISOString() });
  });

  // Get current rooms
  socket.on('room:list', () => {
    const rooms = Array.from(socket.rooms).filter((room) => room !== socket.id);
    socket.emit('room:list', { rooms });
  });
};

/**
 * Validate if a user can join a room
 * @param {string} room - Room name
 * @param {Object} user - User object
 * @returns {boolean}
 */
const isValidRoom = (room, user) => {
  // Users can join their own user room
  if (room === `user:${user.id}`) return true;

  // Users can join conversation rooms
  if (room.startsWith('conversation:')) return true;

  // Users can join incident rooms
  if (room.startsWith('incident:')) return true;

  // Police+ can join monitoring rooms
  if (room === 'monitoring' && hasMinimumRole(user.role, ROLES.VOLUNTEER)) return true;

  // Police+ can join location tracking rooms
  if (room.startsWith('tracking:') && hasMinimumRole(user.role, ROLES.POLICE)) return true;

  return false;
};

// ============= User Connection Management =============

/**
 * Add user connection
 * @param {string} userId - User ID
 * @param {string} socketId - Socket ID
 * @param {string} role - User role
 */
const addUserConnection = (userId, socketId, role) => {
  if (!connectedUsers.has(userId)) {
    connectedUsers.set(userId, new Set());
  }
  connectedUsers.get(userId).add(socketId);
  socketToUser.set(socketId, { userId, role });

  // Emit user online event to monitoring room
  if (connectedUsers.get(userId).size === 1) {
    io.to('monitoring').emit('user:online', {
      userId,
      role,
      timestamp: new Date().toISOString(),
    });
  }
};

/**
 * Remove user connection
 * @param {string} userId - User ID
 * @param {string} socketId - Socket ID
 */
const removeUserConnection = (userId, socketId) => {
  if (connectedUsers.has(userId)) {
    connectedUsers.get(userId).delete(socketId);
    if (connectedUsers.get(userId).size === 0) {
      connectedUsers.delete(userId);
    }
  }
  socketToUser.delete(socketId);
};

/**
 * Check if user is online
 * @param {string} userId - User ID
 * @returns {boolean}
 */
const isUserOnline = (userId) => {
  return connectedUsers.has(userId) && connectedUsers.get(userId).size > 0;
};

/**
 * Get user's socket IDs
 * @param {string} userId - User ID
 * @returns {string[]}
 */
const getUserSocketIds = (userId) => {
  if (!connectedUsers.has(userId)) return [];
  return Array.from(connectedUsers.get(userId));
};

/**
 * Get online users count
 * @returns {number}
 */
const getOnlineUsersCount = () => {
  return connectedUsers.size;
};

/**
 * Get online users by role
 * @returns {Object}
 */
const getOnlineUsersByRole = () => {
  const byRole = {};

  for (const [userId, socketIds] of connectedUsers) {
    const socketId = socketIds.values().next().value;
    const userInfo = socketToUser.get(socketId);
    if (userInfo) {
      const { role } = userInfo;
      if (!byRole[role]) byRole[role] = [];
      byRole[role].push(userId);
    }
  }

  return byRole;
};

// ============= Emit Helpers =============

/**
 * Emit event to a specific user
 * @param {string} userId - User ID
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
const emitToUser = (userId, event, data) => {
  if (!io) {
    logger.error('Socket.IO not initialized');
    return;
  }
  io.to(`user:${userId}`).emit(event, data);
  logger.socket('emit:user', 'server', { userId, event });
};

/**
 * Emit event to users with a specific role
 * @param {string} role - Role name
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
const emitToRole = (role, event, data) => {
  if (!io) {
    logger.error('Socket.IO not initialized');
    return;
  }
  io.to(`role:${role}`).emit(event, data);
  logger.socket('emit:role', 'server', { role, event });
};

/**
 * Emit event to all users with minimum role level
 * @param {string} minRole - Minimum role level
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
const emitToMinimumRole = (minRole, event, data) => {
  if (!io) {
    logger.error('Socket.IO not initialized');
    return;
  }

  const rolesToEmit = Object.values(ROLES).filter((role) =>
    hasMinimumRole(role, minRole)
  );

  rolesToEmit.forEach((role) => {
    io.to(`role:${role}`).emit(event, data);
  });

  logger.socket('emit:minRole', 'server', { minRole, event, roles: rolesToEmit });
};

/**
 * Emit event to a room
 * @param {string} room - Room name
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
const emitToRoom = (room, event, data) => {
  if (!io) {
    logger.error('Socket.IO not initialized');
    return;
  }
  io.to(room).emit(event, data);
  logger.socket('emit:room', 'server', { room, event });
};

/**
 * Emit event to all connected users
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
const emitToAll = (event, data) => {
  if (!io) {
    logger.error('Socket.IO not initialized');
    return;
  }
  io.emit(event, data);
  logger.socket('emit:all', 'server', { event });
};

/**
 * Get Socket.IO instance
 * @returns {Server|null}
 */
const getIO = () => io;

module.exports = {
  // Initialization
  initialize,
  getIO,

  // Connection management
  isUserOnline,
  getUserSocketIds,
  getOnlineUsersCount,
  getOnlineUsersByRole,

  // Emit helpers
  emitToUser,
  emitToRole,
  emitToMinimumRole,
  emitToRoom,
  emitToAll,
};
