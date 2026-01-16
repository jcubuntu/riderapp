'use strict';

const bcrypt = require('bcryptjs');
const config = require('../config');

/**
 * Hash a password
 * @param {string} password - Plain text password
 * @returns {Promise<string>} Hashed password
 */
const hashPassword = async (password) => {
  const saltRounds = config.bcrypt.saltRounds;
  const salt = await bcrypt.genSalt(saltRounds);
  const hashedPassword = await bcrypt.hash(password, salt);
  return hashedPassword;
};

/**
 * Compare password with hash
 * @param {string} password - Plain text password
 * @param {string} hashedPassword - Hashed password to compare against
 * @returns {Promise<boolean>} True if passwords match, false otherwise
 */
const comparePassword = async (password, hashedPassword) => {
  try {
    const isMatch = await bcrypt.compare(password, hashedPassword);
    return isMatch;
  } catch (error) {
    console.error('Password comparison error:', error);
    return false;
  }
};

/**
 * Check if a string is a valid bcrypt hash
 * @param {string} str - String to check
 * @returns {boolean} True if valid bcrypt hash
 */
const isValidHash = (str) => {
  // Bcrypt hashes start with $2a$, $2b$, or $2y$ followed by cost factor
  const bcryptRegex = /^\$2[aby]\$\d{2}\$.{53}$/;
  return bcryptRegex.test(str);
};

/**
 * Validate password strength
 * @param {string} password - Password to validate
 * @returns {Object} Validation result with isValid and errors
 */
const validatePasswordStrength = (password) => {
  const errors = [];
  const minLength = 8;
  const maxLength = 128;

  // Check minimum length
  if (password.length < minLength) {
    errors.push(`Password must be at least ${minLength} characters long`);
  }

  // Check maximum length
  if (password.length > maxLength) {
    errors.push(`Password must be at most ${maxLength} characters long`);
  }

  // Check for lowercase letter
  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter');
  }

  // Check for uppercase letter
  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter');
  }

  // Check for number
  if (!/\d/.test(password)) {
    errors.push('Password must contain at least one number');
  }

  // Check for special character
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push('Password must contain at least one special character');
  }

  // Check for common weak passwords
  const weakPasswords = [
    'password',
    '12345678',
    'qwerty123',
    'abc12345',
    'password1',
    'Password1',
    '123456789',
    'iloveyou',
    'sunshine',
    'princess',
  ];

  if (weakPasswords.includes(password.toLowerCase())) {
    errors.push('Password is too common. Please choose a stronger password');
  }

  return {
    isValid: errors.length === 0,
    errors,
    strength: calculatePasswordStrength(password),
  };
};

/**
 * Calculate password strength score
 * @param {string} password - Password to evaluate
 * @returns {Object} Strength score and level
 */
const calculatePasswordStrength = (password) => {
  let score = 0;

  // Length score
  if (password.length >= 8) score += 1;
  if (password.length >= 12) score += 1;
  if (password.length >= 16) score += 1;

  // Character type scores
  if (/[a-z]/.test(password)) score += 1;
  if (/[A-Z]/.test(password)) score += 1;
  if (/\d/.test(password)) score += 1;
  if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) score += 1;

  // Variety bonus
  const uniqueChars = new Set(password).size;
  if (uniqueChars >= 8) score += 1;
  if (uniqueChars >= 12) score += 1;

  // Determine strength level
  let level;
  if (score <= 2) {
    level = 'weak';
  } else if (score <= 4) {
    level = 'fair';
  } else if (score <= 6) {
    level = 'good';
  } else {
    level = 'strong';
  }

  return {
    score,
    maxScore: 9,
    level,
    percentage: Math.round((score / 9) * 100),
  };
};

/**
 * Generate a random password
 * @param {number} length - Password length (default: 16)
 * @param {Object} options - Generation options
 * @returns {string} Generated password
 */
const generateRandomPassword = (length = 16, options = {}) => {
  const {
    includeUppercase = true,
    includeLowercase = true,
    includeNumbers = true,
    includeSymbols = true,
  } = options;

  let charset = '';
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const numbers = '0123456789';
  const symbols = '!@#$%^&*()_+-=[]{}|;:,.<>?';

  if (includeLowercase) charset += lowercase;
  if (includeUppercase) charset += uppercase;
  if (includeNumbers) charset += numbers;
  if (includeSymbols) charset += symbols;

  if (charset === '') {
    charset = lowercase + uppercase + numbers;
  }

  let password = '';

  // Ensure at least one character from each selected category
  if (includeLowercase) password += lowercase[Math.floor(Math.random() * lowercase.length)];
  if (includeUppercase) password += uppercase[Math.floor(Math.random() * uppercase.length)];
  if (includeNumbers) password += numbers[Math.floor(Math.random() * numbers.length)];
  if (includeSymbols) password += symbols[Math.floor(Math.random() * symbols.length)];

  // Fill remaining length
  const remainingLength = Math.max(0, length - password.length);
  for (let i = 0; i < remainingLength; i++) {
    password += charset[Math.floor(Math.random() * charset.length)];
  }

  // Shuffle the password
  return password
    .split('')
    .sort(() => Math.random() - 0.5)
    .join('');
};

/**
 * Check if password needs rehashing (e.g., if salt rounds changed)
 * @param {string} hashedPassword - Current hashed password
 * @returns {boolean} True if password should be rehashed
 */
const needsRehash = (hashedPassword) => {
  try {
    // Extract the rounds from the hash
    const roundsMatch = hashedPassword.match(/^\$2[aby]\$(\d{2})\$/);
    if (!roundsMatch) {
      return true;
    }

    const currentRounds = parseInt(roundsMatch[1], 10);
    return currentRounds !== config.bcrypt.saltRounds;
  } catch (error) {
    return true;
  }
};

module.exports = {
  hashPassword,
  comparePassword,
  isValidHash,
  validatePasswordStrength,
  calculatePasswordStrength,
  generateRandomPassword,
  needsRehash,
};
