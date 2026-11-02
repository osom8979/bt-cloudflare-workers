import {exports} from 'cloudflare:workers';
import {describe, expect, it} from 'vitest';

describe('/api/health', () => {
  it('Worker 상태와 실행 환경을 반환한다', async () => {
    const response = await exports.default.fetch('http://example.com/api/health');

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({status: 'ok', environment: 'production'});
  });

  it('없는 API 경로는 JSON 404 를 반환한다', async () => {
    const response = await exports.default.fetch('http://example.com/api/unknown');

    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({error: 'not_found'});
  });
});
