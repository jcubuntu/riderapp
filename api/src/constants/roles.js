'use strict';

/**
 * User role constants
 * Defines the available user roles in the system
 */
const ROLES = Object.freeze({
  RIDER: 'rider',
  VOLUNTEER: 'volunteer',
  POLICE: 'police',
  COMMANDER: 'commander',
  ADMIN: 'admin',
  SUPER_ADMIN: 'super_admin',
});

/**
 * Role hierarchy levels
 * Higher number = higher privilege level
 */
const ROLE_HIERARCHY = Object.freeze({
  [ROLES.RIDER]: 1,
  [ROLES.VOLUNTEER]: 2,
  [ROLES.POLICE]: 3,
  [ROLES.COMMANDER]: 4,
  [ROLES.ADMIN]: 5,
  [ROLES.SUPER_ADMIN]: 6,
});

/**
 * Get all roles as an array
 * @returns {string[]} Array of role values
 */
const getAllRoles = () => Object.values(ROLES);

/**
 * Check if a role is valid
 * @param {string} role - Role to check
 * @returns {boolean} True if valid role
 */
const isValidRole = (role) => getAllRoles().includes(role);

/**
 * Get role display name
 * @param {string} role - Role value
 * @returns {string} Display name
 */
const getRoleDisplayName = (role) => {
  const displayNames = {
    [ROLES.RIDER]: 'Rider',
    [ROLES.VOLUNTEER]: 'Volunteer',
    [ROLES.POLICE]: 'Police Officer',
    [ROLES.COMMANDER]: 'Commander',
    [ROLES.ADMIN]: 'Administrator',
    [ROLES.SUPER_ADMIN]: 'Super Administrator',
  };
  return displayNames[role] || role;
};

/**
 * Get role description
 * @param {string} role - Role value
 * @returns {string} Role description
 */
const getRoleDescription = (role) => {
  const descriptions = {
    [ROLES.RIDER]: 'A motorcycle rider who can report incidents and view their own reports',
    [ROLES.VOLUNTEER]: 'A police volunteer who assists with incident coordination and monitoring',
    [ROLES.POLICE]: 'A police officer who can manage incidents and track riders',
    [ROLES.COMMANDER]: 'A commanding officer who oversees police operations and approves actions',
    [ROLES.ADMIN]: 'A system administrator with full access to all features',
    [ROLES.SUPER_ADMIN]: 'A super administrator with full system control including admin management and system configuration',
  };
  return descriptions[role] || 'Unknown role';
};

/**
 * Check if role has permission level
 * @param {string} userRole - User's role
 * @param {string} requiredRole - Minimum required role
 * @returns {boolean} True if user has sufficient permission
 */
const hasMinimumRole = (userRole, requiredRole) => {
  const userLevel = ROLE_HIERARCHY[userRole] || 0;
  const requiredLevel = ROLE_HIERARCHY[requiredRole] || 0;
  return userLevel >= requiredLevel;
};

/**
 * Compare two roles
 * @param {string} roleA - First role
 * @param {string} roleB - Second role
 * @returns {number} Positive if A > B, negative if A < B, 0 if equal
 */
const compareRoles = (roleA, roleB) => {
  const levelA = ROLE_HIERARCHY[roleA] || 0;
  const levelB = ROLE_HIERARCHY[roleB] || 0;
  return levelA - levelB;
};

/**
 * Get roles that can be assigned by a given role
 * Admins can assign all roles, police can assign riders, riders can't assign
 * @param {string} assignerRole - Role of the person assigning
 * @returns {string[]} Array of assignable roles
 */
const getAssignableRoles = (assignerRole) => {
  switch (assignerRole) {
    case ROLES.SUPER_ADMIN:
      return [ROLES.RIDER, ROLES.VOLUNTEER, ROLES.POLICE, ROLES.COMMANDER, ROLES.ADMIN, ROLES.SUPER_ADMIN];
    case ROLES.ADMIN:
      return [ROLES.RIDER, ROLES.VOLUNTEER, ROLES.POLICE, ROLES.COMMANDER, ROLES.ADMIN];
    case ROLES.COMMANDER:
      return [ROLES.RIDER, ROLES.VOLUNTEER, ROLES.POLICE];
    case ROLES.POLICE:
      return [ROLES.RIDER, ROLES.VOLUNTEER];
    default:
      return [];
  }
};

/**
 * Role-based feature permissions
 */
const ROLE_PERMISSIONS = Object.freeze({
  [ROLES.RIDER]: {
    canCreateIncident: true,
    canViewOwnIncidents: true,
    canUpdateOwnIncidents: true,
    canDeleteOwnIncidents: false,
    canViewAllIncidents: false,
    canManageUsers: false,
    canApproveUsers: false,
    canViewDashboard: false,
    canAccessAdmin: false,
    canManageAdmins: false,
    canAccessSystemConfig: false,
  },
  [ROLES.VOLUNTEER]: {
    canCreateIncident: true,
    canViewOwnIncidents: true,
    canUpdateOwnIncidents: true,
    canDeleteOwnIncidents: false,
    canViewAllIncidents: true,
    canManageUsers: false,
    canApproveUsers: false,
    canViewDashboard: true,
    canAccessAdmin: false,
    canManageAdmins: false,
    canAccessSystemConfig: false,
  },
  [ROLES.POLICE]: {
    canCreateIncident: true,
    canViewOwnIncidents: true,
    canUpdateOwnIncidents: true,
    canDeleteOwnIncidents: false,
    canViewAllIncidents: true,
    canManageUsers: false,
    canApproveUsers: true,
    canViewDashboard: true,
    canAccessAdmin: false,
    canManageAdmins: false,
    canAccessSystemConfig: false,
  },
  [ROLES.COMMANDER]: {
    canCreateIncident: true,
    canViewOwnIncidents: true,
    canUpdateOwnIncidents: true,
    canDeleteOwnIncidents: true,
    canViewAllIncidents: true,
    canManageUsers: true,
    canApproveUsers: true,
    canViewDashboard: true,
    canAccessAdmin: false,
    canManageAdmins: false,
    canAccessSystemConfig: false,
  },
  [ROLES.ADMIN]: {
    canCreateIncident: true,
    canViewOwnIncidents: true,
    canUpdateOwnIncidents: true,
    canDeleteOwnIncidents: true,
    canViewAllIncidents: true,
    canManageUsers: true,
    canApproveUsers: true,
    canViewDashboard: true,
    canAccessAdmin: true,
    canManageAdmins: false,
    canAccessSystemConfig: false,
  },
  [ROLES.SUPER_ADMIN]: {
    canCreateIncident: true,
    canViewOwnIncidents: true,
    canUpdateOwnIncidents: true,
    canDeleteOwnIncidents: true,
    canViewAllIncidents: true,
    canManageUsers: true,
    canApproveUsers: true,
    canViewDashboard: true,
    canAccessAdmin: true,
    canManageAdmins: true,
    canAccessSystemConfig: true,
  },
});

/**
 * Check if a role has a specific permission
 * @param {string} role - User role
 * @param {string} permission - Permission to check
 * @returns {boolean} True if role has the permission
 */
const hasPermission = (role, permission) => {
  const permissions = ROLE_PERMISSIONS[role];
  if (!permissions) return false;
  return permissions[permission] === true;
};

module.exports = {
  ROLES,
  ROLE_HIERARCHY,
  ROLE_PERMISSIONS,
  getAllRoles,
  isValidRole,
  getRoleDisplayName,
  getRoleDescription,
  hasMinimumRole,
  compareRoles,
  getAssignableRoles,
  hasPermission,
};
