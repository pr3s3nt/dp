// api-gateway — forward /api/* sang service nội bộ.
// ORDERS_URL / PAYMENTS_URL do platform bơm vào từ resource `type: service`.
const express = require('express');
const app = express();
app.use(express.json());

const { PORT = 8080, ORDERS_URL, PAYMENTS_URL } = process.env;

app.get('/health', (_req, res) => res.json({ ok: true }));

async function forward(base, req, res) {
  try {
    const r = await fetch(base + req.path.replace(/^\/api/, ''), {
      method: req.method,
      headers: { 'Content-Type': 'application/json' },
      body: ['POST', 'PUT', 'PATCH'].includes(req.method) ? JSON.stringify(req.body) : undefined,
    });
    res.status(r.status).json(await r.json().catch(() => ({})));
  } catch (e) {
    res.status(502).json({ error: 'upstream unavailable', detail: e.message });
  }
}

app.all(/^\/api\/orders/, (req, res) => forward(ORDERS_URL, req, res));
app.all(/^\/api\/payments/, (req, res) => forward(PAYMENTS_URL, req, res));

app.listen(PORT, () => console.log(`api-gateway listening on :${PORT}`));
