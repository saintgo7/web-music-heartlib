import { useState } from 'react';
import { Link } from 'react-router-dom';

interface DownloadOption {
  id: string;
  name: string;
  icon: React.ReactNode;
  fileSize: string;
  note: string;
  url: string;
  requirements: string[];
  recommended?: boolean;
}

const downloadOptions: DownloadOption[] = [
  {
    id: 'windows-x64',
    name: 'Windows 64-bit',
    icon: (
      <svg className="w-12 h-12" fill="currentColor" viewBox="0 0 24 24">
        <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/>
      </svg>
    ),
    fileSize: '~80MB',
    note: 'Windows 10/11 (64-bit)',
    url: 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/MuLa_Setup_x64.exe',
    requirements: ['Windows 10/11 64-bit', '8GB RAM minimum', 'NVIDIA GPU recommended'],
    recommended: true,
  },
  {
    id: 'windows-x86',
    name: 'Windows 32-bit',
    icon: (
      <svg className="w-12 h-12" fill="currentColor" viewBox="0 0 24 24">
        <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/>
      </svg>
    ),
    fileSize: '~80MB',
    note: 'Windows 10/11 (32-bit)',
    url: 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/MuLa_Setup_x86.exe',
    requirements: ['Windows 10/11 32-bit', '8GB RAM minimum', 'CPU only (no GPU acceleration)'],
  },
  {
    id: 'macos',
    name: 'macOS',
    icon: (
      <svg className="w-12 h-12" fill="currentColor" viewBox="0 0 24 24">
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
      </svg>
    ),
    fileSize: '~50MB',
    note: 'macOS 12+ (Monterey or later)',
    url: 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/MuLa_Installer.dmg',
    requirements: ['macOS 12 (Monterey) or later', 'Intel or Apple Silicon (M1/M2/M3)', '8GB RAM minimum'],
  },
  {
    id: 'linux',
    name: 'Linux',
    icon: (
      <svg className="w-12 h-12" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12.504 0c-.155 0-.311.004-.466.016a9.89 9.89 0 0 0-.722.064 7.03 7.03 0 0 0-.702.14c-.19.049-.38.104-.57.166-.14.05-.28.104-.42.163-.222.087-.44.186-.655.293a6.3 6.3 0 0 0-.602.341 5.67 5.67 0 0 0-.55.386 5.08 5.08 0 0 0-.496.435c-.138.14-.27.286-.398.437a5.22 5.22 0 0 0-.616.896c-.086.148-.168.3-.246.455a6.45 6.45 0 0 0-.2.478c-.052.136-.1.273-.145.41-.04.128-.077.257-.11.388a7.38 7.38 0 0 0-.132.657c-.035.205-.062.41-.082.617a8.5 8.5 0 0 0-.036.67v.108c0 .202.003.407.014.613.01.21.025.42.048.629.024.21.054.42.092.629.04.21.086.418.14.626.053.21.113.417.18.622.067.205.14.407.22.605.082.198.168.394.26.586.093.19.19.378.292.562.102.183.21.362.32.536.11.175.225.344.344.51.12.164.244.323.37.478.126.155.256.304.388.449.133.145.27.285.408.42.14.135.28.265.424.39.143.125.29.244.437.359.147.115.297.225.448.33.15.105.303.205.458.299.155.095.313.184.471.268.159.083.32.162.481.234.162.073.326.14.49.202.164.062.33.118.497.169.166.05.335.093.503.13.168.039.338.07.508.095.17.025.341.044.513.057.171.013.343.02.515.02.172 0 .344-.007.515-.02.172-.013.343-.032.513-.057.17-.025.34-.056.508-.095.168-.037.337-.08.503-.13.167-.051.333-.107.497-.169.164-.062.328-.129.49-.202.161-.072.322-.151.481-.234.158-.084.316-.173.471-.268.155-.094.308-.194.458-.299.151-.105.301-.215.448-.33.147-.115.294-.234.437-.359.144-.125.284-.255.424-.39.138-.135.275-.275.408-.42.132-.145.262-.294.388-.449.126-.155.25-.314.37-.478.119-.166.234-.335.344-.51.11-.174.218-.353.32-.536.102-.184.199-.372.292-.562.092-.192.178-.388.26-.586.08-.198.153-.4.22-.605.067-.205.127-.412.18-.622.054-.208.1-.416.14-.626.038-.209.068-.419.092-.629.023-.209.038-.419.048-.629.011-.206.014-.411.014-.613v-.108a8.5 8.5 0 0 0-.036-.67 7.66 7.66 0 0 0-.082-.617 7.38 7.38 0 0 0-.132-.657 6.15 6.15 0 0 0-.11-.388 5.72 5.72 0 0 0-.145-.41 6.45 6.45 0 0 0-.2-.478 5.72 5.72 0 0 0-.246-.455 5.22 5.22 0 0 0-.616-.896 4.88 4.88 0 0 0-.398-.437 5.08 5.08 0 0 0-.496-.435 5.67 5.67 0 0 0-.55-.386 6.3 6.3 0 0 0-.602-.341 6.6 6.6 0 0 0-.655-.293 6.03 6.03 0 0 0-.42-.163 7.03 7.03 0 0 0-.57-.166 7.03 7.03 0 0 0-.702-.14 9.89 9.89 0 0 0-.722-.064 11.85 11.85 0 0 0-.466-.016Z"/>
      </svg>
    ),
    fileSize: '~5KB',
    note: 'Ubuntu 20.04+ / Fedora 35+ / Arch',
    url: 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/mula_install.sh',
    requirements: ['Ubuntu 20.04+, Fedora 35+, or Arch Linux', 'Terminal access', '8GB RAM minimum'],
  },
];

export default function DownloadPage() {
  const [selectedOS, setSelectedOS] = useState<string>('windows-x64');

  const handleDownload = (option: DownloadOption) => {
    // Track download (in production, this would call the API)
    console.log('Download:', option.id);
    window.open(option.url, '_blank');
  };

  const selectedOption = downloadOptions.find(o => o.id === selectedOS);

  return (
    <main className="pt-20 min-h-screen bg-gradient-to-b from-gray-50 to-white">
      <div className="container py-16">
        {/* Header */}
        <div className="text-center mb-16">
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Download <span className="gradient-text">ABADA Music Studio</span>
          </h1>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Choose your operating system to download the installer.
            Installation is automatic and takes about 15-30 minutes.
          </p>
        </div>

        {/* OS Selection */}
        <div className="max-w-4xl mx-auto mb-12">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {downloadOptions.map((option) => (
              <button
                key={option.id}
                onClick={() => setSelectedOS(option.id)}
                className={`relative p-6 rounded-2xl border-2 transition-all duration-300 ${
                  selectedOS === option.id
                    ? 'border-abada-primary bg-abada-light shadow-lg'
                    : 'border-gray-200 bg-white hover:border-abada-primary/50'
                }`}
              >
                {option.recommended && (
                  <span className="absolute -top-2 -right-2 px-2 py-1 bg-green-500 text-white text-xs font-medium rounded-full">
                    Recommended
                  </span>
                )}
                <div className={`mx-auto mb-3 ${selectedOS === option.id ? 'text-abada-primary' : 'text-gray-400'}`}>
                  {option.icon}
                </div>
                <h3 className={`text-sm font-medium ${selectedOS === option.id ? 'text-abada-primary' : 'text-gray-700'}`}>
                  {option.name}
                </h3>
              </button>
            ))}
          </div>
        </div>

        {/* Selected OS Details */}
        {selectedOption && (
          <div className="max-w-2xl mx-auto">
            <div className="bg-white rounded-3xl shadow-xl p-8 border border-gray-100">
              {/* Header */}
              <div className="text-center mb-8">
                <div className="w-20 h-20 mx-auto rounded-2xl bg-abada-light text-abada-primary flex items-center justify-center mb-4">
                  {selectedOption.icon}
                </div>
                <h2 className="text-2xl font-bold text-gray-900 mb-2">{selectedOption.name}</h2>
                <p className="text-gray-600">{selectedOption.note}</p>
              </div>

              {/* Info Grid */}
              <div className="grid grid-cols-2 gap-4 mb-8">
                <div className="bg-gray-50 rounded-xl p-4 text-center">
                  <p className="text-sm text-gray-500 mb-1">File Size</p>
                  <p className="text-xl font-bold text-gray-900">{selectedOption.fileSize}</p>
                </div>
                <div className="bg-gray-50 rounded-xl p-4 text-center">
                  <p className="text-sm text-gray-500 mb-1">Version</p>
                  <p className="text-xl font-bold text-gray-900">v1.0.0</p>
                </div>
              </div>

              {/* Requirements */}
              <div className="mb-8">
                <h3 className="text-sm font-medium text-gray-500 uppercase tracking-wide mb-3">
                  Requirements
                </h3>
                <ul className="space-y-2">
                  {selectedOption.requirements.map((req, index) => (
                    <li key={index} className="flex items-center gap-3 text-gray-600">
                      <svg className="w-5 h-5 text-green-500 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                      </svg>
                      {req}
                    </li>
                  ))}
                </ul>
              </div>

              {/* Download Button */}
              <button
                onClick={() => handleDownload(selectedOption)}
                className="w-full btn btn-primary py-4 text-lg"
              >
                <svg className="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Download for {selectedOption.name}
              </button>

              {/* SHA256 */}
              <p className="text-xs text-gray-400 text-center mt-4">
                SHA256 verification available on{' '}
                <a
                  href="https://github.com/saintgo7/web-music-heartlib/releases"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-abada-primary hover:underline"
                >
                  GitHub Releases
                </a>
              </p>
            </div>
          </div>
        )}

        {/* Installation Steps */}
        <div className="max-w-3xl mx-auto mt-16">
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-8">
            Installation Steps
          </h2>

          <div className="space-y-4">
            {[
              {
                step: 1,
                title: 'Download the installer',
                description: 'Click the download button above to get the installer for your OS.',
              },
              {
                step: 2,
                title: 'Run the installer',
                description: 'Double-click the downloaded file and follow the installation wizard.',
              },
              {
                step: 3,
                title: 'Wait for model download',
                description: 'On first run, AI models (~6GB) will be downloaded automatically.',
              },
              {
                step: 4,
                title: 'Start creating music!',
                description: 'Open "MuLa Studio" from your desktop and start generating music.',
              },
            ].map((item) => (
              <div
                key={item.step}
                className="flex items-start gap-4 bg-white rounded-xl p-6 border border-gray-100"
              >
                <div className="w-10 h-10 rounded-full bg-abada-primary text-white flex items-center justify-center font-bold flex-shrink-0">
                  {item.step}
                </div>
                <div>
                  <h3 className="font-bold text-gray-900 mb-1">{item.title}</h3>
                  <p className="text-gray-600">{item.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Help Section */}
        <div className="max-w-3xl mx-auto mt-16 text-center">
          <p className="text-gray-600 mb-4">
            Need help with installation?
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link to="/tutorial" className="btn btn-secondary">
              View Tutorial
            </Link>
            <a
              href="https://github.com/saintgo7/web-music-heartlib/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-secondary"
            >
              Report Issue
            </a>
          </div>
        </div>
      </div>
    </main>
  );
}
