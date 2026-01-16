'use strict';

const { errorResponse } = require('../utils/response.utils');
const { ROLES, ROLE_HIERARCHY } = require('../constants/roles');

/**
 * Role-based access control middleware
 * Checks if the authenticated user has one of the required roles
 * @param {...string} allowedRoles - Roles that are allowed to access the route
 * @returns {Function} Express middleware function
 */
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    // Check if user is authenticated
    if (!req.user) {
      return errorResponse(res, 'Authentication required.', 401);
    }

    const userRole = req.user.role;

    // Check if user's role is in the allowed roles
    if (!allowedRoles.includes(userRole)) {
      return errorResponse(
        res,
        `Access denied. Required role(s): ${allowedRoles.join(', ')}. Your role: ${userRole}`,
        403
      );
    }

    next();
  };
};

/**
 * Minimum role level middleware
 * Checks if the authenticated user has at least the minimum required role level
 * Role hierarchy: admin > police > rider
 * @param {string} minimumRole - Minimum role required
 * @returns {Function} Express middleware function
 */
const requireMinimumRole = (minimumRole) => {
  return (req, res, next) => {
    // Check if user is authenticated
    if (!req.user) {
      return errorResponse(res, 'Authentication required.', 401);
    }

    const userRole = req.user.role;
    const userRoleLevel = ROLE_HIERARCHY[userRole] || 0;
    const requiredRoleLevel = ROLE_HIERARCHY[minimumRole] || 0;

    if (userRoleLevel < requiredRoleLevel) {
      return errorResponse(
        res,
        `Access denied. Minimum role required: ${minimumRole}. Your role: ${userRole}`,
        403
      );
    }

    next();
  };
};

/**
 * Admin only middleware
 * Shorthand for requireRole(ROLES.ADMIN, ROLES.SUPER_ADMIN)
 */
const adminOnly = (req, res, next) => {
  if (!req.user) {
    return errorResponse(res, 'Authentication required.', 401);
  }

  if (req.user.role !== ROLES.ADMIN && req.user.role !== ROLES.SUPER_ADMIN) {
    return errorResponse(res, 'Admin access required.', 403);
  }

  next();
};

/**
 * Super Admin only middleware
 * Only allows super admin access
 */
const superAdminOnly = (req, res, next) => {
  if (!req.user) {
    return errorResponse(res, 'Authentication required.', 401);
  }

  if (req.user.role !== ROLES.SUPER_ADMIN) {
    return errorResponse(res, 'Super Admin access required.', 403);
  }

  next();
};

/**
 * Police or Admin middleware
 * Shorthand for requireRole(ROLES.POLICE, ROLES.ADMIN, ROLES.SUPER_ADMIN)
 */
const policeOrAdmin = (req, res, next) => {
  if (!req.user) {
    return errorResponse(res, 'Authentication required.', 401);
  }

  const allowedRoles = [ROLES.POLICE, ROLES.ADMIN, ROLES.SUPER_ADMIN];
  if (!allowedRoles.includes(req.user.role)) {
    return errorResponse(res, 'Police or Admin access required.', 403);
  }

  next();
};

/**
 * Volunteer or higher middleware
 * Allows volunteer, police, admin, and super_admin
 */
const volunteerOrHigher = (req, res, next) => {
  if (!req.user) {
    return errorResponse(res, 'Authentication required.', 401);
  }

  const allowedRoles = [ROLES.VOLUNTEER, ROLES.POLICE, ROLES.ADMIN, ROLES.SUPER_ADMIN];
  if (!allowedRoles.includes(req.user.role)) {
    return errorResponse(res, 'Volunteer or higher access required.', 403);
  }

  next();
};

/**
 * Owner or Admin middleware
 * Checks if user is the owner of the resource or an admin
 * @param {Function} getResourceOwnerId - Function that extracts owner ID from request
 * @returns {Function} Express middleware function
 */
const ownerOrAdmin = (getResourceOwnerId) => {
  return async (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Authentication required.', 401);
    }

    // Admins and Super Admins can access any resource
    if (req.user.role === ROLES.ADMIN || req.user.role === ROLES.SUPER_ADMIN) {
      return next();
    }

    try {
      // Get the owner ID of the resource
      const ownerId = await getResourceOwnerId(req);

      if (ownerId === null || ownerId === undefined) {
        return errorResponse(res, 'Resource not found.', 404);
      }

      // Check if the current user is the owner
      if (req.user.id !== ownerId) {
        return errorResponse(res, 'Access denied. You can only access your own resources.', 403);
      }

      next();
    } catch (error) {
      console.error('Owner check error:', error);
      return errorResponse(res, 'Error checking resource ownership.', 500);
    }
  };
};

/**
 * Self or Admin middleware
 * Checks if user is accessing their own data or is an admin
 * Useful for user profile routes
 * @param {string} paramName - Name of the request parameter containing user ID (default: 'id')
 */
const selfOrAdmin = (paramName = 'id') => {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Authentication required.', 401);
    }

    // Admins and Super Admins can access any user's data
    if (req.user.role === ROLES.ADMIN || req.user.role === ROLES.SUPER_ADMIN) {
      return next();
    }

    // Get the target user ID from params
    const targetUserId = req.params[paramName];

    // Check if user is accessing their own data
    if (req.user.id.toString() !== targetUserId.toString()) {
      return errorResponse(res, 'Access denied. You can only access your own data.', 403);
    }

    next();
  };
};

/**
 * Check if user has any of the specified permissions
 * This is a placeholder for a more complex permission system
 * @param {...string} permissions - Required permissions
 */
const hasPermission = (...permissions) => {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Authentication required.', 401);
    }

    // Super admins have all permissions
    if (req.user.role === ROLES.SUPER_ADMIN) {
      return next();
    }

    // Admins have all permissions except system config
    if (req.user.role === ROLES.ADMIN) {
      const adminRestricted = ['manage_admins', 'system_config'];
      if (!permissions.some((p) => adminRestricted.includes(p))) {
        return next();
      }
    }

    // This can be extended to check a permissions table
    // For now, we'll use role-based permissions
    const rolePermissions = {
      [ROLES.RIDER]: ['create_incident', 'view_own_incidents', 'update_profile'],
      [ROLES.VOLUNTEER]: [
        'create_incident',
        'view_own_incidents',
        'view_all_incidents',
        'update_profile',
        'view_dashboard',
      ],
      [ROLES.POLICE]: [
        'create_incident',
        'view_own_incidents',
        'view_all_incidents',
        'update_incident_status',
        'update_profile',
        'approve_users',
      ],
      [ROLES.ADMIN]: ['all'],
      [ROLES.SUPER_ADMIN]: ['all'],
    };

    const userPermissions = rolePermissions[req.user.role] || [];

    const hasRequiredPermission = permissions.some(
      (permission) => userPermissions.includes(permission) || userPermissions.includes('all')
    );

    if (!hasRequiredPermission) {
      return errorResponse(
        res,
        `Access denied. Required permission(s): ${permissions.join(', ')}`,
        403
      );
    }

    next();
  };
};

module.exports = {
  requireRole,
  requireMinimumRole,
  adminOnly,
  superAdminOnly,
  policeOrAdmin,
  volunteerOrHigher,
  ownerOrAdmin,
  selfOrAdmin,
  hasPermission,
};
