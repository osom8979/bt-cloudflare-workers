import {fileURLToPath} from 'node:url';

import react from '@vitejs/plugin-react';
import {defineConfig} from 'vitest/config';

// 브라우저 코드 테스트. Worker 테스트는 vitest.workers.config.ts 에서 실행한다.
export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/react-app/**/*.test.{ts,tsx}'],
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src/react-app', import.meta.url)),
    },
  },
});
