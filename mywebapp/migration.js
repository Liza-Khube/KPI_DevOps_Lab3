const pool = require('./db');

const migration = async () => {
  const client = await pool.connect();
  try {
    console.log('Start migration');

    await client.query(
      `
    CREATE TABLE IF NOT EXISTS tasks (
    id     SERIAL PRIMARY KEY,
    title   VARCHAR(255) NOT NULL,
    status  VARCHAR(50) NOT NULL DEFAULT 'undone'
            CHECK (status IN ('undone', 'done')),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
    )
    `,
    );

    await client.query(
      `
    CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)
    `,
    );

    console.log('Migration completed successfully');
  } catch (err) {
    console.error('Migration failed: ', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
};

migration();
