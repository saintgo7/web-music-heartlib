import { useState } from 'react';

interface DownloadOption {
  id: string;
  name: string;
  icon: React.ReactNode;
  fileSize: string;
  note: string;
  url: string;
  recommended?: boolean;
}

const downloadOptions: DownloadOption[] = [
  {
    id: 'windows-x64',
    name: 'Windows 64-bit',
    icon: (
      <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
        <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/>
      </svg>
    ),
    fileSize: '~80MB',
    note: 'Windows 10/11 recommended',
    url: 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/MuLa_Setup_x64.exe',
    recommended: true,
  },
  {
    id: 'windows-x86',
    name: 'Windows 32-bit',
    icon: (
      <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
        <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/>
      </svg>
    ),
    fileSize: '~80MB',
    note: 'CPU only (no GPU acceleration)',
    url: 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/MuLa_Setup_x86.exe',
  },
  {
    id: 'macos',
    name: 'macOS',
    icon: (
      <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
      </svg>
    ),
    fileSize: '~50MB',
    note: 'Intel & Apple Silicon',
    url: 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/MuLa_Installer.dmg',
  },
  {
    id: 'linux',
    name: 'Linux',
    icon: (
      <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12.504 0c-.155 0-.311.004-.466.016a9.89 9.89 0 0 0-.722.064 7.03 7.03 0 0 0-.702.14c-.19.049-.38.104-.57.166-.14.05-.28.104-.42.163-.222.087-.44.186-.655.293a6.3 6.3 0 0 0-.602.341 5.67 5.67 0 0 0-.55.386 5.08 5.08 0 0 0-.496.435c-.138.14-.27.286-.398.437a5.22 5.22 0 0 0-.616.896c-.086.148-.168.3-.246.455a6.45 6.45 0 0 0-.2.478c-.052.136-.1.273-.145.41-.04.128-.077.257-.11.388a7.38 7.38 0 0 0-.132.657c-.035.205-.062.41-.082.617a8.5 8.5 0 0 0-.036.67v.108c0 .202.003.407.014.613.01.21.025.42.048.629.024.21.054.42.092.629.04.21.086.418.14.626.053.21.113.417.18.622.067.205.14.407.22.605.082.198.168.394.26.586.093.19.19.378.292.562.102.183.21.362.32.536.11.175.225.344.344.51.12.164.244.323.37.478.126.155.256.304.388.449.133.145.27.285.408.42.14.135.28.265.424.39.143.125.29.244.437.359.147.115.297.225.448.33.15.105.303.205.458.299.155.095.313.184.471.268.159.083.32.162.481.234.162.073.326.14.49.202.164.062.33.118.497.169.166.05.335.093.503.13.168.039.338.07.508.095.17.025.341.044.513.057.171.013.343.02.515.02.172 0 .344-.007.515-.02.172-.013.343-.032.513-.057.17-.025.34-.056.508-.095.168-.037.337-.08.503-.13.167-.051.333-.107.497-.169.164-.062.328-.129.49-.202.161-.072.322-.151.481-.234.158-.084.316-.173.471-.268.155-.094.308-.194.458-.299.151-.105.301-.215.448-.33.147-.115.294-.234.437-.359.144-.125.284-.255.424-.39.138-.135.275-.275.408-.42.132-.145.262-.294.388-.449.126-.155.25-.314.37-.478.119-.166.234-.335.344-.51.11-.174.218-.353.32-.536.102-.184.199-.372.292-.562.092-.192.178-.388.26-.586.08-.198.153-.4.22-.605.067-.205.127-.412.18-.622.054-.208.1-.416.14-.626.038-.209.068-.419.092-.629.023-.209.038-.419.048-.629.011-.206.014-.411.014-.613v-.108a8.5 8.5 0 0 0-.036-.67 7.66 7.66 0 0 0-.082-.617 7.38 7.38 0 0 0-.132-.657 6.15 6.15 0 0 0-.11-.388 5.72 5.72 0 0 0-.145-.41 6.45 6.45 0 0 0-.2-.478 5.72 5.72 0 0 0-.246-.455 5.22 5.22 0 0 0-.616-.896 4.88 4.88 0 0 0-.398-.437 5.08 5.08 0 0 0-.496-.435 5.67 5.67 0 0 0-.55-.386 6.3 6.3 0 0 0-.602-.341 6.6 6.6 0 0 0-.655-.293 6.03 6.03 0 0 0-.42-.163 7.03 7.03 0 0 0-.57-.166 7.03 7.03 0 0 0-.702-.14 9.89 9.89 0 0 0-.722-.064 11.85 11.85 0 0 0-.466-.016Z"/>
      </svg>
    ),
    fileSize: '~5KB',
    note: 'Shell script for Ubuntu/Fedora/Arch',
    url: 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/mula_install.sh',
  },
];

export default function DownloadSection() {
  const [downloadCount, setDownloadCount] = useState<Record<string, number>>({
    'windows-x64': 847,
    'windows-x86': 124,
    'macos': 432,
    'linux': 289,
  });

  const handleDownload = async (option: DownloadOption) => {
    // Track download (in production, this would call the API)
    setDownloadCount(prev => ({
      ...prev,
      [option.id]: prev[option.id] + 1,
    }));

    // Open download URL
    window.open(option.url, '_blank');
  };

  return (
    <section className="section bg-white" id="download">
      <div className="container">
        {/* Section Header */}
        <div className="text-center mb-16">
          <span className="inline-block px-4 py-2 rounded-full bg-abada-light text-abada-primary text-sm font-medium mb-4">
            Download
          </span>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold text-gray-900 mb-4">
            Get <span className="gradient-text">ABADA Music Studio</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Choose your operating system and start creating AI-generated music in minutes.
          </p>
        </div>

        {/* Download Cards */}
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-5xl mx-auto">
          {downloadOptions.map((option) => (
            <div
              key={option.id}
              className={`relative bg-white rounded-2xl p-6 border-2 transition-all duration-300 hover:shadow-xl ${
                option.recommended
                  ? 'border-abada-primary shadow-lg'
                  : 'border-gray-100 hover:border-abada-primary/50'
              }`}
            >
              {/* Recommended Badge */}
              {option.recommended && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                  <span className="px-3 py-1 bg-abada-primary text-white text-xs font-medium rounded-full">
                    Recommended
                  </span>
                </div>
              )}

              {/* Icon */}
              <div className="w-16 h-16 mx-auto rounded-2xl bg-gray-100 flex items-center justify-center text-gray-700 mb-4">
                {option.icon}
              </div>

              {/* Content */}
              <h3 className="text-lg font-bold text-gray-900 text-center mb-2">
                {option.name}
              </h3>
              <p className="text-2xl font-bold text-abada-primary text-center mb-1">
                {option.fileSize}
              </p>
              <p className="text-sm text-gray-500 text-center mb-4">
                {option.note}
              </p>

              {/* Download Button */}
              <button
                onClick={() => handleDownload(option)}
                className="w-full btn btn-primary py-3"
              >
                <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Download
              </button>

              {/* Download Count */}
              <p className="text-xs text-gray-400 text-center mt-3">
                {downloadCount[option.id].toLocaleString()} downloads
              </p>
            </div>
          ))}
        </div>

        {/* Additional Info */}
        <div className="mt-16 max-w-3xl mx-auto">
          <div className="bg-gray-50 rounded-2xl p-6 md:p-8">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Installation Notes</h3>
            <ul className="space-y-3 text-gray-600">
              <li className="flex items-start gap-3">
                <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span>AI models (~6GB) will be downloaded automatically during first run</span>
              </li>
              <li className="flex items-start gap-3">
                <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span>No Python installation required - everything is bundled</span>
              </li>
              <li className="flex items-start gap-3">
                <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span>NVIDIA GPU (RTX 2060+) or Apple Silicon (M1+) recommended for faster generation</span>
              </li>
              <li className="flex items-start gap-3">
                <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span>Generated music is saved to ~/MuLaStudio_Outputs folder</span>
              </li>
            </ul>

            <div className="mt-6 pt-6 border-t border-gray-200">
              <p className="text-sm text-gray-500">
                Having trouble? Check our{' '}
                <a href="/tutorial" className="text-abada-primary hover:underline">
                  installation guide
                </a>{' '}
                or{' '}
                <a
                  href="https://github.com/saintgo7/web-music-heartlib/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-abada-primary hover:underline"
                >
                  report an issue
                </a>
                .
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
