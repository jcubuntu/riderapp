'use strict';

const authService = require('../../../src/modules/auth/auth.service');
const authRepository = require('../../../src/modules/auth/auth.repository');
const passwordUtils = require('../../../src/utils/password.utils');
const jwtUtils = require('../../../src/utils/jwt.utils');

// Mock dependencies
jest.mock('../../../src/modules/auth/auth.repository');
jest.mock('../../../src/utils/password.utils');
jest.mock('../../../src/utils/jwt.utils');

describe('AuthService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('register', () => {
    const mockUserData = {
      phone: '0811111111',
      password: 'Test1234!',
      fullName: 'Test User',
      idCardNumber: '1234567890123',
      affiliation: 'Test Affiliation',
      address: '123 Test Street',
    };

    it('should successfully register a new user', async () => {
      // Arrange
      const mockCreatedUser = {
        id: 'new-user-id',
        email: null,
        phone: mockUserData.phone,
        full_name: mockUserData.fullName,
        id_card_number: mockUserData.idCardNumber,
        affiliation: mockUserData.affiliation,
        address: mockUserData.address,
        role: 'rider',
        status: 'pending',
        profile_image_url: null,
        approved_at: null,
        created_at: new Date(),
        updated_at: new Date(),
      };

      authRepository.findByPhone.mockResolvedValue(null);
      authRepository.findByIdCardNumber.mockResolvedValue(null);
      passwordUtils.hashPassword.mockResolvedValue('hashed-password');
      authRepository.create.mockResolvedValue(mockCreatedUser);

      // Act
      const result = await authService.register(mockUserData);

      // Assert
      expect(authRepository.findByPhone).toHaveBeenCalledWith(mockUserData.phone);
      expect(passwordUtils.hashPassword).toHaveBeenCalledWith(mockUserData.password);
      expect(authRepository.create).toHaveBeenCalled();
      expect(result.requiresApproval).toBe(true);
      expect(result.user.phone).toBe(mockUserData.phone);
      expect(result.user.fullName).toBe(mockUserData.fullName);
      expect(result.user.role).toBe('rider');
      expect(result.user.status).toBe('pending');
    });

    it('should throw error if phone number already exists', async () => {
      // Arrange
      const existingUser = global.testUtils.createMockUser({
        phone: mockUserData.phone,
      });
      authRepository.findByPhone.mockResolvedValue(existingUser);

      // Act & Assert
      await expect(authService.register(mockUserData)).rejects.toThrow(
        'Phone number already registered'
      );
      expect(authRepository.create).not.toHaveBeenCalled();
    });

    it('should throw error if ID card number already exists', async () => {
      // Arrange
      const existingUser = global.testUtils.createMockUser({
        id_card_number: mockUserData.idCardNumber,
      });
      authRepository.findByPhone.mockResolvedValue(null);
      authRepository.findByIdCardNumber.mockResolvedValue(existingUser);

      // Act & Assert
      await expect(authService.register(mockUserData)).rejects.toThrow(
        'ID card number already registered'
      );
      expect(authRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('login', () => {
    const mockPhone = '0811111111';
    const mockPassword = 'Test1234!';
    const mockDeviceInfo = {
      deviceName: 'Test Device',
      deviceType: 'mobile',
      ipAddress: '127.0.0.1',
      userAgent: 'Test Agent',
    };

    it('should successfully login an approved user', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({
        phone: mockPhone,
        status: 'approved',
      });
      const mockTokens = {
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        tokenType: 'Bearer',
        expiresIn: '15m',
      };

      authRepository.findByPhone.mockResolvedValue(mockUser);
      passwordUtils.comparePassword.mockResolvedValue(true);
      jwtUtils.generateTokenPair.mockReturnValue(mockTokens);
      authRepository.createRefreshToken.mockResolvedValue({ id: 'token-id' });
      authRepository.updateLastLogin.mockResolvedValue();

      // Act
      const result = await authService.login(mockPhone, mockPassword, mockDeviceInfo);

      // Assert
      expect(authRepository.findByPhone).toHaveBeenCalledWith(mockPhone);
      expect(passwordUtils.comparePassword).toHaveBeenCalledWith(
        mockPassword,
        mockUser.password_hash
      );
      expect(jwtUtils.generateTokenPair).toHaveBeenCalledWith(mockUser);
      expect(authRepository.createRefreshToken).toHaveBeenCalled();
      expect(authRepository.updateLastLogin).toHaveBeenCalledWith(mockUser.id);
      expect(result.user.phone).toBe(mockPhone);
      expect(result.tokens).toEqual(mockTokens);
    });

    it('should throw error if user not found', async () => {
      // Arrange
      authRepository.findByPhone.mockResolvedValue(null);

      // Act & Assert
      await expect(authService.login(mockPhone, mockPassword)).rejects.toThrow(
        'Invalid phone number or password'
      );
      expect(passwordUtils.comparePassword).not.toHaveBeenCalled();
    });

    it('should throw error if password is invalid', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({ phone: mockPhone });
      authRepository.findByPhone.mockResolvedValue(mockUser);
      passwordUtils.comparePassword.mockResolvedValue(false);

      // Act & Assert
      await expect(authService.login(mockPhone, mockPassword)).rejects.toThrow(
        'Invalid phone number or password'
      );
      expect(jwtUtils.generateTokenPair).not.toHaveBeenCalled();
    });

    it('should throw error if user status is pending', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({
        phone: mockPhone,
        status: 'pending',
      });
      authRepository.findByPhone.mockResolvedValue(mockUser);
      passwordUtils.comparePassword.mockResolvedValue(true);

      // Act & Assert
      await expect(authService.login(mockPhone, mockPassword)).rejects.toThrow(
        'Account pending approval'
      );
    });

    it('should throw error if user status is rejected', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({
        phone: mockPhone,
        status: 'rejected',
      });
      authRepository.findByPhone.mockResolvedValue(mockUser);
      passwordUtils.comparePassword.mockResolvedValue(true);

      // Act & Assert
      await expect(authService.login(mockPhone, mockPassword)).rejects.toThrow(
        'Account registration was rejected'
      );
    });

    it('should throw error if user status is suspended', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({
        phone: mockPhone,
        status: 'suspended',
      });
      authRepository.findByPhone.mockResolvedValue(mockUser);
      passwordUtils.comparePassword.mockResolvedValue(true);

      // Act & Assert
      await expect(authService.login(mockPhone, mockPassword)).rejects.toThrow(
        'Account has been suspended'
      );
    });
  });

  describe('refreshTokens', () => {
    it('should successfully refresh tokens', async () => {
      // Arrange
      const mockRefreshToken = 'valid-refresh-token';
      const mockDecoded = { userId: 'user-id', type: 'refresh' };
      const mockTokenRecord = {
        id: 'token-record-id',
        user_id: 'user-id',
        email: 'test@example.com',
        role: 'rider',
        full_name: 'Test User',
        status: 'approved',
        device_name: 'Test Device',
        device_type: 'mobile',
      };
      const mockNewTokens = {
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        tokenType: 'Bearer',
        expiresIn: '15m',
      };

      jwtUtils.verifyRefreshToken.mockReturnValue(mockDecoded);
      authRepository.findRefreshTokenByToken.mockResolvedValue(mockTokenRecord);
      authRepository.updateRefreshTokenLastUsed.mockResolvedValue();
      jwtUtils.generateTokenPair.mockReturnValue(mockNewTokens);
      authRepository.createRefreshToken.mockResolvedValue({ id: 'new-token-id' });
      authRepository.revokeRefreshToken.mockResolvedValue();

      // Act
      const result = await authService.refreshTokens(mockRefreshToken);

      // Assert
      expect(jwtUtils.verifyRefreshToken).toHaveBeenCalledWith(mockRefreshToken);
      expect(authRepository.findRefreshTokenByToken).toHaveBeenCalledWith(mockRefreshToken);
      expect(authRepository.revokeRefreshToken).toHaveBeenCalledWith(
        mockRefreshToken,
        'token_refresh'
      );
      expect(result.tokens).toEqual(mockNewTokens);
    });

    it('should throw error if refresh token is invalid', async () => {
      // Arrange
      jwtUtils.verifyRefreshToken.mockImplementation(() => {
        const error = new Error('Invalid token');
        error.name = 'JsonWebTokenError';
        throw error;
      });

      // Act & Assert
      await expect(authService.refreshTokens('invalid-token')).rejects.toThrow(
        'Invalid refresh token'
      );
    });

    it('should throw error if refresh token is expired', async () => {
      // Arrange
      jwtUtils.verifyRefreshToken.mockImplementation(() => {
        const error = new Error('Token expired');
        error.name = 'TokenExpiredError';
        throw error;
      });

      // Act & Assert
      await expect(authService.refreshTokens('expired-token')).rejects.toThrow(
        'Refresh token expired'
      );
    });

    it('should throw error if refresh token not found in database', async () => {
      // Arrange
      jwtUtils.verifyRefreshToken.mockReturnValue({ userId: 'user-id' });
      authRepository.findRefreshTokenByToken.mockResolvedValue(null);

      // Act & Assert
      await expect(authService.refreshTokens('unknown-token')).rejects.toThrow(
        'Refresh token not found or revoked'
      );
    });
  });

  describe('logout', () => {
    it('should successfully logout user', async () => {
      // Arrange
      const mockRefreshToken = 'valid-refresh-token';
      authRepository.revokeRefreshToken.mockResolvedValue();

      // Act
      await authService.logout(mockRefreshToken);

      // Assert
      expect(authRepository.revokeRefreshToken).toHaveBeenCalledWith(mockRefreshToken, 'logout');
    });

    it('should handle logout without refresh token', async () => {
      // Act
      await authService.logout(null);

      // Assert
      expect(authRepository.revokeRefreshToken).not.toHaveBeenCalled();
    });
  });

  describe('logoutAllDevices', () => {
    it('should revoke all refresh tokens for user', async () => {
      // Arrange
      const mockUserId = 'user-id';
      authRepository.revokeAllUserTokens.mockResolvedValue({ affectedRows: 5 });

      // Act
      const result = await authService.logoutAllDevices(mockUserId);

      // Assert
      expect(authRepository.revokeAllUserTokens).toHaveBeenCalledWith(
        mockUserId,
        'logout_all_devices'
      );
      expect(result.revokedSessions).toBe(5);
    });
  });

  describe('getUserById', () => {
    it('should return user by ID', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      authRepository.findById.mockResolvedValue(mockUser);

      // Act
      const result = await authService.getUserById(mockUser.id);

      // Assert
      expect(authRepository.findById).toHaveBeenCalledWith(mockUser.id);
      expect(result.id).toBe(mockUser.id);
    });

    it('should throw error if user not found', async () => {
      // Arrange
      authRepository.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(authService.getUserById('non-existent-id')).rejects.toThrow('User not found');
    });
  });

  describe('getProfile', () => {
    it('should return user profile', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      authRepository.findById.mockResolvedValue(mockUser);

      // Act
      const result = await authService.getProfile(mockUser.id);

      // Assert
      expect(authRepository.findById).toHaveBeenCalledWith(mockUser.id);
      expect(result.id).toBe(mockUser.id);
      expect(result.phone).toBe(mockUser.phone);
      expect(result.fullName).toBe(mockUser.full_name);
    });

    it('should throw error if user not found', async () => {
      // Arrange
      authRepository.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(authService.getProfile('non-existent-id')).rejects.toThrow('User not found');
    });
  });

  describe('updateProfile', () => {
    it('should update user profile successfully', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      const updates = {
        fullName: 'Updated Name',
        affiliation: 'New Affiliation',
      };
      const updatedUser = {
        ...mockUser,
        full_name: updates.fullName,
        affiliation: updates.affiliation,
      };

      authRepository.findById.mockResolvedValue(mockUser);
      authRepository.update.mockResolvedValue(updatedUser);

      // Act
      const result = await authService.updateProfile(mockUser.id, updates);

      // Assert
      expect(authRepository.findById).toHaveBeenCalledWith(mockUser.id);
      expect(authRepository.update).toHaveBeenCalled();
      expect(result.fullName).toBe(updates.fullName);
    });

    it('should throw error if user not found', async () => {
      // Arrange
      authRepository.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(authService.updateProfile('non-existent-id', {})).rejects.toThrow(
        'User not found'
      );
    });

    it('should throw error if phone is already taken', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({ phone: '0811111111' });
      const existingUser = global.testUtils.createMockUser({
        id: 'other-user-id',
        phone: '0822222222',
      });

      authRepository.findById.mockResolvedValue(mockUser);
      authRepository.findByPhone.mockResolvedValue(existingUser);

      // Act & Assert
      await expect(
        authService.updateProfile(mockUser.id, { phone: '0822222222' })
      ).rejects.toThrow('Phone number already in use');
    });
  });

  describe('changePassword', () => {
    it('should change password successfully', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      const currentPassword = 'CurrentPass1!';
      const newPassword = 'NewPass1234!';

      authRepository.findById.mockResolvedValue(mockUser);
      authRepository.findByEmail.mockResolvedValue(mockUser);
      passwordUtils.comparePassword.mockResolvedValue(true);
      passwordUtils.hashPassword.mockResolvedValue('new-hashed-password');
      authRepository.updatePassword.mockResolvedValue();
      authRepository.revokeAllUserTokens.mockResolvedValue({ affectedRows: 1 });

      // Act
      await authService.changePassword(mockUser.id, currentPassword, newPassword);

      // Assert
      expect(passwordUtils.comparePassword).toHaveBeenCalledWith(
        currentPassword,
        mockUser.password_hash
      );
      expect(passwordUtils.hashPassword).toHaveBeenCalledWith(newPassword);
      expect(authRepository.updatePassword).toHaveBeenCalledWith(
        mockUser.id,
        'new-hashed-password'
      );
      expect(authRepository.revokeAllUserTokens).toHaveBeenCalledWith(
        mockUser.id,
        'password_change'
      );
    });

    it('should throw error if current password is incorrect', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      authRepository.findById.mockResolvedValue(mockUser);
      authRepository.findByEmail.mockResolvedValue(mockUser);
      passwordUtils.comparePassword.mockResolvedValue(false);

      // Act & Assert
      await expect(
        authService.changePassword(mockUser.id, 'WrongPassword', 'NewPassword')
      ).rejects.toThrow('Current password is incorrect');
    });
  });

  describe('getActiveSessions', () => {
    it('should return active sessions for user', async () => {
      // Arrange
      const mockUserId = 'user-id';
      const mockSessions = [
        {
          id: 'session-1',
          device_name: 'iPhone',
          device_type: 'mobile',
          last_used_at: new Date(),
        },
        {
          id: 'session-2',
          device_name: 'Chrome',
          device_type: 'web',
          last_used_at: new Date(),
        },
      ];
      authRepository.getUserActiveSessions.mockResolvedValue(mockSessions);

      // Act
      const result = await authService.getActiveSessions(mockUserId);

      // Assert
      expect(authRepository.getUserActiveSessions).toHaveBeenCalledWith(mockUserId);
      expect(result).toHaveLength(2);
    });
  });

  describe('checkApprovalStatus', () => {
    it('should return approval status for user', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser({ status: 'pending' });
      authRepository.findById.mockResolvedValue(mockUser);

      // Act
      const result = await authService.checkApprovalStatus(mockUser.id);

      // Assert
      expect(result.status).toBe('pending');
      expect(result.user).toBeDefined();
    });

    it('should throw error if user not found', async () => {
      // Arrange
      authRepository.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(authService.checkApprovalStatus('non-existent-id')).rejects.toThrow(
        'User not found'
      );
    });
  });
});
