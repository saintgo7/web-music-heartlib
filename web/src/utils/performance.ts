import { onCLS, onFCP, onINP, onLCP, onTTFB, type Metric } from 'web-vitals';

// Performance thresholds based on Core Web Vitals
export const PERFORMANCE_THRESHOLDS = {
  LCP: { good: 2500, needsImprovement: 4000 }, // Largest Contentful Paint
  FCP: { good: 1800, needsImprovement: 3000 }, // First Contentful Paint
  CLS: { good: 0.1, needsImprovement: 0.25 },  // Cumulative Layout Shift
  INP: { good: 200, needsImprovement: 500 },   // Interaction to Next Paint
  TTFB: { good: 800, needsImprovement: 1800 }, // Time to First Byte
} as const;

// Metric rating based on thresholds
type MetricRating = 'good' | 'needs-improvement' | 'poor';

function getMetricRating(name: string, value: number): MetricRating {
  const threshold = PERFORMANCE_THRESHOLDS[name as keyof typeof PERFORMANCE_THRESHOLDS];
  if (!threshold) return 'good';

  if (value <= threshold.good) return 'good';
  if (value <= threshold.needsImprovement) return 'needs-improvement';
  return 'poor';
}

// Callback for reporting metrics
type ReportCallback = (metric: Metric & { rating: MetricRating }) => void;

// Default console reporter for development
const defaultReporter: ReportCallback = (metric) => {
  const rating = metric.rating;
  const color = rating === 'good' ? '#0cce6b' : rating === 'needs-improvement' ? '#ffa400' : '#ff4e42';

  if (import.meta.env.DEV) {
    console.log(
      `%c[Web Vitals] ${metric.name}: ${metric.value.toFixed(2)}ms (${rating})`,
      `color: ${color}; font-weight: bold;`
    );
  }
};

// Analytics reporter (sends to backend/analytics service)
const analyticsReporter: ReportCallback = (metric) => {
  // Cloudflare Analytics Engine or custom backend
  const analyticsEndpoint = import.meta.env.VITE_ANALYTICS_ENDPOINT;

  if (analyticsEndpoint) {
    const body = JSON.stringify({
      name: metric.name,
      value: metric.value,
      rating: metric.rating,
      delta: metric.delta,
      id: metric.id,
      navigationType: metric.navigationType,
      url: window.location.href,
      timestamp: Date.now(),
    });

    // Use sendBeacon for reliability (won't be cancelled on page unload)
    if (navigator.sendBeacon) {
      navigator.sendBeacon(analyticsEndpoint, body);
    } else {
      fetch(analyticsEndpoint, {
        method: 'POST',
        body,
        headers: { 'Content-Type': 'application/json' },
        keepalive: true,
      }).catch(() => {
        // Silently fail for analytics
      });
    }
  }
};

// Combined reporter
const createReporter = (callback?: ReportCallback): ((metric: Metric) => void) => {
  return (metric: Metric) => {
    const rating = getMetricRating(metric.name, metric.value);
    const enhancedMetric = { ...metric, rating };

    defaultReporter(enhancedMetric);

    if (callback) {
      callback(enhancedMetric);
    }

    // Always send to analytics in production
    if (import.meta.env.PROD) {
      analyticsReporter(enhancedMetric);
    }
  };
};

// Initialize performance monitoring
export function initPerformanceMonitoring(callback?: ReportCallback): void {
  const reporter = createReporter(callback);

  // Core Web Vitals
  onLCP(reporter);    // Largest Contentful Paint
  onFCP(reporter);    // First Contentful Paint
  onCLS(reporter);    // Cumulative Layout Shift
  onINP(reporter);    // Interaction to Next Paint (replaces FID)
  onTTFB(reporter);   // Time to First Byte
}

// Performance observer for long tasks
export function observeLongTasks(): void {
  if (!('PerformanceObserver' in window)) return;

  try {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (import.meta.env.DEV) {
          console.warn(`[Long Task] Duration: ${entry.duration.toFixed(2)}ms`);
        }
      }
    });

    observer.observe({ entryTypes: ['longtask'] });
  } catch {
    // Long task observation not supported
  }
}

// Resource timing for debugging
export function logResourceTimings(): void {
  if (!import.meta.env.DEV) return;

  const resources = performance.getEntriesByType('resource') as PerformanceResourceTiming[];
  const grouped: Record<string, PerformanceResourceTiming[]> = {};

  resources.forEach((resource) => {
    const type = resource.initiatorType;
    if (!grouped[type]) grouped[type] = [];
    grouped[type].push(resource);
  });

  console.group('[Resource Timings]');
  Object.entries(grouped).forEach(([type, entries]) => {
    const totalDuration = entries.reduce((sum, e) => sum + e.duration, 0);
    console.log(`${type}: ${entries.length} resources, ${totalDuration.toFixed(2)}ms total`);
  });
  console.groupEnd();
}

// Export singleton initialization
let initialized = false;
export function initWebVitals(callback?: ReportCallback): void {
  if (initialized) return;
  initialized = true;

  initPerformanceMonitoring(callback);

  if (import.meta.env.DEV) {
    observeLongTasks();
    // Log resource timings after page load
    window.addEventListener('load', () => {
      setTimeout(logResourceTimings, 1000);
    });
  }
}

export default initWebVitals;
