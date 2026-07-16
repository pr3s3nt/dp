// payment-service — service nội bộ, có DB riêng, không có route ra ngoài.
const express = require('express');
const { Pool } = require('pg');

const { PORT = 8080, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD } = process.env;

const pool = new Pool({
  host: DB_HOST, port: DB_PORT, database: DB_NAME, user: DB_USER, password: DB_PASSWORD,
});

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true }));

app.get('/payments', async (_req, res) => {
  const { rows } = await pool.query('SELECT id, order_id, amount, status FROM payments ORDER BY id DESC LIMIT 50');
  res.json(rows);
});

app.post('/payments', async (req, res) => {
  const { orderId, amount } = req.body;
  const { rows } = await pool.query(
    'INSERT INTO payments (order_id, amount, status) VALUES ($1, $2, $3) RETURNING id',
    [orderId, amount, 'success']
  );
  res.status(201).json({ id: rows[0].id, status: 'success' });
});

async function init() {
  await pool.query(`CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY, order_id INT NOT NULL, amount NUMERIC NOT NULL, status TEXT NOT NULL
  )`);
  app.listen(PORT, () => console.log(`payment-service listening on :${PORT}`));
}
init().catch((e) => { console.error(e); process.exit(1); });
