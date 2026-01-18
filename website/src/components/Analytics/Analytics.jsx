import { useEffect } from 'react';

const Analytics = () => {
  useEffect(() => {
    if (!import.meta.env.VITE_ENABLE_ANALYTICS) return;

    const trackingId = import.meta.env.VITE_GA_TRACKING_ID;
    if (!trackingId) return;

    const script1 = document.createElement('script');
    script1.async = true;
    script1.src = `https://www.googletagmanager.com/gtag/js?id=${trackingId}`;
    document.head.appendChild(script1);

    const script2 = document.createElement('script');
    script2.innerHTML = `
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '${trackingId}');
    `;
    document.head.appendChild(script2);

    return () => {
      document.head.removeChild(script1);
      document.head.removeChild(script2);
    };
  }, []);

  return null;
};

export default Analytics;
