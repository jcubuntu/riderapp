'use strict';

const {
  requireRole,
  requireMinimumRole,
  adminOnly,
  superAdminOnly,
  policeOrAdmin,
  volunteerOrHigher,
  selfOrAdmin,
  hasPermission,
} = require('../../src/middleware/role.middleware');
const { ROLES } = require('../../src/constants/roles');

describe('RoleMiddleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('requireRole', () => {
    it('should allow user with matching role', () => {
      // Arrange
      const middleware = requireRole(ROLES.POLICE, ROLES.ADMIN);
      const req = global.testUtils.createMockRequest({
        user: { id: 'user-id', role: ROLES.POLICE },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should reject user without matching role', () => {
      // Arrange
      const middleware = requireRole(ROLES.ADMIN);
      const req = global.testUtils.createMockRequest({
        user: { id: 'user-id', role: ROLES.RIDER },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject unauthenticated user', () => {
      // Arrange
      const middleware = requireRole(ROLES.RIDER);
      const req = global.testUtils.createMockRequest({ user: null });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Authentication required.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('requireMinimumRole', () => {
    it('should allow user with equal role', () => {
      // Arrange
      const middleware = requireMinimumRole(ROLES.POLICE);
      const req = global.testUtils.createMockRequest({
        user: { id: 'user-id', role: ROLES.POLICE },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow user with higher role', () => {
      // Arrange
      const middleware = requireMinimumRole(ROLES.POLICE);
      const req = global.testUtils.createMockRequest({
        user: { id: 'user-id', role: ROLES.ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should reject user with lower role', () => {
      // Arrange
      const middleware = requireMinimumRole(ROLES.POLICE);
      const req = global.testUtils.createMockRequest({
        user: { id: 'user-id', role: ROLES.RIDER },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject unauthenticated user', () => {
      // Arrange
      const middleware = requireMinimumRole(ROLES.RIDER);
      const req = global.testUtils.createMockRequest({ user: null });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('adminOnly', () => {
    it('should allow admin user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'admin-id', role: ROLES.ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      adminOnly(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow super_admin user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'super-admin-id', role: ROLES.SUPER_ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      adminOnly(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should reject police user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'police-id', role: ROLES.POLICE },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      adminOnly(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Admin access required.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject unauthenticated user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({ user: null });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      adminOnly(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('superAdminOnly', () => {
    it('should allow super_admin user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'super-admin-id', role: ROLES.SUPER_ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      superAdminOnly(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should reject admin user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'admin-id', role: ROLES.ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      superAdminOnly(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Super Admin access required.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject unauthenticated user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({ user: null });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      superAdminOnly(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('policeOrAdmin', () => {
    it('should allow police user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'police-id', role: ROLES.POLICE },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      policeOrAdmin(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow admin user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'admin-id', role: ROLES.ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      policeOrAdmin(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow super_admin user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'super-admin-id', role: ROLES.SUPER_ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      policeOrAdmin(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should reject volunteer user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'volunteer-id', role: ROLES.VOLUNTEER },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      policeOrAdmin(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject rider user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'rider-id', role: ROLES.RIDER },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      policeOrAdmin(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('volunteerOrHigher', () => {
    it('should allow volunteer user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'volunteer-id', role: ROLES.VOLUNTEER },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      volunteerOrHigher(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow police user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'police-id', role: ROLES.POLICE },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      volunteerOrHigher(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow admin user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'admin-id', role: ROLES.ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      volunteerOrHigher(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should reject rider user', () => {
      // Arrange
      const req = global.testUtils.createMockRequest({
        user: { id: 'rider-id', role: ROLES.RIDER },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      volunteerOrHigher(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('selfOrAdmin', () => {
    it('should allow user accessing own data', () => {
      // Arrange
      const userId = 'user-123';
      const middleware = selfOrAdmin('id');
      const req = global.testUtils.createMockRequest({
        user: { id: userId, role: ROLES.RIDER },
        params: { id: userId },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow admin accessing any user data', () => {
      // Arrange
      const middleware = selfOrAdmin('id');
      const req = global.testUtils.createMockRequest({
        user: { id: 'admin-id', role: ROLES.ADMIN },
        params: { id: 'other-user-id' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow super_admin accessing any user data', () => {
      // Arrange
      const middleware = selfOrAdmin('id');
      const req = global.testUtils.createMockRequest({
        user: { id: 'super-admin-id', role: ROLES.SUPER_ADMIN },
        params: { id: 'other-user-id' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should reject user accessing other user data', () => {
      // Arrange
      const middleware = selfOrAdmin('id');
      const req = global.testUtils.createMockRequest({
        user: { id: 'user-123', role: ROLES.RIDER },
        params: { id: 'other-user-456' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Access denied. You can only access your own data.',
        })
      );
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject unauthenticated user', () => {
      // Arrange
      const middleware = selfOrAdmin('id');
      const req = global.testUtils.createMockRequest({
        user: null,
        params: { id: 'user-id' },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('hasPermission', () => {
    it('should allow super_admin with any permission', () => {
      // Arrange
      const middleware = hasPermission('manage_admins', 'system_config');
      const req = global.testUtils.createMockRequest({
        user: { id: 'super-admin-id', role: ROLES.SUPER_ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow admin for non-restricted permissions', () => {
      // Arrange
      const middleware = hasPermission('view_all_incidents');
      const req = global.testUtils.createMockRequest({
        user: { id: 'admin-id', role: ROLES.ADMIN },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow police with appropriate permissions', () => {
      // Arrange
      const middleware = hasPermission('approve_users');
      const req = global.testUtils.createMockRequest({
        user: { id: 'police-id', role: ROLES.POLICE },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should allow rider with appropriate permissions', () => {
      // Arrange
      const middleware = hasPermission('create_incident');
      const req = global.testUtils.createMockRequest({
        user: { id: 'rider-id', role: ROLES.RIDER },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(next).toHaveBeenCalled();
    });

    it('should reject rider for admin permissions', () => {
      // Arrange
      const middleware = hasPermission('manage_users');
      const req = global.testUtils.createMockRequest({
        user: { id: 'rider-id', role: ROLES.RIDER },
      });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('should reject unauthenticated user', () => {
      // Arrange
      const middleware = hasPermission('view_dashboard');
      const req = global.testUtils.createMockRequest({ user: null });
      const res = global.testUtils.createMockResponse();
      const next = global.testUtils.createMockNext();

      // Act
      middleware(req, res, next);

      // Assert
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).not.toHaveBeenCalled();
    });
  });
});
