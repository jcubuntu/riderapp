'use strict';

const admin = require('firebase-admin');
const logger = require('../utils/logger.utils');

/**
 * Firebase Admin SDK Configuration
 *
 * Supports two modes of initialization:
 * 1. Service Account JSON file path (FIREBASE_SERVICE_ACCOUNT_PATH)
 * 2. Individual credentials (FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL)
 */

let firebaseApp = null;
let isInitialized = false;

/**
 * Initialize Firebase Admin SDK
 * @returns {admin.app.App|null} Firebase app instance or null if initialization fails
 */
const initializeFirebase = () => {
  if (isInitialized) {
    return firebaseApp;
  }

  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

    // Check if Firebase is configured
    if (!serviceAccountPath && !(projectId && privateKey && clientEmail)) {
      logger.warn('Firebase is not configured. Push notifications will be disabled.');
      logger.warn('Set FIREBASE_SERVICE_ACCOUNT_PATH or (FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL)');
      isInitialized = true;
      return null;
    }

    let credential;

    if (serviceAccountPath) {
      // Initialize with service account JSON file
      const serviceAccount = require(serviceAccountPath);
      credential = admin.credential.cert(serviceAccount);
      logger.info('Firebase initialized with service account file');
    } else {
      // Initialize with individual credentials
      // Handle escaped newlines in private key (common in environment variables)
      const formattedPrivateKey = privateKey.replace(/\\n/g, '\n');

      credential = admin.credential.cert({
        projectId,
        privateKey: formattedPrivateKey,
        clientEmail,
      });
      logger.info('Firebase initialized with individual credentials');
    }

    firebaseApp = admin.initializeApp({
      credential,
      projectId: projectId || undefined,
    });

    isInitialized = true;
    logger.info('Firebase Admin SDK initialized successfully');

    return firebaseApp;
  } catch (error) {
    logger.error('Failed to initialize Firebase Admin SDK', {
      error: error.message,
      stack: error.stack,
    });
    isInitialized = true;
    return null;
  }
};

/**
 * Get Firebase Admin instance
 * @returns {admin|null} Firebase admin instance or null if not initialized
 */
const getFirebaseAdmin = () => {
  if (!isInitialized) {
    initializeFirebase();
  }
  return firebaseApp ? admin : null;
};

/**
 * Get Firebase Messaging instance
 * @returns {admin.messaging.Messaging|null} Firebase messaging instance or null
 */
const getMessaging = () => {
  const firebaseAdmin = getFirebaseAdmin();
  if (!firebaseAdmin) {
    return null;
  }
  return firebaseAdmin.messaging();
};

/**
 * Check if Firebase is configured and ready
 * @returns {boolean}
 */
const isFirebaseConfigured = () => {
  if (!isInitialized) {
    initializeFirebase();
  }
  return firebaseApp !== null;
};

/**
 * Get Firebase configuration status
 * @returns {Object}
 */
const getFirebaseStatus = () => {
  return {
    initialized: isInitialized,
    configured: firebaseApp !== null,
    projectId: process.env.FIREBASE_PROJECT_ID || 'not set',
  };
};

// Initialize on module load
initializeFirebase();

module.exports = {
  initializeFirebase,
  getFirebaseAdmin,
  getMessaging,
  isFirebaseConfigured,
  getFirebaseStatus,
};
