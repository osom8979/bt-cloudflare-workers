import {useHealth} from '@/hooks/useHealth';

const STATUS_LABEL = {
  loading: '확인하는 중…',
  ready: '정상',
  failed: '응답 없음',
} as const;

const STATUS_TONE = {
  loading: 'text-muted-foreground',
  ready: 'text-success',
  failed: 'text-destructive',
} as const;

export default function App() {
  const health = useHealth();

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-xl flex-col justify-center gap-6 px-4 py-12">
      <header className="flex flex-col gap-1">
        <h1 className="text-lg font-semibold tracking-tight">bt-cloudflare-workers</h1>
        <p className="text-muted-foreground text-sm">
          Cloudflare Workers 연동 상태를 표시합니다.
        </p>
      </header>

      <dl className="bg-card border-border divide-border divide-y rounded-md border text-sm">
        <div className="flex items-center justify-between gap-4 px-4 py-3">
          <dt className="text-muted-foreground">Worker</dt>
          <dd className={`font-mono ${STATUS_TONE[health.phase]}`} role="status">
            {STATUS_LABEL[health.phase]}
          </dd>
        </div>
        <div className="flex items-center justify-between gap-4 px-4 py-3">
          <dt className="text-muted-foreground">환경</dt>
          <dd className="font-mono">
            {health.phase === 'ready' ? health.environment : '—'}
          </dd>
        </div>
      </dl>
    </main>
  );
}
