'use strict';

const usersService = require('./users.service');
const {
  successResponse,
  paginatedResponse,
  notFoundResponse,
  badRequestResponse,
  forbiddenResponse,
  conflictResponse,
  calculatePagination,
  parsePaginationQuery,
} = require('../../utils/response.utils');

/**
 * Users Controller - Handle HTTP requests for user management
 */

/**
 * Get all users (paginated)
 * GET /users
 */
const getUsers = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query);
    const { search, role, status, affiliation, sortBy, sortOrder } = req.query;

    const result = await usersService.getUsers({
      page,
      limit,
      search,
      role,
      status,
      affiliation,
      sortBy,
      sortOrder,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.users, pagination, 'Users retrieved successfully');
  } catch (error) {
    console.error('Get users error:', error);
    return badRequestResponse(res, 'Failed to retrieve users');
  }
};

/**
 * Get pending users (for approval)
 * GET /users/pending
 */
const getPendingUsers = async (req, res) => {
  try {
    const { page, limit } = parsePaginationQuery(req.query);
    const { search } = req.query;

    const result = await usersService.getPendingUsers({
      page,
      limit,
      search,
    });

    const pagination = calculatePagination(page, limit, result.total);

    return paginatedResponse(res, result.users, pagination, 'Pending users retrieved successfully');
  } catch (error) {
    console.error('Get pending users error:', error);
    return badRequestResponse(res, 'Failed to retrieve pending users');
  }
};

/**
 * Get user by ID
 * GET /users/:id
 */
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const includeApprover = req.query.includeApprover === 'true';

    const user = await usersService.getUserById(id, includeApprover);

    if (!user) {
      return notFoundResponse(res, 'User not found');
    }

    return successResponse(res, user, 'User retrieved successfully');
  } catch (error) {
    console.error('Get user by ID error:', error);
    return badRequestResponse(res, 'Failed to retrieve user');
  }
};

/**
 * Update user
 * PUT /users/:id
 */
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const user = await usersService.updateUser(id, updates, req.user);

    return successResponse(res, user, 'User updated successfully');
  } catch (error) {
    console.error('Update user error:', error);

    switch (error.message) {
      case 'USER_NOT_FOUND':
        return notFoundResponse(res, 'User not found');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to update this user');
      case 'EMAIL_TAKEN':
        return conflictResponse(res, 'Email is already in use');
      case 'PHONE_TAKEN':
        return conflictResponse(res, 'Phone number is already in use');
      case 'ID_CARD_TAKEN':
        return conflictResponse(res, 'ID card number is already in use');
      default:
        return badRequestResponse(res, 'Failed to update user');
    }
  }
};

/**
 * Update user status
 * PATCH /users/:id/status
 */
const updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return badRequestResponse(res, 'Status is required');
    }

    const user = await usersService.updateUserStatus(id, status, req.user);

    return successResponse(res, user, 'User status updated successfully');
  } catch (error) {
    console.error('Update user status error:', error);

    switch (error.message) {
      case 'USER_NOT_FOUND':
        return notFoundResponse(res, 'User not found');
      case 'INVALID_STATUS':
        return badRequestResponse(res, 'Invalid status value');
      case 'CANNOT_CHANGE_OWN_STATUS':
        return forbiddenResponse(res, 'You cannot change your own status');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to change this user\'s status');
      default:
        return badRequestResponse(res, 'Failed to update user status');
    }
  }
};

/**
 * Update user role
 * PATCH /users/:id/role
 */
const updateUserRole = async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    if (!role) {
      return badRequestResponse(res, 'Role is required');
    }

    const user = await usersService.updateUserRole(id, role, req.user);

    return successResponse(res, user, 'User role updated successfully');
  } catch (error) {
    console.error('Update user role error:', error);

    switch (error.message) {
      case 'USER_NOT_FOUND':
        return notFoundResponse(res, 'User not found');
      case 'INVALID_ROLE':
        return badRequestResponse(res, 'Invalid role value');
      case 'CANNOT_CHANGE_OWN_ROLE':
        return forbiddenResponse(res, 'You cannot change your own role');
      case 'CANNOT_ASSIGN_ROLE':
        return forbiddenResponse(res, 'You do not have permission to assign this role');
      case 'CANNOT_MODIFY_HIGHER_ROLE':
        return forbiddenResponse(res, 'You cannot modify the role of someone with equal or higher role');
      default:
        return badRequestResponse(res, 'Failed to update user role');
    }
  }
};

/**
 * Approve user
 * POST /users/:id/approve
 */
const approveUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await usersService.approveUser(id, req.user);

    return successResponse(res, user, 'User approved successfully');
  } catch (error) {
    console.error('Approve user error:', error);

    switch (error.message) {
      case 'USER_NOT_FOUND':
        return notFoundResponse(res, 'User not found');
      case 'USER_NOT_PENDING':
        return badRequestResponse(res, 'User is not pending approval');
      case 'CANNOT_APPROVE_SELF':
        return forbiddenResponse(res, 'You cannot approve yourself');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to approve users');
      default:
        return badRequestResponse(res, 'Failed to approve user');
    }
  }
};

/**
 * Reject user
 * POST /users/:id/reject
 */
const rejectUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    const user = await usersService.rejectUser(id, reason, req.user);

    return successResponse(res, user, 'User rejected successfully');
  } catch (error) {
    console.error('Reject user error:', error);

    switch (error.message) {
      case 'USER_NOT_FOUND':
        return notFoundResponse(res, 'User not found');
      case 'USER_NOT_PENDING':
        return badRequestResponse(res, 'User is not pending approval');
      case 'CANNOT_REJECT_SELF':
        return forbiddenResponse(res, 'You cannot reject yourself');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to reject users');
      default:
        return badRequestResponse(res, 'Failed to reject user');
    }
  }
};

/**
 * Delete user (soft delete)
 * DELETE /users/:id
 */
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await usersService.deleteUser(id, req.user);

    return successResponse(res, user, 'User deleted successfully');
  } catch (error) {
    console.error('Delete user error:', error);

    switch (error.message) {
      case 'USER_NOT_FOUND':
        return notFoundResponse(res, 'User not found');
      case 'CANNOT_DELETE_SELF':
        return forbiddenResponse(res, 'You cannot delete yourself');
      case 'ACCESS_DENIED':
        return forbiddenResponse(res, 'You do not have permission to delete users');
      case 'CANNOT_DELETE_HIGHER_ROLE':
        return forbiddenResponse(res, 'You cannot delete someone with equal or higher role');
      default:
        return badRequestResponse(res, 'Failed to delete user');
    }
  }
};

/**
 * Get user statistics
 * GET /users/stats
 */
const getUserStats = async (req, res) => {
  try {
    const stats = await usersService.getUserStats();

    return successResponse(res, stats, 'User statistics retrieved successfully');
  } catch (error) {
    console.error('Get user stats error:', error);
    return badRequestResponse(res, 'Failed to retrieve user statistics');
  }
};

module.exports = {
  getUsers,
  getPendingUsers,
  getUserById,
  updateUser,
  updateUserStatus,
  updateUserRole,
  approveUser,
  rejectUser,
  deleteUser,
  getUserStats,
};
