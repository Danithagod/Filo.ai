import { useEffect } from 'react';
import * as Sentry from '@sentry/react';

const ErrorLogging = () => {
  useEffect(() => {
    if (!import.meta.env.VITE_ENABLE_SENTRY) return;

    const dsn = import.meta.env.VITE_SENTRY_DSN;
    if (!dsn) return;

    Sentry.init({
      dsn: dsn,
      integrations: [
        Sentry.browserTracingIntegration(),
        Sentry.replayIntegration({
          maskAllText: false,
          blockAllMedia: false,
        }),
      ],
      tracesSampleRate: 0.1,
      replaysSessionSampleRate: 0.1,
      replaysOnErrorSampleRate: 1.0,
      environment: import.meta.env.VITE_ENV || 'production',
    });
  }, []);

  return null;
};

export default ErrorLogging;
