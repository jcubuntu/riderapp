/**
 * Database Migration Runner for RiderApp
 *
 * This script reads and executes all SQL migration files in order.
 * It tracks which migrations have been run in a migrations table.
 *
 * Usage:
 *   node src/database/migrate.js [command]
 *
 * Commands:
 *   up        Run all pending migrations (default)
 *   down      Rollback the last migration batch
 *   status    Show migration status
 *   fresh     Drop all tables and re-run all migrations
 *   reset     Rollback all migrations
 *
 * Environment Variables:
 *   DB_HOST     Database host (default: localhost)
 *   DB_PORT     Database port (default: 3306)
 *   DB_USER     Database user (default: root)
 *   DB_PASSWORD Database password
 *   DB_NAME     Database name (default: riderapp)
 */

// Load environment variables
require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

// Configuration from environment variables
const config = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'riderapp',
  multipleStatements: true,
  charset: 'utf8mb4',
};

// Migrations directory
const MIGRATIONS_DIR = path.join(__dirname, 'migrations');

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

/**
 * Log helper functions
 */
const log = {
  info: (msg) => console.log(`${colors.blue}[INFO]${colors.reset} ${msg}`),
  success: (msg) => console.log(`${colors.green}[SUCCESS]${colors.reset} ${msg}`),
  warning: (msg) => console.log(`${colors.yellow}[WARNING]${colors.reset} ${msg}`),
  error: (msg) => console.log(`${colors.red}[ERROR]${colors.reset} ${msg}`),
  migration: (msg) => console.log(`${colors.cyan}[MIGRATION]${colors.reset} ${msg}`),
};

/**
 * Create database connection
 */
async function createConnection() {
  try {
    const connection = await mysql.createConnection(config);
    log.success('Connected to database');
    return connection;
  } catch (error) {
    if (error.code === 'ER_BAD_DB_ERROR') {
      // Database doesn't exist, create it
      log.warning(`Database '${config.database}' does not exist. Creating...`);
      const tempConfig = { ...config };
      delete tempConfig.database;
      const tempConnection = await mysql.createConnection(tempConfig);
      await tempConnection.query(
        `CREATE DATABASE IF NOT EXISTS \`${config.database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
      );
      await tempConnection.end();
      log.success(`Database '${config.database}' created`);
      return mysql.createConnection(config);
    }
    throw error;
  }
}

/**
 * Create migrations tracking table if it doesn't exist
 */
async function createMigrationsTable(connection) {
  const sql = `
    CREATE TABLE IF NOT EXISTS migrations (
      id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
      migration VARCHAR(255) NOT NULL,
      batch INT UNSIGNED NOT NULL,
      executed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY uk_migration (migration)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `;
  await connection.query(sql);
  log.info('Migrations table ready');
}

/**
 * Get list of all migration files
 */
function getMigrationFiles() {
  if (!fs.existsSync(MIGRATIONS_DIR)) {
    throw new Error(`Migrations directory not found: ${MIGRATIONS_DIR}`);
  }

  const files = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((file) => file.endsWith('.sql'))
    .sort();

  return files;
}

/**
 * Get list of executed migrations
 */
async function getExecutedMigrations(connection) {
  try {
    const [rows] = await connection.query(
      'SELECT migration, batch FROM migrations ORDER BY id'
    );
    return rows;
  } catch {
    return [];
  }
}

/**
 * Get the current batch number
 */
async function getCurrentBatch(connection) {
  try {
    const [rows] = await connection.query(
      'SELECT MAX(batch) as batch FROM migrations'
    );
    return (rows[0].batch || 0) + 1;
  } catch {
    return 1;
  }
}

/**
 * Read and parse a migration file
 */
function readMigrationFile(filename) {
  const filepath = path.join(MIGRATIONS_DIR, filename);
  const content = fs.readFileSync(filepath, 'utf8');
  return content;
}

/**
 * Execute a single migration
 */
async function executeMigration(connection, filename, batch) {
  const sql = readMigrationFile(filename);

  try {
    // Execute the migration SQL
    await connection.query(sql);

    // Record the migration
    await connection.query(
      'INSERT INTO migrations (migration, batch) VALUES (?, ?)',
      [filename, batch]
    );

    log.migration(`Migrated: ${filename}`);
    return true;
  } catch (error) {
    log.error(`Failed to migrate ${filename}: ${error.message}`);
    throw error;
  }
}

/**
 * Run all pending migrations
 */
async function runMigrations(connection) {
  await createMigrationsTable(connection);

  const allFiles = getMigrationFiles();
  const executed = await getExecutedMigrations(connection);
  const executedNames = executed.map((m) => m.migration);

  const pending = allFiles.filter((f) => !executedNames.includes(f));

  if (pending.length === 0) {
    log.success('Nothing to migrate. All migrations are up to date.');
    return;
  }

  const batch = await getCurrentBatch(connection);
  log.info(`Running ${pending.length} migration(s) in batch ${batch}...`);

  for (const file of pending) {
    await executeMigration(connection, file, batch);
  }

  log.success(`Migrated ${pending.length} file(s) successfully`);
}

/**
 * Show migration status
 */
async function showStatus(connection) {
  await createMigrationsTable(connection);

  const allFiles = getMigrationFiles();
  const executed = await getExecutedMigrations(connection);
  const executedMap = new Map(executed.map((m) => [m.migration, m.batch]));

  console.log('\n' + colors.bright + 'Migration Status' + colors.reset);
  console.log('='.repeat(60));

  for (const file of allFiles) {
    const batch = executedMap.get(file);
    if (batch !== undefined) {
      console.log(
        `${colors.green}[Ran]${colors.reset}     ${file} (batch: ${batch})`
      );
    } else {
      console.log(`${colors.yellow}[Pending]${colors.reset} ${file}`);
    }
  }

  console.log('='.repeat(60) + '\n');
}

/**
 * Rollback the last batch of migrations
 */
async function rollbackMigrations(connection) {
  const [rows] = await connection.query(
    'SELECT MAX(batch) as batch FROM migrations'
  );
  const lastBatch = rows[0].batch;

  if (!lastBatch) {
    log.warning('Nothing to rollback');
    return;
  }

  const [migrations] = await connection.query(
    'SELECT migration FROM migrations WHERE batch = ? ORDER BY id DESC',
    [lastBatch]
  );

  log.info(`Rolling back batch ${lastBatch} (${migrations.length} migration(s))...`);

  for (const { migration } of migrations) {
    // For simplicity, we just remove from tracking table
    // In a full implementation, you'd have DOWN migrations
    await connection.query('DELETE FROM migrations WHERE migration = ?', [
      migration,
    ]);
    log.migration(`Rolled back: ${migration}`);
  }

  log.success('Rollback completed');
}

/**
 * Reset all migrations (rollback all)
 */
async function resetMigrations(connection) {
  const [migrations] = await connection.query(
    'SELECT migration FROM migrations ORDER BY id DESC'
  );

  if (migrations.length === 0) {
    log.warning('Nothing to reset');
    return;
  }

  log.info(`Resetting ${migrations.length} migration(s)...`);

  await connection.query('DELETE FROM migrations');

  log.success('All migrations reset');
}

/**
 * Fresh migration - drop all tables and re-run
 */
async function freshMigrations(connection) {
  log.warning('Dropping all tables...');

  // Disable foreign key checks
  await connection.query('SET FOREIGN_KEY_CHECKS = 0');

  // Get all tables
  const [tables] = await connection.query(
    `SELECT table_name FROM information_schema.tables
     WHERE table_schema = ? AND table_type = 'BASE TABLE'`,
    [config.database]
  );

  // Drop all tables
  for (const { table_name } of tables) {
    await connection.query(`DROP TABLE IF EXISTS \`${table_name}\``);
    log.info(`Dropped table: ${table_name}`);
  }

  // Re-enable foreign key checks
  await connection.query('SET FOREIGN_KEY_CHECKS = 1');

  log.success('All tables dropped');

  // Run all migrations
  await runMigrations(connection);
}

/**
 * Main function
 */
async function main() {
  const command = process.argv[2] || 'up';
  let connection;

  try {
    connection = await createConnection();

    switch (command) {
      case 'up':
        await runMigrations(connection);
        break;
      case 'down':
        await rollbackMigrations(connection);
        break;
      case 'status':
        await showStatus(connection);
        break;
      case 'fresh':
        console.log(
          `${colors.red}${colors.bright}WARNING: This will drop ALL tables!${colors.reset}`
        );
        console.log('Press Ctrl+C to cancel or wait 3 seconds to continue...\n');
        await new Promise((resolve) => setTimeout(resolve, 3000));
        await freshMigrations(connection);
        break;
      case 'reset':
        await resetMigrations(connection);
        break;
      default:
        log.error(`Unknown command: ${command}`);
        console.log('\nAvailable commands:');
        console.log('  up      Run all pending migrations (default)');
        console.log('  down    Rollback the last migration batch');
        console.log('  status  Show migration status');
        console.log('  fresh   Drop all tables and re-run all migrations');
        console.log('  reset   Rollback all migrations');
        process.exit(1);
    }
  } catch (error) {
    log.error(error.message);
    if (process.env.DEBUG) {
      console.error(error);
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      log.info('Database connection closed');
    }
  }
}

// Run the script
main();
