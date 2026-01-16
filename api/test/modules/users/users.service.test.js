'use strict';

const usersService = require('../../../src/modules/users/users.service');
const usersRepository = require('../../../src/modules/users/users.repository');
const { ROLES } = require('../../../src/constants/roles');

// Mock dependencies
jest.mock('../../../src/modules/users/users.repository');

describe('UsersService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getUsers', () => {
    it('should return paginated users list', async () => {
      // Arrange
      const mockUsers = [
        global.testUtils.createMockUser({ id: 'user-1' }),
        global.testUtils.createMockUser({ id: 'user-2' }),
      ];
      usersRepository.findAll.mockResolvedValue({
        users: mockUsers,
        total: 2,
      });

      // Act
      const result = await usersService.getUsers({ page: 1, limit: 10 });

      // Assert
      expect(usersRepository.findAll).toHaveBeenCalledWith({ page: 1, limit: 10 });
      expect(result.users).toHaveLength(2);
      expect(result.total).toBe(2);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
    });

    it('should use default pagination when not provided', async () => {
      // Arrange
      usersRepository.findAll.mockResolvedValue({
        users: [],
        total: 0,
      });

      // Act
      const result = await usersService.getUsers();

      // Assert
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
    });
  });

  describe('getPendingUsers', () => {
    it('should return users pending approval', async () => {
      // Arrange
      const mockPendingUsers = [
        global.testUtils.createMockUser({ id: 'user-1', status: 'pending' }),
        global.testUtils.createMockUser({ id: 'user-2', status: 'pending' }),
      ];
      usersRepository.findPending.mockResolvedValue({
        users: mockPendingUsers,
        total: 2,
      });

      // Act
      const result = await usersService.getPendingUsers({ page: 1, limit: 10 });

      // Assert
      expect(usersRepository.findPending).toHaveBeenCalled();
      expect(result.users).toHaveLength(2);
      expect(result.users.every((u) => u.status === 'pending')).toBe(true);
    });
  });

  describe('getUserById', () => {
    it('should return user by ID', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      usersRepository.findById.mockResolvedValue(mockUser);

      // Act
      const result = await usersService.getUserById(mockUser.id);

      // Assert
      expect(usersRepository.findById).toHaveBeenCalledWith(mockUser.id);
      expect(result.id).toBe(mockUser.id);
    });

    it('should return user with approver details when requested', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({
        approved_by: 'admin-id',
        approver_name: 'Admin User',
        approver_role: 'admin',
      });
      usersRepository.findByIdWithApprover.mockResolvedValue(mockUser);

      // Act
      const result = await usersService.getUserById(mockUser.id, true);

      // Assert
      expect(usersRepository.findByIdWithApprover).toHaveBeenCalledWith(mockUser.id);
      expect(result.approverName).toBe('Admin User');
    });

    it('should return null if user not found', async () => {
      // Arrange
      usersRepository.findById.mockResolvedValue(null);

      // Act
      const result = await usersService.getUserById('non-existent-id');

      // Assert
      expect(result).toBeNull();
    });
  });

  describe('updateUser', () => {
    it('should allow admin to update any user', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ role: 'rider' });
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };
      const updates = { fullName: 'Updated Name' };

      usersRepository.findById.mockResolvedValue(mockTargetUser);
      usersRepository.update.mockResolvedValue({
        ...mockTargetUser,
        full_name: updates.fullName,
      });

      // Act
      const result = await usersService.updateUser(mockTargetUser.id, updates, mockCurrentUser);

      // Assert
      expect(usersRepository.update).toHaveBeenCalledWith(mockTargetUser.id, updates);
      expect(result.fullName).toBe(updates.fullName);
    });

    it('should allow user to update their own profile with limited fields', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({ role: 'rider' });
      const mockCurrentUser = { id: mockUser.id, role: ROLES.RIDER };
      const updates = {
        fullName: 'Updated Name',
        role: 'admin', // Should be filtered out
      };

      usersRepository.findById.mockResolvedValue(mockUser);
      usersRepository.update.mockResolvedValue({
        ...mockUser,
        full_name: updates.fullName,
      });

      // Act
      const result = await usersService.updateUser(mockUser.id, updates, mockCurrentUser);

      // Assert
      expect(usersRepository.update).toHaveBeenCalled();
      const updateCallArgs = usersRepository.update.mock.calls[0][1];
      expect(updateCallArgs.role).toBeUndefined(); // Role should be filtered
    });

    it('should throw error if user not found', async () => {
      // Arrange
      usersRepository.findById.mockResolvedValue(null);
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };

      // Act & Assert
      await expect(
        usersService.updateUser('non-existent-id', {}, mockCurrentUser)
      ).rejects.toThrow('USER_NOT_FOUND');
    });

    it('should throw error if non-admin tries to update another user', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ id: 'user-1' });
      const mockCurrentUser = { id: 'user-2', role: ROLES.RIDER };

      usersRepository.findById.mockResolvedValue(mockTargetUser);

      // Act & Assert
      await expect(
        usersService.updateUser(mockTargetUser.id, {}, mockCurrentUser)
      ).rejects.toThrow('ACCESS_DENIED');
    });

    it('should throw error if email is already taken', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ email: 'old@test.com' });
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };

      usersRepository.findById.mockResolvedValue(mockTargetUser);
      usersRepository.isEmailTaken.mockResolvedValue(true);

      // Act & Assert
      await expect(
        usersService.updateUser(mockTargetUser.id, { email: 'new@test.com' }, mockCurrentUser)
      ).rejects.toThrow('EMAIL_TAKEN');
    });

    it('should throw error if phone is already taken', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ phone: '0811111111' });
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };

      usersRepository.findById.mockResolvedValue(mockTargetUser);
      usersRepository.isPhoneTaken.mockResolvedValue(true);

      // Act & Assert
      await expect(
        usersService.updateUser(mockTargetUser.id, { phone: '0822222222' }, mockCurrentUser)
      ).rejects.toThrow('PHONE_TAKEN');
    });
  });

  describe('updateUserStatus', () => {
    it('should allow police to update user status', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ status: 'pending' });
      const mockCurrentUser = { id: 'police-id', role: ROLES.POLICE };

      usersRepository.findById.mockResolvedValue(mockTargetUser);
      usersRepository.updateStatus.mockResolvedValue({
        ...mockTargetUser,
        status: 'approved',
      });

      // Act
      const result = await usersService.updateUserStatus(
        mockTargetUser.id,
        'approved',
        mockCurrentUser
      );

      // Assert
      expect(usersRepository.updateStatus).toHaveBeenCalledWith(
        mockTargetUser.id,
        'approved',
        mockCurrentUser.id
      );
      expect(result.status).toBe('approved');
    });

    it('should throw error for invalid status', async () => {
      // Arrange
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };

      // Act & Assert
      await expect(
        usersService.updateUserStatus('user-id', 'invalid-status', mockCurrentUser)
      ).rejects.toThrow('INVALID_STATUS');
    });

    it('should throw error when trying to change own status', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      const mockCurrentUser = { id: mockUser.id, role: ROLES.ADMIN };

      usersRepository.findById.mockResolvedValue(mockUser);

      // Act & Assert
      await expect(
        usersService.updateUserStatus(mockUser.id, 'approved', mockCurrentUser)
      ).rejects.toThrow('CANNOT_CHANGE_OWN_STATUS');
    });

    it('should throw error if rider tries to update status', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser();
      const mockCurrentUser = { id: 'rider-id', role: ROLES.RIDER };

      usersRepository.findById.mockResolvedValue(mockTargetUser);

      // Act & Assert
      await expect(
        usersService.updateUserStatus(mockTargetUser.id, 'approved', mockCurrentUser)
      ).rejects.toThrow('ACCESS_DENIED');
    });
  });

  describe('approveUser', () => {
    it('should approve a pending user', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ status: 'pending' });
      const mockCurrentUser = { id: 'police-id', role: ROLES.POLICE };

      usersRepository.findById.mockResolvedValue(mockTargetUser);
      usersRepository.updateStatus.mockResolvedValue({
        ...mockTargetUser,
        status: 'approved',
      });

      // Act
      const result = await usersService.approveUser(mockTargetUser.id, mockCurrentUser);

      // Assert
      expect(usersRepository.updateStatus).toHaveBeenCalledWith(
        mockTargetUser.id,
        'approved',
        mockCurrentUser.id
      );
      expect(result.status).toBe('approved');
    });

    it('should throw error if user is not pending', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ status: 'approved' });
      const mockCurrentUser = { id: 'police-id', role: ROLES.POLICE };

      usersRepository.findById.mockResolvedValue(mockTargetUser);

      // Act & Assert
      await expect(usersService.approveUser(mockTargetUser.id, mockCurrentUser)).rejects.toThrow(
        'USER_NOT_PENDING'
      );
    });

    it('should throw error when trying to approve yourself', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({ status: 'pending' });
      const mockCurrentUser = { id: mockUser.id, role: ROLES.POLICE };

      usersRepository.findById.mockResolvedValue(mockUser);

      // Act & Assert
      await expect(usersService.approveUser(mockUser.id, mockCurrentUser)).rejects.toThrow(
        'CANNOT_APPROVE_SELF'
      );
    });
  });

  describe('rejectUser', () => {
    it('should reject a pending user with reason', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ status: 'pending' });
      const mockCurrentUser = { id: 'police-id', role: ROLES.POLICE };
      const reason = 'Invalid ID card';

      usersRepository.findById.mockResolvedValue(mockTargetUser);
      usersRepository.updateStatus.mockResolvedValue({
        ...mockTargetUser,
        status: 'rejected',
        rejection_reason: reason,
      });

      // Act
      const result = await usersService.rejectUser(mockTargetUser.id, reason, mockCurrentUser);

      // Assert
      expect(usersRepository.updateStatus).toHaveBeenCalledWith(
        mockTargetUser.id,
        'rejected',
        mockCurrentUser.id,
        reason
      );
      expect(result.status).toBe('rejected');
    });

    it('should throw error if user is not pending', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ status: 'approved' });
      const mockCurrentUser = { id: 'police-id', role: ROLES.POLICE };

      usersRepository.findById.mockResolvedValue(mockTargetUser);

      // Act & Assert
      await expect(
        usersService.rejectUser(mockTargetUser.id, 'reason', mockCurrentUser)
      ).rejects.toThrow('USER_NOT_PENDING');
    });
  });

  describe('updateUserRole', () => {
    it('should allow admin to update user role', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ role: 'rider' });
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };
      const newRole = ROLES.VOLUNTEER;

      usersRepository.findById.mockResolvedValue(mockTargetUser);
      usersRepository.updateRole.mockResolvedValue({
        ...mockTargetUser,
        role: newRole,
      });

      // Act
      const result = await usersService.updateUserRole(mockTargetUser.id, newRole, mockCurrentUser);

      // Assert
      expect(usersRepository.updateRole).toHaveBeenCalledWith(mockTargetUser.id, newRole);
      expect(result.role).toBe(newRole);
    });

    it('should throw error for invalid role', async () => {
      // Arrange
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };

      // Act & Assert
      await expect(
        usersService.updateUserRole('user-id', 'invalid-role', mockCurrentUser)
      ).rejects.toThrow('INVALID_ROLE');
    });

    it('should throw error when trying to change own role', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({ role: 'rider' });
      const mockCurrentUser = { id: mockUser.id, role: ROLES.ADMIN };

      usersRepository.findById.mockResolvedValue(mockUser);

      // Act & Assert
      await expect(
        usersService.updateUserRole(mockUser.id, ROLES.VOLUNTEER, mockCurrentUser)
      ).rejects.toThrow('CANNOT_CHANGE_OWN_ROLE');
    });

    it('should throw error if role cannot be assigned by current user', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ role: 'rider' });
      const mockCurrentUser = { id: 'police-id', role: ROLES.POLICE };

      usersRepository.findById.mockResolvedValue(mockTargetUser);

      // Act & Assert
      await expect(
        usersService.updateUserRole(mockTargetUser.id, ROLES.ADMIN, mockCurrentUser)
      ).rejects.toThrow('CANNOT_ASSIGN_ROLE');
    });

    it('should throw error if trying to modify higher role user', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ role: ROLES.ADMIN });
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };

      usersRepository.findById.mockResolvedValue(mockTargetUser);

      // Act & Assert
      await expect(
        usersService.updateUserRole(mockTargetUser.id, ROLES.RIDER, mockCurrentUser)
      ).rejects.toThrow('CANNOT_MODIFY_HIGHER_ROLE');
    });
  });

  describe('deleteUser', () => {
    it('should soft delete user', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ role: 'rider' });
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };

      usersRepository.findById.mockResolvedValue(mockTargetUser);
      usersRepository.softDelete.mockResolvedValue({
        ...mockTargetUser,
        status: 'inactive',
      });

      // Act
      const result = await usersService.deleteUser(mockTargetUser.id, mockCurrentUser);

      // Assert
      expect(usersRepository.softDelete).toHaveBeenCalledWith(mockTargetUser.id);
      expect(result.status).toBe('inactive');
    });

    it('should throw error when trying to delete yourself', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      const mockCurrentUser = { id: mockUser.id, role: ROLES.ADMIN };

      usersRepository.findById.mockResolvedValue(mockUser);

      // Act & Assert
      await expect(usersService.deleteUser(mockUser.id, mockCurrentUser)).rejects.toThrow(
        'CANNOT_DELETE_SELF'
      );
    });

    it('should throw error if non-admin tries to delete', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser();
      const mockCurrentUser = { id: 'police-id', role: ROLES.POLICE };

      usersRepository.findById.mockResolvedValue(mockTargetUser);

      // Act & Assert
      await expect(usersService.deleteUser(mockTargetUser.id, mockCurrentUser)).rejects.toThrow(
        'ACCESS_DENIED'
      );
    });

    it('should throw error if trying to delete higher role user', async () => {
      // Arrange
      const mockTargetUser = global.testUtils.createMockUser({ role: ROLES.SUPER_ADMIN });
      const mockCurrentUser = { id: 'admin-id', role: ROLES.ADMIN };

      usersRepository.findById.mockResolvedValue(mockTargetUser);

      // Act & Assert
      await expect(usersService.deleteUser(mockTargetUser.id, mockCurrentUser)).rejects.toThrow(
        'CANNOT_DELETE_HIGHER_ROLE'
      );
    });
  });

  describe('getUserStats', () => {
    it('should return user statistics', async () => {
      // Arrange
      const mockStatsByStatus = { approved: 50, pending: 10, rejected: 5 };
      const mockStatsByRole = { rider: 40, volunteer: 10, police: 5, admin: 5 };

      usersRepository.getCountByStatus.mockResolvedValue(mockStatsByStatus);
      usersRepository.getCountByRole.mockResolvedValue(mockStatsByRole);

      // Act
      const result = await usersService.getUserStats();

      // Assert
      expect(usersRepository.getCountByStatus).toHaveBeenCalled();
      expect(usersRepository.getCountByRole).toHaveBeenCalled();
      expect(result.byStatus).toEqual(mockStatsByStatus);
      expect(result.byRole).toEqual(mockStatsByRole);
    });
  });
});
