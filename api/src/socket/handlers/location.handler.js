'use strict';

const logger = require('../../utils/logger.utils');
const { ROLES, hasMinimumRole } = require('../../constants/roles');

/**
 * Location Socket Handler
 * Handles real-time location events: updates, subscriptions, tracking
 */

// Track location subscriptions
// Map of riderId -> Set of subscriberId (police/admin watching this rider)
const riderSubscribers = new Map();

// Track which riders a user is subscribed to
// Map of subscriberId -> Set of riderIds
const userSubscriptions = new Map();

/**
 * Register location event handlers on a socket
 * @param {Socket} socket - Socket.IO socket instance
 * @param {Server} io - Socket.IO server instance
 */
const register = (socket, io) => {
  const { user } = socket;

  // ============= Location Update Events =============

  /**
   * Handle location update event (from riders)
   * Broadcasts location to subscribed police/admin users
   */
  socket.on('location:update', (data) => {
    try {
      const { latitude, longitude, accuracy, altitude, speed, heading, batteryLevel, address } = data;

      if (latitude === undefined || longitude === undefined) {
        socket.emit('error', { message: 'Latitude and longitude required' });
        return;
      }

      logger.socket('location:update', socket.id, { userId: user.id, latitude, longitude });

      const locationData = {
        riderId: user.id,
        riderRole: user.role,
        coordinates: {
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
        },
        accuracy: accuracy ? parseFloat(accuracy) : null,
        altitude: altitude ? parseFloat(altitude) : null,
        speed: speed ? parseFloat(speed) : null,
        heading: heading ? parseFloat(heading) : null,
        batteryLevel: batteryLevel || null,
        address: address || null,
        timestamp: new Date().toISOString(),
      };

      // Broadcast to all subscribers of this rider
      const subscribers = riderSubscribers.get(user.id);
      if (subscribers && subscribers.size > 0) {
        subscribers.forEach((subscriberId) => {
          io.to(`user:${subscriberId}`).emit('rider:location', locationData);
        });
      }

      // Also broadcast to general tracking room for monitoring dashboard
      io.to('tracking:all').emit('rider:location', locationData);

      // Acknowledge update
      socket.emit('location:updated', {
        timestamp: locationData.timestamp,
      });
    } catch (error) {
      logger.error('Error handling location:update', error);
      socket.emit('error', { message: 'Failed to update location' });
    }
  });

  /**
   * Handle location sharing toggle
   */
  socket.on('location:sharing:toggle', (data) => {
    try {
      const { enabled } = data;

      logger.socket('location:sharing:toggle', socket.id, { userId: user.id, enabled });

      // Broadcast sharing status change to monitoring
      io.to('monitoring').emit('rider:sharing:changed', {
        riderId: user.id,
        enabled: Boolean(enabled),
        timestamp: new Date().toISOString(),
      });

      socket.emit('location:sharing:toggled', {
        enabled: Boolean(enabled),
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling location:sharing:toggle', error);
    }
  });

  // ============= Subscription Events (for Police/Admin) =============

  /**
   * Handle subscribe to rider's location
   * Only police+ can subscribe to track specific riders
   */
  socket.on('location:subscribe', (data) => {
    try {
      const { riderId } = data;

      // Check permission
      if (!hasMinimumRole(user.role, ROLES.POLICE)) {
        socket.emit('error', { message: 'Permission denied' });
        return;
      }

      if (!riderId) {
        socket.emit('error', { message: 'Rider ID required' });
        return;
      }

      logger.socket('location:subscribe', socket.id, { subscriberId: user.id, riderId });

      // Add subscription
      addSubscription(user.id, riderId);

      // Join rider's tracking room
      socket.join(`tracking:${riderId}`);

      socket.emit('location:subscribed', {
        riderId,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling location:subscribe', error);
    }
  });

  /**
   * Handle unsubscribe from rider's location
   */
  socket.on('location:unsubscribe', (data) => {
    try {
      const { riderId } = data;

      if (!riderId) {
        socket.emit('error', { message: 'Rider ID required' });
        return;
      }

      logger.socket('location:unsubscribe', socket.id, { subscriberId: user.id, riderId });

      // Remove subscription
      removeSubscription(user.id, riderId);

      // Leave rider's tracking room
      socket.leave(`tracking:${riderId}`);

      socket.emit('location:unsubscribed', {
        riderId,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling location:unsubscribe', error);
    }
  });

  /**
   * Handle subscribe to all rider locations (monitoring dashboard)
   */
  socket.on('location:subscribe:all', () => {
    try {
      // Check permission
      if (!hasMinimumRole(user.role, ROLES.POLICE)) {
        socket.emit('error', { message: 'Permission denied' });
        return;
      }

      logger.socket('location:subscribe:all', socket.id, { subscriberId: user.id });

      // Join the all-tracking room
      socket.join('tracking:all');

      socket.emit('location:subscribed:all', {
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling location:subscribe:all', error);
    }
  });

  /**
   * Handle unsubscribe from all rider locations
   */
  socket.on('location:unsubscribe:all', () => {
    try {
      logger.socket('location:unsubscribe:all', socket.id, { subscriberId: user.id });

      // Leave the all-tracking room
      socket.leave('tracking:all');

      socket.emit('location:unsubscribed:all', {
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling location:unsubscribe:all', error);
    }
  });

  /**
   * Handle get subscribed riders list
   */
  socket.on('location:subscriptions:list', () => {
    try {
      const subscriptions = userSubscriptions.get(user.id);
      const riderIds = subscriptions ? Array.from(subscriptions) : [];

      socket.emit('location:subscriptions:list', {
        riderIds,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error handling location:subscriptions:list', error);
    }
  });

  // ============= Emergency Location Events =============

  /**
   * Handle emergency location broadcast
   * Immediately broadcasts location to all police/admin with high priority
   */
  socket.on('location:emergency', (data) => {
    try {
      const { latitude, longitude, message } = data;

      if (latitude === undefined || longitude === undefined) {
        socket.emit('error', { message: 'Latitude and longitude required' });
        return;
      }

      logger.socket('location:emergency', socket.id, { userId: user.id, latitude, longitude });

      const emergencyData = {
        riderId: user.id,
        riderRole: user.role,
        coordinates: {
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
        },
        message: message || 'Emergency alert',
        timestamp: new Date().toISOString(),
        priority: 'urgent',
      };

      // Broadcast to all police and admin
      io.to(`role:${ROLES.POLICE}`)
        .to(`role:${ROLES.ADMIN}`)
        .to(`role:${ROLES.SUPER_ADMIN}`)
        .emit('rider:emergency', emergencyData);

      // Also emit to monitoring room
      io.to('monitoring').emit('rider:emergency', emergencyData);

      // Acknowledge
      socket.emit('location:emergency:sent', {
        timestamp: emergencyData.timestamp,
      });
    } catch (error) {
      logger.error('Error handling location:emergency', error);
      socket.emit('error', { message: 'Failed to send emergency alert' });
    }
  });

  // Clean up subscriptions on disconnect
  socket.on('disconnect', () => {
    clearUserSubscriptions(user.id);
  });
};

// ============= Subscription Management =============

/**
 * Add subscription (subscriber watches rider)
 * @param {string} subscriberId - Subscriber user ID
 * @param {string} riderId - Rider user ID
 */
const addSubscription = (subscriberId, riderId) => {
  // Add to rider's subscribers
  if (!riderSubscribers.has(riderId)) {
    riderSubscribers.set(riderId, new Set());
  }
  riderSubscribers.get(riderId).add(subscriberId);

  // Add to user's subscriptions
  if (!userSubscriptions.has(subscriberId)) {
    userSubscriptions.set(subscriberId, new Set());
  }
  userSubscriptions.get(subscriberId).add(riderId);
};

/**
 * Remove subscription
 * @param {string} subscriberId - Subscriber user ID
 * @param {string} riderId - Rider user ID
 */
const removeSubscription = (subscriberId, riderId) => {
  // Remove from rider's subscribers
  if (riderSubscribers.has(riderId)) {
    riderSubscribers.get(riderId).delete(subscriberId);
    if (riderSubscribers.get(riderId).size === 0) {
      riderSubscribers.delete(riderId);
    }
  }

  // Remove from user's subscriptions
  if (userSubscriptions.has(subscriberId)) {
    userSubscriptions.get(subscriberId).delete(riderId);
    if (userSubscriptions.get(subscriberId).size === 0) {
      userSubscriptions.delete(subscriberId);
    }
  }
};

/**
 * Clear all subscriptions for a user (on disconnect)
 * @param {string} userId - User ID
 */
const clearUserSubscriptions = (userId) => {
  // Clear subscriptions where user is the subscriber
  if (userSubscriptions.has(userId)) {
    const riderIds = userSubscriptions.get(userId);
    riderIds.forEach((riderId) => {
      if (riderSubscribers.has(riderId)) {
        riderSubscribers.get(riderId).delete(userId);
        if (riderSubscribers.get(riderId).size === 0) {
          riderSubscribers.delete(riderId);
        }
      }
    });
    userSubscriptions.delete(userId);
  }

  // Clear subscriptions where user is the rider being tracked
  if (riderSubscribers.has(userId)) {
    riderSubscribers.delete(userId);
  }
};

// ============= Emit Helpers for External Use (Service Layer) =============

/**
 * Emit location update from server/service (e.g., after HTTP update)
 * @param {Server} io - Socket.IO server instance
 * @param {string} riderId - Rider user ID
 * @param {Object} location - Location data
 */
const emitLocationUpdate = (io, riderId, location) => {
  const locationData = {
    riderId,
    coordinates: location.coordinates,
    accuracy: location.accuracy,
    altitude: location.altitude,
    speed: location.speed,
    heading: location.heading,
    batteryLevel: location.batteryLevel,
    address: location.address,
    timestamp: new Date().toISOString(),
  };

  // Emit to rider's subscribers
  const subscribers = riderSubscribers.get(riderId);
  if (subscribers && subscribers.size > 0) {
    subscribers.forEach((subscriberId) => {
      io.to(`user:${subscriberId}`).emit('rider:location', locationData);
    });
  }

  // Also broadcast to all-tracking room
  io.to('tracking:all').emit('rider:location', locationData);

  logger.socket('location:update:server', 'server', { riderId });
};

/**
 * Emit emergency alert from server/service
 * @param {Server} io - Socket.IO server instance
 * @param {Object} emergencyData - Emergency data
 */
const emitEmergencyAlert = (io, emergencyData) => {
  io.to(`role:${ROLES.POLICE}`)
    .to(`role:${ROLES.ADMIN}`)
    .to(`role:${ROLES.SUPER_ADMIN}`)
    .emit('rider:emergency', {
      ...emergencyData,
      timestamp: new Date().toISOString(),
      priority: 'urgent',
    });

  io.to('monitoring').emit('rider:emergency', {
    ...emergencyData,
    timestamp: new Date().toISOString(),
    priority: 'urgent',
  });

  logger.socket('rider:emergency:server', 'server', { riderId: emergencyData.riderId });
};

/**
 * Emit rider sharing status change
 * @param {Server} io - Socket.IO server instance
 * @param {string} riderId - Rider user ID
 * @param {boolean} isSharing - Sharing status
 */
const emitSharingStatusChange = (io, riderId, isSharing) => {
  io.to('monitoring').emit('rider:sharing:changed', {
    riderId,
    isSharing: Boolean(isSharing),
    timestamp: new Date().toISOString(),
  });
};

/**
 * Get number of subscribers for a rider
 * @param {string} riderId - Rider user ID
 * @returns {number}
 */
const getSubscriberCount = (riderId) => {
  if (!riderSubscribers.has(riderId)) return 0;
  return riderSubscribers.get(riderId).size;
};

/**
 * Get total number of active tracking subscriptions
 * @returns {Object}
 */
const getTrackingStats = () => {
  return {
    ridersBeingTracked: riderSubscribers.size,
    activeSubscribers: userSubscriptions.size,
    totalSubscriptions: Array.from(userSubscriptions.values()).reduce(
      (sum, set) => sum + set.size,
      0
    ),
  };
};

module.exports = {
  register,

  // Emit helpers
  emitLocationUpdate,
  emitEmergencyAlert,
  emitSharingStatusChange,

  // Stats
  getSubscriberCount,
  getTrackingStats,
};
