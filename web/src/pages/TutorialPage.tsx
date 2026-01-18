import { useState } from 'react';
import { Link } from 'react-router-dom';

interface TutorialStep {
  id: number;
  title: string;
  description: string;
  details: string[];
  tips?: string[];
  warning?: string;
}

const installationSteps: Record<string, TutorialStep[]> = {
  windows: [
    {
      id: 1,
      title: 'Download the Installer',
      description: 'Download MuLa_Setup_x64.exe from the download page.',
      details: [
        'Visit the Download page and click "Windows 64-bit"',
        'The file (~80MB) will start downloading automatically',
        'Save the file to an easy-to-find location like your Desktop',
      ],
      tips: ['Use Windows 10 or 11 for best compatibility', 'Make sure you have at least 15GB of free disk space'],
    },
    {
      id: 2,
      title: 'Run the Installer',
      description: 'Double-click the installer to start the setup wizard.',
      details: [
        'Locate the downloaded MuLa_Setup_x64.exe file',
        'Double-click to run (you may need to click "Run anyway" if Windows shows a warning)',
        'Follow the on-screen instructions',
        'Choose an installation directory (default is recommended)',
      ],
      warning: 'Windows Defender may show a warning because the app is new. Click "More info" then "Run anyway" to proceed.',
    },
    {
      id: 3,
      title: 'Wait for AI Model Download',
      description: 'The installer will automatically download AI models (~6GB).',
      details: [
        'This step requires an internet connection',
        'The download may take 15-30 minutes depending on your connection',
        'Do not close the installer window during this process',
        'Models are downloaded from HuggingFace servers',
      ],
      tips: ['Use a stable internet connection', 'The models are only downloaded once and cached locally'],
    },
    {
      id: 4,
      title: 'Launch the Application',
      description: 'Find "MuLa Studio" on your desktop and start creating music!',
      details: [
        'A shortcut will be created on your Desktop',
        'Double-click "MuLa Studio" to launch',
        'Your default browser will open with the Gradio UI',
        'The application runs at http://127.0.0.1:7860',
      ],
    },
  ],
  macos: [
    {
      id: 1,
      title: 'Download the DMG',
      description: 'Download MuLa_Installer.dmg from the download page.',
      details: [
        'Visit the Download page and click "macOS"',
        'The DMG file (~50MB) will download to your Downloads folder',
        'Works on both Intel and Apple Silicon Macs',
      ],
      tips: ['Requires macOS 12 (Monterey) or later', 'Apple Silicon (M1/M2/M3) is recommended for faster generation'],
    },
    {
      id: 2,
      title: 'Install the Application',
      description: 'Open the DMG and drag the app to Applications.',
      details: [
        'Double-click the downloaded DMG file',
        'Drag "MuLa Studio" to the Applications folder',
        'Wait for the copy to complete',
        'Eject the DMG from your desktop',
      ],
      warning: 'On first launch, macOS may show "unidentified developer" warning. Go to System Preferences > Security & Privacy and click "Open Anyway".',
    },
    {
      id: 3,
      title: 'First Run Setup',
      description: 'Launch the app and wait for AI models to download.',
      details: [
        'Open Applications folder and double-click "MuLa Studio"',
        'Grant any permission requests (network, file access)',
        'AI models (~6GB) will download automatically',
        'This may take 15-30 minutes on first run',
      ],
    },
    {
      id: 4,
      title: 'Start Creating Music',
      description: 'The app is ready! Your browser will open automatically.',
      details: [
        'Safari or your default browser will open',
        'Access the Gradio UI at http://127.0.0.1:7860',
        'Enter lyrics and tags to generate music',
        'Generated files are saved to ~/MuLaStudio_Outputs',
      ],
    },
  ],
  linux: [
    {
      id: 1,
      title: 'Download the Install Script',
      description: 'Download mula_install.sh from the download page.',
      details: [
        'Visit the Download page and click "Linux"',
        'The shell script (~5KB) will download',
        'Save it to your home directory or Downloads',
      ],
      tips: ['Supports Ubuntu 20.04+, Fedora 35+, and Arch Linux', 'Python 3.10+ is required (will be installed if missing)'],
    },
    {
      id: 2,
      title: 'Run the Install Script',
      description: 'Open terminal and execute the install script.',
      details: [
        'Open your terminal application',
        'Navigate to where you downloaded the script: cd ~/Downloads',
        'Make it executable: chmod +x mula_install.sh',
        'Run with: ./mula_install.sh',
      ],
      warning: 'The script will ask for sudo password to install system dependencies.',
    },
    {
      id: 3,
      title: 'Wait for Installation',
      description: 'The script installs dependencies and downloads AI models.',
      details: [
        'System packages will be installed via apt/dnf/pacman',
        'Python virtual environment is created automatically',
        'AI models (~6GB) are downloaded from HuggingFace',
        'Total installation time: 20-40 minutes',
      ],
    },
    {
      id: 4,
      title: 'Launch the Application',
      description: 'Run mulastudio command or use the desktop shortcut.',
      details: [
        'Type "mulastudio" in terminal to launch',
        'Or find "MuLa Studio" in your applications menu',
        'Your browser will open automatically',
        'Access the UI at http://127.0.0.1:7860',
      ],
    },
  ],
};

const usageGuide = [
  {
    title: 'Writing Lyrics',
    content: 'Use tags like [Verse], [Chorus], [Bridge], [Outro] to structure your lyrics. Each section should be on its own line.',
    example: '[Verse]\nThe morning sun rises high\nA new day begins\n\n[Chorus]\nThis is my time to shine\nNothing can stop me now',
  },
  {
    title: 'Choosing Tags',
    content: 'Tags describe the style of music you want. You can combine multiple tags for more specific results.',
    example: 'pop, upbeat, happy, female vocal, acoustic guitar',
  },
  {
    title: 'Generation Settings',
    content: 'Adjust the generation length and quality settings for different results. Longer tracks take more time.',
    example: 'Length: 30-180 seconds\nQuality: Standard (faster) or High (better)',
  },
  {
    title: 'Output Files',
    content: 'Generated music is saved to your MuLaStudio_Outputs folder as MP3 files with timestamps.',
    example: '~/MuLaStudio_Outputs/music_2026-01-18_143022.mp3',
  },
];

export default function TutorialPage() {
  const [selectedOS, setSelectedOS] = useState<'windows' | 'macos' | 'linux'>('windows');

  return (
    <main className="pt-20 min-h-screen bg-gradient-to-b from-gray-50 to-white">
      <div className="container py-16">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Installation <span className="gradient-text">Tutorial</span>
          </h1>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Follow these step-by-step instructions to install ABADA Music Studio on your computer.
          </p>
        </div>

        {/* OS Selector */}
        <div className="flex justify-center gap-4 mb-12">
          {(['windows', 'macos', 'linux'] as const).map((os) => (
            <button
              key={os}
              onClick={() => setSelectedOS(os)}
              className={`px-6 py-3 rounded-xl font-medium transition-all ${
                selectedOS === os
                  ? 'bg-abada-primary text-white shadow-lg'
                  : 'bg-white text-gray-600 hover:bg-abada-light border border-gray-200'
              }`}
            >
              {os === 'windows' && 'Windows'}
              {os === 'macos' && 'macOS'}
              {os === 'linux' && 'Linux'}
            </button>
          ))}
        </div>

        {/* Installation Steps */}
        <div className="max-w-3xl mx-auto mb-16">
          <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">
            Installation Steps for {selectedOS === 'windows' ? 'Windows' : selectedOS === 'macos' ? 'macOS' : 'Linux'}
          </h2>

          <div className="space-y-6">
            {installationSteps[selectedOS].map((step) => (
              <div
                key={step.id}
                className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100"
              >
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 rounded-full bg-abada-primary text-white flex items-center justify-center font-bold flex-shrink-0">
                    {step.id}
                  </div>
                  <div className="flex-1">
                    <h3 className="text-lg font-bold text-gray-900 mb-2">{step.title}</h3>
                    <p className="text-gray-600 mb-4">{step.description}</p>

                    {/* Details */}
                    <ul className="space-y-2 mb-4">
                      {step.details.map((detail, index) => (
                        <li key={index} className="flex items-start gap-2 text-sm text-gray-600">
                          <svg className="w-5 h-5 text-abada-primary flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                          </svg>
                          {detail}
                        </li>
                      ))}
                    </ul>

                    {/* Tips */}
                    {step.tips && (
                      <div className="bg-blue-50 rounded-xl p-4 mb-4">
                        <h4 className="text-sm font-medium text-blue-700 mb-2 flex items-center gap-2">
                          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                          </svg>
                          Tips
                        </h4>
                        <ul className="space-y-1">
                          {step.tips.map((tip, index) => (
                            <li key={index} className="text-sm text-blue-600">{tip}</li>
                          ))}
                        </ul>
                      </div>
                    )}

                    {/* Warning */}
                    {step.warning && (
                      <div className="bg-amber-50 rounded-xl p-4">
                        <h4 className="text-sm font-medium text-amber-700 mb-1 flex items-center gap-2">
                          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                          </svg>
                          Important
                        </h4>
                        <p className="text-sm text-amber-600">{step.warning}</p>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Usage Guide */}
        <div className="max-w-3xl mx-auto mb-16">
          <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">
            How to Use ABADA Music Studio
          </h2>

          <div className="grid md:grid-cols-2 gap-6">
            {usageGuide.map((guide, index) => (
              <div
                key={index}
                className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100"
              >
                <h3 className="text-lg font-bold text-gray-900 mb-2">{guide.title}</h3>
                <p className="text-gray-600 text-sm mb-4">{guide.content}</p>
                <div className="bg-gray-50 rounded-xl p-4">
                  <p className="text-xs font-medium text-gray-500 uppercase mb-2">Example</p>
                  <pre className="text-sm text-gray-700 whitespace-pre-wrap font-mono">
                    {guide.example}
                  </pre>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* FAQ Section */}
        <div className="max-w-3xl mx-auto mb-16">
          <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">
            Frequently Asked Questions
          </h2>

          <div className="space-y-4">
            {[
              {
                q: 'How long does music generation take?',
                a: 'With a GPU (NVIDIA RTX 2060+ or Apple Silicon), generation takes about 2-3 minutes. CPU-only mode takes 8-15 minutes.',
              },
              {
                q: 'Can I use generated music commercially?',
                a: 'The AI model is licensed under CC BY-NC 4.0, meaning it\'s free for non-commercial use. Contact us for commercial licensing.',
              },
              {
                q: 'Why is my GPU not being used?',
                a: 'Make sure you have the latest NVIDIA drivers installed. The installer should detect your GPU automatically. Check the console output for any CUDA errors.',
              },
              {
                q: 'Where are generated files saved?',
                a: 'All generated music is saved to ~/MuLaStudio_Outputs (or %USERPROFILE%\\MuLaStudio_Outputs on Windows) as MP3 files.',
              },
              {
                q: 'Can I run multiple generations at once?',
                a: 'It\'s recommended to run one generation at a time to avoid memory issues. Each generation uses significant GPU/CPU resources.',
              },
            ].map((faq, index) => (
              <div
                key={index}
                className="bg-white rounded-xl p-6 shadow-sm border border-gray-100"
              >
                <h3 className="font-bold text-gray-900 mb-2">{faq.q}</h3>
                <p className="text-gray-600 text-sm">{faq.a}</p>
              </div>
            ))}
          </div>

          <div className="text-center mt-8">
            <Link to="/faq" className="text-abada-primary hover:underline">
              View all FAQs
            </Link>
          </div>
        </div>

        {/* Help Section */}
        <div className="max-w-3xl mx-auto text-center">
          <div className="bg-gradient-to-r from-abada-primary/10 to-abada-secondary/10 rounded-3xl p-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              Need More Help?
            </h2>
            <p className="text-gray-600 mb-6">
              If you're having trouble with installation or usage, we're here to help.
            </p>
            <div className="flex flex-wrap justify-center gap-4">
              <a
                href="https://github.com/saintgo7/web-music-heartlib/issues"
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-primary"
              >
                Report an Issue
              </a>
              <a
                href="https://github.com/saintgo7/web-music-heartlib/discussions"
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-secondary"
              >
                Community Forum
              </a>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
