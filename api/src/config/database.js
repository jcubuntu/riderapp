'use strict';

const mariadb = require('mariadb');

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'riderapp',
  connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT, 10) || 10,
  acquireTimeout: 30000,
  connectTimeout: 10000,
  waitForConnections: true,
  idleTimeout: 60000,
  // Connection options
  allowPublicKeyRetrieval: true,
  multipleStatements: false,
  dateStrings: true,
  // Character set
  charset: 'utf8mb4',
  collation: 'utf8mb4_unicode_ci',
};

// Create connection pool
const pool = mariadb.createPool(dbConfig);

/**
 * Get a connection from the pool
 * @returns {Promise<mariadb.PoolConnection>}
 */
const getConnection = async () => {
  try {
    const connection = await pool.getConnection();
    return connection;
  } catch (error) {
    console.error('Error getting database connection:', error.message);
    throw error;
  }
};

/**
 * Execute a query with parameters
 * @param {string} sql - SQL query string
 * @param {Array} params - Query parameters
 * @returns {Promise<any>}
 */
const query = async (sql, params = []) => {
  let connection;
  try {
    connection = await pool.getConnection();
    const result = await connection.query(sql, params);
    return result;
  } catch (error) {
    console.error('Database query error:', error.message);
    throw error;
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

/**
 * Execute a query and return a single row
 * @param {string} sql - SQL query string
 * @param {Array} params - Query parameters
 * @returns {Promise<any>}
 */
const queryOne = async (sql, params = []) => {
  const result = await query(sql, params);
  return result[0] || null;
};

/**
 * Execute an insert query and return the inserted ID
 * @param {string} sql - SQL query string
 * @param {Array} params - Query parameters
 * @returns {Promise<{insertId: number, affectedRows: number}>}
 */
const insert = async (sql, params = []) => {
  const result = await query(sql, params);
  return {
    insertId: Number(result.insertId),
    affectedRows: result.affectedRows,
  };
};

/**
 * Execute an update query
 * @param {string} sql - SQL query string
 * @param {Array} params - Query parameters
 * @returns {Promise<{affectedRows: number, changedRows: number}>}
 */
const update = async (sql, params = []) => {
  const result = await query(sql, params);
  return {
    affectedRows: result.affectedRows,
    changedRows: result.changedRows || result.affectedRows,
  };
};

/**
 * Execute a delete query
 * @param {string} sql - SQL query string
 * @param {Array} params - Query parameters
 * @returns {Promise<{affectedRows: number}>}
 */
const remove = async (sql, params = []) => {
  const result = await query(sql, params);
  return {
    affectedRows: result.affectedRows,
  };
};

/**
 * Execute multiple queries in a transaction
 * @param {Function} callback - Callback function that receives the connection
 * @returns {Promise<any>}
 */
const transaction = async (callback) => {
  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    const result = await callback(connection);

    await connection.commit();
    return result;
  } catch (error) {
    if (connection) {
      await connection.rollback();
    }
    console.error('Transaction error:', error.message);
    throw error;
  } finally {
    if (connection) {
      connection.release();
    }
  }
};

/**
 * Check database connection health
 * @returns {Promise<boolean>}
 */
const healthCheck = async () => {
  try {
    await query('SELECT 1');
    return true;
  } catch (error) {
    console.error('Database health check failed:', error.message);
    return false;
  }
};

/**
 * Close the connection pool
 * @returns {Promise<void>}
 */
const closePool = async () => {
  try {
    await pool.end();
    console.log('Database pool closed');
  } catch (error) {
    console.error('Error closing database pool:', error.message);
    throw error;
  }
};

module.exports = {
  pool,
  getConnection,
  query,
  queryOne,
  insert,
  update,
  remove,
  transaction,
  healthCheck,
  closePool,
};
