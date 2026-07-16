import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    // dev local: vite chạy :5173, proxy /api sang backend local :8080
    proxy: { '/api': 'http://localhost:8080' },
  },
});
