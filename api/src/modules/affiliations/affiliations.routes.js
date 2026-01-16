'use strict';

const express = require('express');
const router = express.Router();

const affiliationsController = require('./affiliations.controller');
const { asyncHandler } = require('../../middleware/error.middleware');
const { authenticate } = require('../../middleware/auth.middleware');
const { requireRole } = require('../../middleware/role.middleware');

// Public routes
router.get('/', asyncHandler(affiliationsController.getAllAffiliations));

// Protected routes (admin only)
router.get(
  '/admin',
  authenticate,
  requireRole(['admin']),
  asyncHandler(affiliationsController.getAllAffiliationsAdmin)
);

router.get(
  '/:id',
  authenticate,
  asyncHandler(affiliationsController.getAffiliationById)
);

router.post(
  '/',
  authenticate,
  requireRole(['admin']),
  asyncHandler(affiliationsController.createAffiliation)
);

router.put(
  '/:id',
  authenticate,
  requireRole(['admin']),
  asyncHandler(affiliationsController.updateAffiliation)
);

router.delete(
  '/:id',
  authenticate,
  requireRole(['admin']),
  asyncHandler(affiliationsController.deleteAffiliation)
);

router.post(
  '/:id/restore',
  authenticate,
  requireRole(['admin']),
  asyncHandler(affiliationsController.restoreAffiliation)
);

module.exports = router;
