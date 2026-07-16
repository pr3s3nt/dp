// backend — Express + Postgres, CRUD ghi chú.
// Serve dưới prefix /api vì Traefik PathPrefix không strip prefix.
const express = require('express');
const { Pool } = require('pg');

const { PORT = 8080, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD } = process.env;

const pool = new Pool({
  host: DB_HOST, port: DB_PORT, database: DB_NAME, user: DB_USER, password: DB_PASSWORD,
});

const app = express();
app.use(express.json());

app.get(['/health', '/api/health'], (_req, res) => res.json({ ok: true }));

app.get('/api/notes', async (_req, res) => {
  const { rows } = await pool.query('SELECT id, text, created_at FROM notes ORDER BY id DESC');
  res.json(rows);
});

app.post('/api/notes', async (req, res) => {
  const { text } = req.body;
  if (!text) return res.status(400).json({ error: 'text is required' });
  const { rows } = await pool.query(
    'INSERT INTO notes (text) VALUES ($1) RETURNING id, text, created_at', [text]
  );
  res.status(201).json(rows[0]);
});

app.delete('/api/notes/:id', async (req, res) => {
  await pool.query('DELETE FROM notes WHERE id = $1', [req.params.id]);
  res.status(204).end();
});

async function init(retries = 20) {
  // Postgres (StatefulSet) có thể lên chậm hơn app -> retry
  for (let i = 0; i < retries; i++) {
    try {
      await pool.query(`CREATE TABLE IF NOT EXISTS notes (
        id SERIAL PRIMARY KEY,
        text TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )`);
      app.listen(PORT, () => console.log(`backend listening on :${PORT}`));
      return;
    } catch (e) {
      console.log(`DB chưa sẵn sàng (${e.message}), thử lại sau 3s...`);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
  console.error('Không kết nối được DB'); process.exit(1);
}
init();
