'use strict';

const authRoutes = require('./auth.routes');
const authService = require('./auth.service');
const authRepository = require('./auth.repository');
const authController = require('./auth.controller');

module.exports = {
  routes: authRoutes,
  service: authService,
  repository: authRepository,
  controller: authController,
};
