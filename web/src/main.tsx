import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { initWebVitals } from './utils/performance'
import * as serviceWorker from './utils/serviceWorker'

// Initialize Core Web Vitals monitoring
initWebVitals()

// Render the app
createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)

// Register service worker for offline support and caching
// Only in production to avoid caching issues during development
serviceWorker.register({
  onSuccess: () => {
    console.log('[SW] Content cached for offline use')
  },
  onUpdate: () => {
    console.log('[SW] New content available, please refresh')
  },
})
