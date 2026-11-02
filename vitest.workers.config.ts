import {cloudflareTest} from '@cloudflare/vitest-plugin';
import {defineConfig} from 'vitest/config';

// Worker 코드 테스트. 실제 Workers 런타임(workerd) 안에서 실행한다.
export default defineConfig({
  plugins: [cloudflareTest({wrangler: {configPath: './wrangler.jsonc'}})],
  test: {
    include: ['src/worker/**/*.test.ts'],
  },
});
