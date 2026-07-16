import React, { useEffect, useState } from 'react';

// Gọi /api cùng host — Traefik định tuyến / -> frontend, /api -> backend.
export default function App() {
  const [notes, setNotes] = useState([]);
  const [text, setText] = useState('');
  const [error, setError] = useState(null);

  async function load() {
    try {
      const res = await fetch('/api/notes');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setNotes(await res.json());
      setError(null);
    } catch (e) {
      setError(`Không gọi được backend: ${e.message}`);
    }
  }

  async function add(e) {
    e.preventDefault();
    if (!text.trim()) return;
    await fetch('/api/notes', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text }),
    });
    setText('');
    load();
  }

  async function remove(id) {
    await fetch(`/api/notes/${id}`, { method: 'DELETE' });
    load();
  }

  useEffect(() => { load(); }, []);

  return (
    <div style={{ fontFamily: 'system-ui, sans-serif', maxWidth: 560, margin: '48px auto', padding: '0 16px' }}>
      <h1>Notes — demo IDP</h1>
      <p style={{ color: '#666' }}>React (Vite) + Express + PostgreSQL trên Rook Ceph. Note lưu trong DB — xóa pod Postgres xong note vẫn còn là PVC hoạt động.</p>
      {error && <p style={{ color: 'crimson' }}>{error}</p>}
      <form onSubmit={add} style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Nội dung note..."
          style={{ flex: 1, padding: 8 }}
        />
        <button type="submit" style={{ padding: '8px 16px' }}>Thêm</button>
      </form>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {notes.map((n) => (
          <li key={n.id} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #eee' }}>
            <span>{n.text}</span>
            <button onClick={() => remove(n.id)} style={{ color: 'crimson' }}>Xóa</button>
          </li>
        ))}
      </ul>
      {notes.length === 0 && !error && <p style={{ color: '#999' }}>Chưa có note nào.</p>}
    </div>
  );
}
