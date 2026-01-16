'use strict';

const chatRoutes = require('./chat.routes');
const chatController = require('./chat.controller');
const chatService = require('./chat.service');
const chatRepository = require('./chat.repository');
const chatValidation = require('./chat.validation');

module.exports = {
  routes: chatRoutes,
  controller: chatController,
  service: chatService,
  repository: chatRepository,
  validation: chatValidation,
};
