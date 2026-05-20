const { Pool } = require('pg');
const config = require('./config');

const pool = new Pool({
  user: config.database.user,
  host: config.database.host,
  database: config.database.database,
  password: config.database.password,
  port: config.database.port,
});

pool.on('error', (err) => {
  console.error('PostgreSQL error: ', err.message);
});

module.exports = pool;
