const request = require('supertest');
const app = require('../app');
const db = require('../db');

jest.mock('../config', () => ({
  server: { host: '127.0.0.1', port: 8080 },
  database: {
    host: 'localhost',
    port: 5432,
    user: 'test',
    password: 'test',
    database: 'test',
  },
}));

jest.mock('../db', () => ({
  query: jest.fn(),
}));

afterEach(() => {
  jest.clearAllMocks();
});

describe('GET /', () => {
  test('return 200 with HTML when Accept header: text/html', async () => {
    const res = await request(app).get('/').set('Accept', 'text/html');
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/html/);
    expect(res.text).toContain('mywebapp — Task Tracker');
  });

  test('return 406 when no-html Accept header', async () => {
    const res = await request(app).get('/').set('Accept', 'application/json');
    expect(res.status).toBe(406);
    expect(res.text).toContain('Invalid Accept Header');
  });

  test('return 406 without Accept header', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(406);
  });
});

describe('GET /health/alive', () => {
  test('return 200 OK', async () => {
    const res = await request(app).get('/health/alive');
    expect(res.status).toBe(200);
    expect(res.text.trim()).toBe('OK');
  });
});

describe('GET /health/ready', () => {
  test('return 200 when DB is available', async () => {
    db.query.mockResolvedValueOnce({ rows: [{ '?column?': 1 }] });
    const res = await request(app).get('/health/ready');
    expect(res.status).toBe(200);
    expect(res.text.trim()).toBe('OK');
  });

  test('return 500 when DB is not available', async () => {
    db.query.mockRejectedValueOnce(new Error('connection refused'));
    const res = await request(app).get('/health/ready');
    expect(res.status).toBe(500);
    expect(res.text).toContain('Database connection failed');
  });
});

describe('GET /tasks', () => {
  const mockTasks = [
    { id: 1, title: 'Task A', status: 'undone', created_at: new Date('2026-05-01') },
    { id: 2, title: 'Task B', status: 'done', created_at: new Date('2026-05-02') },
  ];

  test('return JSON list of tasks', async () => {
    db.query.mockResolvedValueOnce({ rows: mockTasks });
    const res = await request(app).get('/tasks').set('Accept', 'application/json');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body).toHaveLength(2);
    expect(res.body[0].title).toBe('Task A');
  });

  test('return HTML table of tasks', async () => {
    db.query.mockResolvedValueOnce({ rows: mockTasks });
    const res = await request(app).get('/tasks').set('Accept', 'text/html');
    expect(res.status).toBe(200);
    expect(res.text).toContain('<table');
    expect(res.text).toContain('Task A');
    expect(res.text).toContain('Task B');
  });

  test('return 406 for invalid Accept header', async () => {
    const res = await request(app).get('/tasks').set('Accept', 'text/plain');
    expect(res.status).toBe(406);
  });

  test('return empty list', async () => {
    db.query.mockResolvedValueOnce({ rows: [] });
    const res = await request(app).get('/tasks').set('Accept', 'application/json');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(0);
  });

  test('return 500 on DB error', async () => {
    db.query.mockRejectedValueOnce(new Error('db error'));
    const res = await request(app).get('/tasks').set('Accept', 'application/json');
    expect(res.status).toBe(500);
  });
});

describe('POST /tasks', () => {
  const newTask = { id: 1, title: 'New Task', status: 'undone', created_at: new Date() };

  test('create task and return JSON (201)', async () => {
    db.query.mockResolvedValueOnce({ rows: [newTask] });
    const res = await request(app)
      .post('/tasks')
      .set('Accept', 'application/json')
      .send({ title: 'New Task' });
    expect(res.status).toBe(201);
    expect(res.body.title).toBe('New Task');
    expect(res.body.status).toBe('undone');
  });

  test('create task and return HTML (201)', async () => {
    db.query.mockResolvedValueOnce({ rows: [newTask] });
    const res = await request(app)
      .post('/tasks')
      .set('Accept', 'text/html')
      .send({ title: 'New Task' });
    expect(res.status).toBe(201);
    expect(res.text).toContain('Task created');
    expect(res.text).toContain('New Task');
  });

  test('return 400 if title is missing', async () => {
    const res = await request(app).post('/tasks').set('Accept', 'application/json').send({});
    expect(res.status).toBe(400);
    expect(res.text).toContain('Title is required');
  });

  test('return 406 for invalid Accept header', async () => {
    const res = await request(app)
      .post('/tasks')
      .set('Accept', 'text/plain')
      .send({ title: 'Task' });
    expect(res.status).toBe(406);
  });

  test('return 500 on DB error', async () => {
    db.query.mockRejectedValueOnce(new Error('db error'));
    const res = await request(app)
      .post('/tasks')
      .set('Accept', 'application/json')
      .send({ title: 'New Task' });
    expect(res.status).toBe(500);
  });
});

describe('POST /tasks/:id/done', () => {
  const doneTask = { id: 1, title: 'Task', status: 'done', created_at: new Date() };

  test('mark task as done and return JSON', async () => {
    db.query.mockResolvedValueOnce({ rows: [doneTask] });
    const res = await request(app).post('/tasks/1/done').set('Accept', 'application/json');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('done');
  });

  test('mark task as done and return HTML', async () => {
    db.query.mockResolvedValueOnce({ rows: [doneTask] });
    const res = await request(app).post('/tasks/1/done').set('Accept', 'text/html');
    expect(res.status).toBe(200);
    expect(res.text).toContain('Task updated');
    expect(res.text).toContain('done');
  });

  test('return 404 if task is not found', async () => {
    db.query.mockResolvedValueOnce({ rows: [] });
    const res = await request(app).post('/tasks/999/done').set('Accept', 'application/json');
    expect(res.status).toBe(404);
    expect(res.text).toContain('not found');
  });

  test('return 406 for invalid Accept header', async () => {
    const res = await request(app).post('/tasks/1/done').set('Accept', 'text/plain');
    expect(res.status).toBe(406);
  });

  test('return 500 on DB error', async () => {
    db.query.mockRejectedValueOnce(new Error('db error'));
    const res = await request(app).post('/tasks/1/done').set('Accept', 'application/json');
    expect(res.status).toBe(500);
  });
});
