import { Link } from 'react-router-dom';

// Generate stable waveform heights using a seeded random
function generateWaveformHeights(count: number, seed: number): number[] {
  const heights: number[] = [];
  let current = seed;
  for (let i = 0; i < count; i++) {
    current = (current * 1103515245 + 12345) & 0x7fffffff;
    heights.push((current % 80) + 20);
  }
  return heights;
}

// Pre-computed waveform heights for consistency
const HERO_WAVEFORM_HEIGHTS = generateWaveformHeights(30, 42);

export default function Hero() {
  return (
    <section className="relative min-h-screen flex items-center pt-20 overflow-hidden">
      {/* Background Gradient */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-gradient-to-br from-abada-light via-white to-purple-50" />
        <div className="absolute top-0 right-0 w-1/2 h-1/2 bg-gradient-to-bl from-abada-primary/10 to-transparent rounded-full blur-3xl" />
        <div className="absolute bottom-0 left-0 w-1/3 h-1/3 bg-gradient-to-tr from-abada-secondary/10 to-transparent rounded-full blur-3xl" />
      </div>

      <div className="container">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Text Content */}
          <div className="text-center lg:text-left">
            {/* Badge */}
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-abada-light text-abada-primary text-sm font-medium mb-6">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-abada-primary opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-abada-primary"></span>
              </span>
              Open Source AI Music Generation
            </div>

            {/* Headline */}
            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-gray-900 mb-6 leading-tight">
              AI로 나만의
              <br />
              <span className="gradient-text">음악을 만든다</span>
            </h1>

            {/* Subheadline */}
            <p className="text-lg md:text-xl text-gray-600 mb-8 max-w-xl mx-auto lg:mx-0 text-balance">
              한 번의 클릭으로 시작하는 음악 생성.
              <br />
              Windows, macOS, Linux 모두 지원합니다.
            </p>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start mb-8">
              <Link to="/download" className="btn btn-primary text-lg px-8 py-4">
                <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Download Now
              </Link>
              <Link to="/tutorial" className="btn btn-secondary text-lg px-8 py-4">
                <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Watch Tutorial
              </Link>
            </div>

            {/* Feature Pills */}
            <div className="flex flex-wrap gap-3 justify-center lg:justify-start">
              <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-100 text-green-700 text-sm font-medium">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                100% Free
              </span>
              <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-100 text-blue-700 text-sm font-medium">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M3 5a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2h-2.22l.123.489.804.804A1 1 0 0113 18H7a1 1 0 01-.707-1.707l.804-.804L7.22 15H5a2 2 0 01-2-2V5zm5.771 7H5V5h10v7H8.771z" clipRule="evenodd" />
                </svg>
                Offline Mode
              </span>
              <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-purple-100 text-purple-700 text-sm font-medium">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M12.316 3.051a1 1 0 01.633 1.265l-4 12a1 1 0 11-1.898-.632l4-12a1 1 0 011.265-.633zM5.707 6.293a1 1 0 010 1.414L3.414 10l2.293 2.293a1 1 0 11-1.414 1.414l-3-3a1 1 0 010-1.414l3-3a1 1 0 011.414 0zm8.586 0a1 1 0 011.414 0l3 3a1 1 0 010 1.414l-3 3a1 1 0 11-1.414-1.414L16.586 10l-2.293-2.293a1 1 0 010-1.414z" clipRule="evenodd" />
                </svg>
                Open Source
              </span>
            </div>
          </div>

          {/* Visual Content */}
          <div className="relative">
            {/* Main Card */}
            <div className="relative bg-white rounded-3xl shadow-2xl p-6 md:p-8 border border-gray-100">
              {/* Mock UI */}
              <div className="space-y-6">
                {/* Header */}
                <div className="flex items-center gap-3">
                  <div className="flex gap-2">
                    <div className="w-3 h-3 rounded-full bg-red-400"></div>
                    <div className="w-3 h-3 rounded-full bg-yellow-400"></div>
                    <div className="w-3 h-3 rounded-full bg-green-400"></div>
                  </div>
                  <div className="flex-1 text-center text-sm text-gray-400 font-medium">
                    MuLa Studio
                  </div>
                </div>

                {/* Input Section */}
                <div className="space-y-4">
                  <div className="bg-gray-50 rounded-xl p-4">
                    <label className="text-xs font-medium text-gray-500 uppercase tracking-wide">Lyrics</label>
                    <p className="text-sm text-gray-700 mt-2 leading-relaxed">
                      [Verse]<br/>
                      The morning light comes through the window<br/>
                      A brand new day is here<br/>
                      [Chorus]<br/>
                      This is my moment...
                    </p>
                  </div>

                  <div className="bg-gray-50 rounded-xl p-4">
                    <label className="text-xs font-medium text-gray-500 uppercase tracking-wide">Tags</label>
                    <div className="flex flex-wrap gap-2 mt-2">
                      <span className="px-3 py-1 bg-abada-primary/10 text-abada-primary text-sm rounded-lg">pop</span>
                      <span className="px-3 py-1 bg-abada-primary/10 text-abada-primary text-sm rounded-lg">upbeat</span>
                      <span className="px-3 py-1 bg-abada-primary/10 text-abada-primary text-sm rounded-lg">happy</span>
                    </div>
                  </div>
                </div>

                {/* Generate Button */}
                <button className="w-full btn btn-primary py-4">
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Generate Music
                </button>

                {/* Audio Waveform Mock */}
                <div className="bg-gradient-to-r from-abada-primary/5 to-abada-secondary/5 rounded-xl p-4">
                  <div className="flex items-center gap-4">
                    <button className="w-10 h-10 rounded-full bg-abada-primary text-white flex items-center justify-center flex-shrink-0">
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clipRule="evenodd" />
                      </svg>
                    </button>
                    <div className="flex-1 h-12 flex items-center gap-1">
                      {HERO_WAVEFORM_HEIGHTS.map((height, i) => (
                        <div
                          key={i}
                          className="flex-1 bg-abada-primary/30 rounded-full"
                          style={{ height: `${height}%` }}
                        ></div>
                      ))}
                    </div>
                    <span className="text-sm text-gray-500 flex-shrink-0">3:24</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Floating Elements */}
            <div className="absolute -top-4 -right-4 w-24 h-24 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-2xl flex items-center justify-center text-4xl shadow-lg animate-bounce-slow">
              AI
            </div>
            <div className="absolute -bottom-4 -left-4 bg-white rounded-xl shadow-lg p-4 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center text-green-600">
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900">Music Generated!</p>
                <p className="text-xs text-gray-500">Saved to outputs folder</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
