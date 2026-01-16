'use strict';

const usersRepository = require('./users.repository');
const { ROLES, getAssignableRoles, hasMinimumRole, isValidRole } = require('../../constants/roles');

/**
 * Users Service - Business logic for user management
 */

/**
 * Get all users with pagination and filtering
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getUsers = async (options = {}) => {
  const { users, total } = await usersRepository.findAll(options);

  return {
    users: users.map(formatUser),
    total,
    page: options.page || 1,
    limit: options.limit || 10,
  };
};

/**
 * Get users pending approval
 * @param {Object} options - Query options
 * @returns {Promise<Object>}
 */
const getPendingUsers = async (options = {}) => {
  const { users, total } = await usersRepository.findPending(options);

  return {
    users: users.map(formatUser),
    total,
    page: options.page || 1,
    limit: options.limit || 10,
  };
};

/**
 * Get user by ID
 * @param {string} id - User UUID
 * @param {boolean} includeApprover - Include approver details
 * @returns {Promise<Object|null>}
 */
const getUserById = async (id, includeApprover = false) => {
  const user = includeApprover
    ? await usersRepository.findByIdWithApprover(id)
    : await usersRepository.findById(id);

  if (!user) {
    return null;
  }

  return formatUser(user);
};

/**
 * Update user
 * @param {string} id - User UUID
 * @param {Object} updates - Fields to update
 * @param {Object} currentUser - User performing the update
 * @returns {Promise<Object>}
 */
const updateUser = async (id, updates, currentUser) => {
  // Get the target user
  const targetUser = await usersRepository.findById(id);
  if (!targetUser) {
    throw new Error('USER_NOT_FOUND');
  }

  // Check permissions
  const isSelf = currentUser.id === id;
  const isAdmin = hasMinimumRole(currentUser.role, ROLES.ADMIN);

  if (!isSelf && !isAdmin) {
    throw new Error('ACCESS_DENIED');
  }

  // Non-admins can only update limited fields
  if (!isAdmin) {
    const allowedFieldsForSelf = ['phone', 'fullName', 'affiliation', 'address', 'profileImageUrl'];
    const filteredUpdates = {};
    for (const key of allowedFieldsForSelf) {
      if (updates[key] !== undefined) {
        filteredUpdates[key] = updates[key];
      }
    }
    updates = filteredUpdates;
  }

  // Validate email uniqueness if being updated
  if (updates.email && updates.email !== targetUser.email) {
    const emailTaken = await usersRepository.isEmailTaken(updates.email, id);
    if (emailTaken) {
      throw new Error('EMAIL_TAKEN');
    }
  }

  // Validate phone uniqueness if being updated
  if (updates.phone && updates.phone !== targetUser.phone) {
    const phoneTaken = await usersRepository.isPhoneTaken(updates.phone, id);
    if (phoneTaken) {
      throw new Error('PHONE_TAKEN');
    }
  }

  // Validate ID card uniqueness if being updated
  if (updates.idCardNumber && updates.idCardNumber !== targetUser.id_card_number) {
    const idCardTaken = await usersRepository.isIdCardTaken(updates.idCardNumber, id);
    if (idCardTaken) {
      throw new Error('ID_CARD_TAKEN');
    }
  }

  const updatedUser = await usersRepository.update(id, updates);
  return formatUser(updatedUser);
};

/**
 * Update user status
 * @param {string} id - User UUID
 * @param {string} status - New status
 * @param {Object} currentUser - User performing the update
 * @returns {Promise<Object>}
 */
const updateUserStatus = async (id, status, currentUser) => {
  const validStatuses = ['pending', 'approved', 'rejected', 'inactive'];
  if (!validStatuses.includes(status)) {
    throw new Error('INVALID_STATUS');
  }

  // Get the target user
  const targetUser = await usersRepository.findById(id);
  if (!targetUser) {
    throw new Error('USER_NOT_FOUND');
  }

  // Cannot change own status
  if (currentUser.id === id) {
    throw new Error('CANNOT_CHANGE_OWN_STATUS');
  }

  // Police can only approve/reject, admins can do anything
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  // Police can only approve/reject pending users
  if (currentUser.role === ROLES.POLICE && targetUser.status !== 'pending') {
    throw new Error('ACCESS_DENIED');
  }

  const updatedUser = await usersRepository.updateStatus(id, status, currentUser.id);
  return formatUser(updatedUser);
};

/**
 * Approve user
 * @param {string} id - User UUID
 * @param {Object} currentUser - User performing the approval
 * @returns {Promise<Object>}
 */
const approveUser = async (id, currentUser) => {
  // Get the target user
  const targetUser = await usersRepository.findById(id);
  if (!targetUser) {
    throw new Error('USER_NOT_FOUND');
  }

  // User must be pending
  if (targetUser.status !== 'pending') {
    throw new Error('USER_NOT_PENDING');
  }

  // Cannot approve yourself
  if (currentUser.id === id) {
    throw new Error('CANNOT_APPROVE_SELF');
  }

  // Check permission (police+ can approve)
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  const updatedUser = await usersRepository.updateStatus(id, 'approved', currentUser.id);
  return formatUser(updatedUser);
};

/**
 * Reject user
 * @param {string} id - User UUID
 * @param {string} reason - Rejection reason
 * @param {Object} currentUser - User performing the rejection
 * @returns {Promise<Object>}
 */
const rejectUser = async (id, reason, currentUser) => {
  // Get the target user
  const targetUser = await usersRepository.findById(id);
  if (!targetUser) {
    throw new Error('USER_NOT_FOUND');
  }

  // User must be pending
  if (targetUser.status !== 'pending') {
    throw new Error('USER_NOT_PENDING');
  }

  // Cannot reject yourself
  if (currentUser.id === id) {
    throw new Error('CANNOT_REJECT_SELF');
  }

  // Check permission (police+ can reject)
  if (!hasMinimumRole(currentUser.role, ROLES.POLICE)) {
    throw new Error('ACCESS_DENIED');
  }

  const updatedUser = await usersRepository.updateStatus(id, 'rejected', currentUser.id, reason);
  return formatUser(updatedUser);
};

/**
 * Update user role
 * @param {string} id - User UUID
 * @param {string} newRole - New role
 * @param {Object} currentUser - User performing the update
 * @returns {Promise<Object>}
 */
const updateUserRole = async (id, newRole, currentUser) => {
  // Validate role
  if (!isValidRole(newRole)) {
    throw new Error('INVALID_ROLE');
  }

  // Get the target user
  const targetUser = await usersRepository.findById(id);
  if (!targetUser) {
    throw new Error('USER_NOT_FOUND');
  }

  // Cannot change own role
  if (currentUser.id === id) {
    throw new Error('CANNOT_CHANGE_OWN_ROLE');
  }

  // Check if current user can assign this role
  const assignableRoles = getAssignableRoles(currentUser.role);
  if (!assignableRoles.includes(newRole)) {
    throw new Error('CANNOT_ASSIGN_ROLE');
  }

  // Cannot change role of someone with higher or equal role (except super_admin)
  if (currentUser.role !== ROLES.SUPER_ADMIN) {
    if (hasMinimumRole(targetUser.role, currentUser.role)) {
      throw new Error('CANNOT_MODIFY_HIGHER_ROLE');
    }
  }

  const updatedUser = await usersRepository.updateRole(id, newRole);
  return formatUser(updatedUser);
};

/**
 * Soft delete user
 * @param {string} id - User UUID
 * @param {Object} currentUser - User performing the deletion
 * @returns {Promise<Object>}
 */
const deleteUser = async (id, currentUser) => {
  // Get the target user
  const targetUser = await usersRepository.findById(id);
  if (!targetUser) {
    throw new Error('USER_NOT_FOUND');
  }

  // Cannot delete yourself
  if (currentUser.id === id) {
    throw new Error('CANNOT_DELETE_SELF');
  }

  // Only admins can delete
  if (!hasMinimumRole(currentUser.role, ROLES.ADMIN)) {
    throw new Error('ACCESS_DENIED');
  }

  // Cannot delete someone with higher or equal role (except super_admin)
  if (currentUser.role !== ROLES.SUPER_ADMIN) {
    if (hasMinimumRole(targetUser.role, currentUser.role)) {
      throw new Error('CANNOT_DELETE_HIGHER_ROLE');
    }
  }

  const deletedUser = await usersRepository.softDelete(id);
  return formatUser(deletedUser);
};

/**
 * Get user statistics
 * @returns {Promise<Object>}
 */
const getUserStats = async () => {
  const [byStatus, byRole] = await Promise.all([
    usersRepository.getCountByStatus(),
    usersRepository.getCountByRole(),
  ]);

  return {
    byStatus,
    byRole,
  };
};

/**
 * Format user object for response
 * @param {Object} user - User from database
 * @returns {Object}
 */
const formatUser = (user) => {
  if (!user) return null;

  return {
    id: user.id,
    email: user.email,
    phone: user.phone,
    fullName: user.full_name,
    idCardNumber: user.id_card_number,
    affiliation: user.affiliation,
    address: user.address,
    role: user.role,
    status: user.status,
    profileImageUrl: user.profile_image_url,
    approvedBy: user.approved_by,
    approvedAt: user.approved_at,
    rejectionReason: user.rejection_reason,
    approverName: user.approver_name || null,
    approverRole: user.approver_role || null,
    createdAt: user.created_at,
    updatedAt: user.updated_at,
    lastLoginAt: user.last_login_at,
  };
};

module.exports = {
  getUsers,
  getPendingUsers,
  getUserById,
  updateUser,
  updateUserStatus,
  approveUser,
  rejectUser,
  updateUserRole,
  deleteUser,
  getUserStats,
};
