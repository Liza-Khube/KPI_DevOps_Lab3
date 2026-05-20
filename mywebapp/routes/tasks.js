const express = require('express');
const db = require('../db');

const router = express.Router();

const getAcceptFormat = (req) => {
  const acceptFormat = req.headers['accept'] || '';

  if (acceptFormat.includes('text/html')) return 'html';
  if (acceptFormat.includes('application/json')) return 'json';
  return null;
};

router.get('/', async (req, res) => {
  const acceptFormat = getAcceptFormat(req);

  if (acceptFormat === null)
    return res.status(406).send('Invalid Accept Header: use text/html or application/json\n');

  try {
    const { rows } = await db.query(
      `
        SELECT * FROM tasks ORDER BY status DESC, created_at DESC
        `,
    );

    if (acceptFormat === 'html') {
      let html = '<html><body><h1>Tasks</h1>';
      html +=
        '<table border="1"><tr><th>ID</th><th>Title</th><th>Status</th><th>Created At</th></tr>';

      html += rows
        .map(
          (row) =>
            `<tr><td>${row.id}</td><td>${row.title}</td><td>${row.status}</td><td>${row.created_at}</td></tr>`,
        )
        .join('');

      html += '</table></body></html>';
      return res.status(200).send(html);
    }
    return res.status(200).json(rows);
  } catch (err) {
    res.status(500).send(`Error: ${err.message}\n`);
  }
});

router.post('/', async (req, res) => {
  const { title } = req.body;
  if (!title) {
    return res.status(400).send('Title is required\n');
  }

  const acceptFormat = getAcceptFormat(req);

  if (acceptFormat === null)
    return res.status(406).send('Invalid Accept Header: use text/html or application/json\n');

  try {
    const { rows } = await db.query('INSERT INTO tasks (title) VALUES ($1) RETURNING *', [title]);
    if (acceptFormat === 'html') {
      const newTask = rows[0];
      return res.status(201).send(`<html>
          <body><h1>Task created</h1>
            <p>ID: ${newTask.id}</p><p>Title: ${newTask.title}</p><p>Status: ${newTask.status}</p><p>Created At: ${newTask.created_at}</p>
          </body></html>`);
    }
    return res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).send(`Error: ${err.message}\n`);
  }
});

router.post('/:id/done', async (req, res) => {
  const acceptFormat = getAcceptFormat(req);

  if (acceptFormat === null)
    return res.status(406).send('Invalid Accept Header: use text/html or application/json\n');

  const { id } = req.params;

  try {
    const { rows } = await db.query('UPDATE tasks SET status = $1 WHERE id = $2 RETURNING *', [
      'done',
      id,
    ]);

    if (rows.length === 0) {
      return res.status(404).send(`Task with id ${id} not found\n`);
    }

    if (acceptFormat === 'html') {
      const updatedTask = rows[0];
      return res.status(200).send(`<html>
          <body><h1>Task updated</h1>
            <p>ID: ${updatedTask.id}</p><p>Title: ${updatedTask.title}</p><p>Status: ${updatedTask.status}</p><p>Created At: ${updatedTask.created_at}</p>
          </body></html>`);
    }
    return res.status(200).json(rows[0]);
  } catch (err) {
    res.status(500).send(`Error: ${err.message}\n`);
  }
});

module.exports = router;
