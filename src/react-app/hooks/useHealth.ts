import {useEffect, useState} from 'react';

export type HealthState =
  {phase: 'loading'} | {phase: 'ready'; environment: string} | {phase: 'failed'};

export function useHealth(): HealthState {
  const [state, setState] = useState<HealthState>({phase: 'loading'});

  useEffect(() => {
    const controller = new AbortController();

    fetch('/api/health', {signal: controller.signal})
      .then(async response => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        const {environment} = (await response.json()) as {environment: string};
        setState({phase: 'ready', environment});
      })
      .catch(() => {
        if (!controller.signal.aborted) {
          setState({phase: 'failed'});
        }
      });

    return () => {
      controller.abort();
    };
  }, []);

  return state;
}
