const express = require('express');
const tasksRouter = require('./routes/tasks');
const healthRouter = require('./routes/health');

const app = express();
app.use(express.json());
app.use('/tasks', tasksRouter);
app.use('/health', healthRouter);

app.get('/', (req, res) => {
  const acceptFormat = req.headers['accept'] || '';
  if (!acceptFormat.includes('text/html')) {
    return res.status(406).send('Invalid Accept Header: this endpoint only supports text/html\n');
  }
  res.status(200).send(`
    <html><body><h1>mywebapp — Task Tracker</h1>
        <ul>
          <li>GET /tasks - list of all tasks</li>
          <li>POST /tasks - create a new task</li>
          <li>POST /tasks/:id/done - change the task status to “done”</li>
        </ul>
      </body></html>
  `);
});

module.exports = app;
