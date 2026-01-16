'use strict';

const { authenticate, optionalAuth, verifyRefreshToken } = require('../../src/middleware/auth.middleware');
const { query } = require('../../src/config/database');
const jwtUtils = require('../../src/utils/jwt.utils');

// Mock dependencies
jest.mock('../../src/utils/jwt.utils');

describe('AuthMiddleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    query.mockReset();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('authenticate', () => {
    it('should authenticate user with valid token', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      const mockToken = 'valid-access-token';
      const mockDecoded = {
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
        type: 'access',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 900,
      };

      const req = global.testUtils.createMockRequest({
        headers: { authorization: `Bearer ${mockToken}` },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyAccessToken.mockReturnValue(mockDecoded);
      query.mockResolvedValue([mockUser]);

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(jwtUtils.verifyAccessToken).toHaveBeenCalledWith(mockToken);
      expect(query).toHaveBeenCalled();
      expect(req.user).toBeDefined();
      expect(req.user.id).toBe(mockUser.id);
      expect(req.user.role).toBe(mockUser.role);
      expect(req.tokenInfo).toBeDefined();
      expect(next).toHaveBeenCalled();
    });

    it('should reject request without authorization header', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({ headers: {} });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Access denied. No token provided.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject request with invalid token format', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'InvalidFormat token123' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Invalid token format. Use Bearer token.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject request with empty bearer token', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'Bearer ' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject request with invalid token', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'Bearer invalid-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyAccessToken.mockReturnValue(null);

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Invalid or expired token.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject request if user not found', async () => {
      // Arrange
      const mockToken = 'valid-token';
      const mockDecoded = {
        userId: 'non-existent-user',
        type: 'access',
      };

      const req = global.testUtils.createMockRequest({
        headers: { authorization: `Bearer ${mockToken}` },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyAccessToken.mockReturnValue(mockDecoded);
      query.mockResolvedValue([]);

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'User not found or not approved.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should handle expired token error', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'Bearer expired-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      const expiredError = new Error('Token expired');
      expiredError.name = 'TokenExpiredError';
      jwtUtils.verifyAccessToken.mockImplementation(() => {
        throw expiredError;
      });

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Token has expired.',
        })
      );
    });

    it('should handle JsonWebTokenError', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'Bearer malformed-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      const jwtError = new Error('Invalid token');
      jwtError.name = 'JsonWebTokenError';
      jwtUtils.verifyAccessToken.mockImplementation(() => {
        throw jwtError;
      });

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Invalid token.',
        })
      );
    });

    it('should handle unexpected errors', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'Bearer some-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyAccessToken.mockImplementation(() => {
        throw new Error('Unexpected error');
      });

      // Act
      await authenticate(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Authentication failed.',
        })
      );
    });
  });

  describe('optionalAuth', () => {
    it('should attach user if valid token provided', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      const mockToken = 'valid-token';
      const mockDecoded = {
        userId: mockUser.id,
        type: 'access',
      };

      const req = global.testUtils.createMockRequest({
        headers: { authorization: `Bearer ${mockToken}` },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyAccessToken.mockReturnValue(mockDecoded);
      query.mockResolvedValue([mockUser]);

      // Act
      await optionalAuth(req, res, next);

      // Assert
      expect(req.user).toBeDefined();
      expect(req.user.id).toBe(mockUser.id);
      expect(next).toHaveBeenCalled();
    });

    it('should continue without user if no token provided', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({ headers: {} });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      await optionalAuth(req, res, next);

      // Assert
      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalled();
    });

    it('should continue without user if token is invalid', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'Bearer invalid-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyAccessToken.mockReturnValue(null);

      // Act
      await optionalAuth(req, res, next);

      // Assert
      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalled();
    });

    it('should continue without user if user not found', async () => {
      // Arrange
      const mockDecoded = { userId: 'non-existent', type: 'access' };
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'Bearer some-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyAccessToken.mockReturnValue(mockDecoded);
      query.mockResolvedValue([]);

      // Act
      await optionalAuth(req, res, next);

      // Assert
      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalled();
    });

    it('should continue without user if token format is invalid', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'InvalidFormat token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      await optionalAuth(req, res, next);

      // Assert
      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalled();
    });

    it('should handle errors gracefully and continue', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        headers: { authorization: 'Bearer some-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyAccessToken.mockImplementation(() => {
        throw new Error('Unexpected error');
      });

      // Act
      await optionalAuth(req, res, next);

      // Assert
      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalled();
    });
  });

  describe('verifyRefreshToken', () => {
    it('should verify valid refresh token', async () => {
      // Arrange
      const mockUser = global.testUtils.createMockUser();
      const mockRefreshToken = 'valid-refresh-token';
      const mockDecoded = { userId: mockUser.id, type: 'refresh' };
      const mockTokenRecord = {
        id: 'token-id',
        user_id: mockUser.id,
        expires_at: new Date(Date.now() + 86400000), // Tomorrow
      };

      const req = global.testUtils.createMockRequest({
        body: { refreshToken: mockRefreshToken },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyRefreshToken.mockReturnValue(mockDecoded);
      query
        .mockResolvedValueOnce([mockTokenRecord]) // Token record query
        .mockResolvedValueOnce([mockUser]); // User query

      // Act
      await verifyRefreshToken(req, res, next);

      // Assert
      expect(jwtUtils.verifyRefreshToken).toHaveBeenCalledWith(mockRefreshToken);
      expect(req.user).toBeDefined();
      expect(req.user.id).toBe(mockUser.id);
      expect(req.refreshToken).toBe(mockRefreshToken);
      expect(req.refreshTokenRecord).toEqual(mockTokenRecord);
      expect(next).toHaveBeenCalled();
    });

    it('should reject if refresh token not provided', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({ body: {} });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      await verifyRefreshToken(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Refresh token is required.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject if refresh token is invalid', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        body: { refreshToken: 'invalid-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyRefreshToken.mockReturnValue(null);

      // Act
      await verifyRefreshToken(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Invalid or expired refresh token.',
        })
      );
    });

    it('should reject if refresh token not found in database', async () => {
      // Arrange
      const mockDecoded = { userId: 'user-id', type: 'refresh' };
      const req = global.testUtils.createMockRequest({
        body: { refreshToken: 'unknown-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyRefreshToken.mockReturnValue(mockDecoded);
      query.mockResolvedValueOnce([]); // Empty token record

      // Act
      await verifyRefreshToken(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Refresh token not found or has been revoked.',
        })
      );
    });

    it('should reject if user not found', async () => {
      // Arrange
      const mockDecoded = { userId: 'user-id', type: 'refresh' };
      const mockTokenRecord = { id: 'token-id', user_id: 'user-id' };
      const req = global.testUtils.createMockRequest({
        body: { refreshToken: 'valid-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      jwtUtils.verifyRefreshToken.mockReturnValue(mockDecoded);
      query
        .mockResolvedValueOnce([mockTokenRecord])
        .mockResolvedValueOnce([]); // User not found

      // Act
      await verifyRefreshToken(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'User not found or inactive.',
        })
      );
    });

    it('should handle expired refresh token error', async () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        body: { refreshToken: 'expired-token' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      const expiredError = new Error('Token expired');
      expiredError.name = 'TokenExpiredError';
      jwtUtils.verifyRefreshToken.mockImplementation(() => {
        throw expiredError;
      });

      // Act
      await verifyRefreshToken(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Refresh token has expired.',
        })
      );
    });
  });
});
