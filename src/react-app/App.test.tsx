import {render, screen} from '@testing-library/react';
import {afterEach, describe, expect, it, vi} from 'vitest';

import App from '@/App';

describe('App', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('Worker 응답의 상태와 환경을 표시한다', async () => {
    vi.stubGlobal(
      'fetch',
      vi
        .fn()
        .mockResolvedValue(Response.json({status: 'ok', environment: 'development'}))
    );

    render(<App />);

    expect(await screen.findByText('정상')).toBeInTheDocument();
    expect(screen.getByText('development')).toBeInTheDocument();
  });

  it('요청이 실패하면 응답 없음을 표시한다', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('network')));

    render(<App />);

    expect(await screen.findByText('응답 없음')).toBeInTheDocument();
  });
});
