// order-service — có Postgres riêng, gọi payment-service khi tạo order.
// Mọi cấu hình đến từ env do platform bơm: DB_* (từ resource postgres), PAYMENTS_URL (từ resource service).
const express = require('express');
const { Pool } = require('pg');

const { PORT = 8080, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, PAYMENTS_URL } = process.env;

const pool = new Pool({
  host: DB_HOST, port: DB_PORT, database: DB_NAME, user: DB_USER, password: DB_PASSWORD,
});

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true }));

app.get('/orders', async (_req, res) => {
  const { rows } = await pool.query('SELECT id, item, amount, status FROM orders ORDER BY id DESC LIMIT 50');
  res.json(rows);
});

app.post('/orders', async (req, res) => {
  const { item, amount } = req.body;
  const { rows } = await pool.query(
    'INSERT INTO orders (item, amount, status) VALUES ($1, $2, $3) RETURNING id',
    [item, amount, 'pending']
  );
  const id = rows[0].id;
  // Gọi payment-service qua DNS nội bộ:
  let status = 'payment_failed';
  try {
    const r = await fetch(`${PAYMENTS_URL}/payments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ orderId: id, amount }),
    });
    if (r.ok) status = 'paid';
  } catch (_) { /* payment-service chưa sẵn sàng */ }
  await pool.query('UPDATE orders SET status = $1 WHERE id = $2', [status, id]);
  res.status(201).json({ id, status });
});

async function init() {
  await pool.query(`CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY, item TEXT NOT NULL, amount NUMERIC NOT NULL, status TEXT NOT NULL
  )`);
  app.listen(PORT, () => console.log(`order-service listening on :${PORT}`));
}
init().catch((e) => { console.error(e); process.exit(1); });
