interface Requirement {
  label: string;
  minimum: string;
  recommended: string;
  icon: React.ReactNode;
}

const requirements: Requirement[] = [
  {
    label: 'RAM',
    minimum: '8GB',
    recommended: '16GB+',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" />
      </svg>
    ),
  },
  {
    label: 'Storage',
    minimum: '15GB',
    recommended: '20GB+ SSD',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
      </svg>
    ),
  },
  {
    label: 'GPU (Optional)',
    minimum: 'CPU Only',
    recommended: 'NVIDIA RTX 2060+ / Apple M1+',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z" />
      </svg>
    ),
  },
  {
    label: 'Operating System',
    minimum: 'Windows 10 / macOS 12 / Ubuntu 20.04',
    recommended: 'Latest version',
    icon: (
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
      </svg>
    ),
  },
];

export default function SystemRequirements() {
  return (
    <section className="section bg-white" id="requirements">
      <div className="container">
        {/* Section Header */}
        <div className="text-center mb-16">
          <span className="inline-block px-4 py-2 rounded-full bg-abada-light text-abada-primary text-sm font-medium mb-4">
            System Requirements
          </span>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold text-gray-900 mb-4">
            Check Your <span className="gradient-text">System Compatibility</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            ABADA Music Studio runs on most modern computers.
            Here's what you need to get started.
          </p>
        </div>

        {/* Requirements Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-5xl mx-auto">
          {requirements.map((req, index) => (
            <div
              key={index}
              className="bg-gray-50 rounded-2xl p-6 text-center hover:bg-white hover:shadow-lg transition-all duration-300 border border-transparent hover:border-gray-100"
            >
              {/* Icon */}
              <div className="w-14 h-14 mx-auto rounded-xl bg-abada-light text-abada-primary flex items-center justify-center mb-4">
                {req.icon}
              </div>

              {/* Label */}
              <h3 className="text-sm font-medium text-gray-500 uppercase tracking-wide mb-2">
                {req.label}
              </h3>

              {/* Minimum */}
              <div className="mb-3">
                <span className="text-xs text-gray-400">Minimum</span>
                <p className="text-lg font-bold text-gray-900">{req.minimum}</p>
              </div>

              {/* Recommended */}
              <div className="pt-3 border-t border-gray-200">
                <span className="text-xs text-abada-primary font-medium">Recommended</span>
                <p className="text-sm font-semibold text-gray-700">{req.recommended}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Performance Notes */}
        <div className="mt-12 max-w-3xl mx-auto">
          <div className="bg-gradient-to-r from-abada-primary/5 to-abada-secondary/5 rounded-2xl p-6 md:p-8">
            <h3 className="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-abada-primary" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
              </svg>
              Performance Tips
            </h3>
            <ul className="grid md:grid-cols-2 gap-4">
              <li className="flex items-start gap-3 text-gray-600">
                <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span className="text-sm">
                  <strong>GPU acceleration</strong> reduces generation time from ~10min to ~2min
                </span>
              </li>
              <li className="flex items-start gap-3 text-gray-600">
                <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span className="text-sm">
                  <strong>SSD storage</strong> significantly improves model loading speed
                </span>
              </li>
              <li className="flex items-start gap-3 text-gray-600">
                <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span className="text-sm">
                  <strong>16GB RAM</strong> allows longer tracks without memory issues
                </span>
              </li>
              <li className="flex items-start gap-3 text-gray-600">
                <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span className="text-sm">
                  <strong>Close other apps</strong> during generation for best results
                </span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}
