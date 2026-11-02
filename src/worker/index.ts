import {Hono} from 'hono';
import {logger} from 'hono/logger';
import {trimTrailingSlash} from 'hono/trailing-slash';

import {health} from './api/health';

const app = new Hono<{Bindings: Env}>();

// 요청 로그는 로컬 개발에서만 남긴다. vitest 도 DEV 모드이므로 테스트 출력과 구분한다.
if (import.meta.env.DEV && import.meta.env.MODE !== 'test') {
  app.use(logger());
}

app.onError((err, c) => {
  console.error(
    JSON.stringify({
      message: 'request failed',
      method: c.req.method,
      path: c.req.path,
      error: err instanceof Error ? err.message : String(err),
    })
  );
  return c.json({error: 'internal_error'}, 500);
});

app.notFound(c => c.json({error: 'not_found'}, 404));

app.use(trimTrailingSlash());
app.route('/api/health', health);

export default {
  fetch: app.fetch,
} satisfies ExportedHandler<Env>;
