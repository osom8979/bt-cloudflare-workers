import {fileURLToPath} from 'node:url';

import {cloudflare} from '@cloudflare/vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import {defineConfig} from 'vite';

export default defineConfig({
  server: {
    port: 48891,
    fs: {
      // Vite 기본값에 Worker 로컬 시크릿(`.dev.vars*`)을 더한다.
      deny: ['.env', '.env.*', '.dev.vars', '.dev.vars.*', '*.{crt,pem}', '**/.git/**'],
    },
  },
  plugins: [react(), tailwindcss(), cloudflare()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src/react-app', import.meta.url)),
    },
  },
});
