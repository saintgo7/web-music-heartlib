export default function AboutPage() {
  return (
    <main className="pt-20 min-h-screen bg-gradient-to-b from-gray-50 to-white">
      <div className="container py-16">
        {/* Header */}
        <div className="text-center mb-16">
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            About <span className="gradient-text">ABADA</span>
          </h1>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Making Open Source AI accessible to everyone.
          </p>
        </div>

        {/* Mission Section */}
        <div className="max-w-4xl mx-auto mb-16">
          <div className="bg-white rounded-3xl p-8 md:p-12 shadow-xl border border-gray-100">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-16 h-16 rounded-2xl gradient-bg flex items-center justify-center">
                <svg className="w-8 h-8 text-white" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/>
                </svg>
              </div>
              <div>
                <h2 className="text-2xl font-bold text-gray-900">ABADA Inc.</h2>
                <p className="text-gray-600">AI Technology Leader</p>
              </div>
            </div>

            <p className="text-lg text-gray-700 leading-relaxed mb-6">
              ABADA is dedicated to making Open Source AI accessible to everyone.
              We believe that AI technology should be free, easy to use, and run locally
              on your own computer for privacy and convenience.
            </p>

            <p className="text-gray-600 leading-relaxed">
              Our mission is to bridge the gap between complex AI research and everyday users.
              With ABADA Music Studio, anyone can create professional-quality AI-generated music
              without technical knowledge, subscriptions, or cloud dependencies.
            </p>
          </div>
        </div>

        {/* Projects Section */}
        <div className="max-w-4xl mx-auto mb-16">
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-8">
            Our Projects
          </h2>

          <div className="grid md:grid-cols-2 gap-6">
            {/* ABADA Music Studio */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-lg transition-all">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-abada-primary to-abada-secondary flex items-center justify-center mb-4">
                <svg className="w-8 h-8 text-white" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/>
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">ABADA Music Studio</h3>
              <p className="text-gray-600 mb-4">
                AI music generation platform. Create music from text with just one click.
                Free, open source, and runs offline.
              </p>
              <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-green-100 text-green-700 text-sm font-medium">
                <span className="w-2 h-2 rounded-full bg-green-500"></span>
                Live
              </span>
            </div>

            {/* Pamout */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:shadow-lg transition-all">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-pink-500 to-rose-500 flex items-center justify-center mb-4">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">Pamout</h3>
              <p className="text-gray-600 mb-4">
                AI image generation service. Create stunning visuals from text descriptions.
                Web-based and easy to use.
              </p>
              <a
                href="https://pamout.co.kr"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-green-100 text-green-700 text-sm font-medium hover:bg-green-200 transition-colors"
              >
                <span className="w-2 h-2 rounded-full bg-green-500"></span>
                Visit pamout.co.kr
              </a>
            </div>

            {/* ABADA Vision */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 opacity-75">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-cyan-500 to-blue-500 flex items-center justify-center mb-4">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">ABADA Vision</h3>
              <p className="text-gray-600 mb-4">
                AI-powered image analysis and understanding.
                Extract insights from visual content.
              </p>
              <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-gray-100 text-gray-600 text-sm font-medium">
                Coming Soon
              </span>
            </div>

            {/* ABADA Voice */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 opacity-75">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-orange-500 to-amber-500 flex items-center justify-center mb-4">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">ABADA Voice</h3>
              <p className="text-gray-600 mb-4">
                AI voice generation and text-to-speech.
                Create natural-sounding voices.
              </p>
              <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-gray-100 text-gray-600 text-sm font-medium">
                Coming Soon
              </span>
            </div>
          </div>
        </div>

        {/* Values Section */}
        <div className="max-w-4xl mx-auto mb-16">
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-8">
            Our Values
          </h2>

          <div className="grid md:grid-cols-3 gap-6">
            {[
              {
                icon: (
                  <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                ),
                title: 'Privacy First',
                description: 'Your data stays on your computer. No cloud processing, no tracking, no data collection.',
              },
              {
                icon: (
                  <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                  </svg>
                ),
                title: 'Open Source',
                description: 'All our code is open source. Transparency, community contributions, and trust.',
              },
              {
                icon: (
                  <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                ),
                title: 'Free Forever',
                description: 'No subscriptions, no premium tiers, no hidden costs. AI should be accessible to everyone.',
              },
            ].map((value, index) => (
              <div
                key={index}
                className="text-center p-6 bg-white rounded-2xl shadow-sm border border-gray-100"
              >
                <div className="w-16 h-16 mx-auto rounded-2xl bg-abada-light text-abada-primary flex items-center justify-center mb-4">
                  {value.icon}
                </div>
                <h3 className="text-lg font-bold text-gray-900 mb-2">{value.title}</h3>
                <p className="text-gray-600 text-sm">{value.description}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Technology Section */}
        <div className="max-w-4xl mx-auto mb-16">
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-8">
            Powered By
          </h2>

          <div className="bg-white rounded-2xl p-8 shadow-sm border border-gray-100">
            <div className="grid md:grid-cols-2 gap-8">
              <div>
                <h3 className="text-lg font-bold text-gray-900 mb-2">HeartMuLa</h3>
                <p className="text-gray-600 text-sm mb-4">
                  Open source AI music generation model with 3 billion parameters.
                  Capable of generating full songs with vocals from text descriptions.
                </p>
                <a
                  href="https://github.com/HeartMuLa/heartlib"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-abada-primary hover:underline text-sm"
                >
                  View on GitHub
                </a>
              </div>
              <div>
                <h3 className="text-lg font-bold text-gray-900 mb-2">Gradio</h3>
                <p className="text-gray-600 text-sm mb-4">
                  Beautiful and intuitive web interface for AI applications.
                  Makes complex AI models accessible through simple web UIs.
                </p>
                <a
                  href="https://gradio.app"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-abada-primary hover:underline text-sm"
                >
                  Learn more
                </a>
              </div>
            </div>
          </div>
        </div>

        {/* Contact Section */}
        <div className="max-w-4xl mx-auto text-center">
          <div className="bg-gradient-to-r from-abada-primary to-abada-secondary rounded-3xl p-8 md:p-12">
            <h2 className="text-2xl md:text-3xl font-bold text-white mb-4">
              Get in Touch
            </h2>
            <p className="text-white/80 mb-8 max-w-xl mx-auto">
              Have questions, suggestions, or want to collaborate?
              We'd love to hear from you.
            </p>
            <div className="flex flex-wrap justify-center gap-4">
              <a
                href="mailto:contact@abada.kr"
                className="btn bg-white text-abada-primary hover:bg-gray-100"
              >
                <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                contact@abada.kr
              </a>
              <a
                href="https://github.com/saintgo7"
                target="_blank"
                rel="noopener noreferrer"
                className="btn bg-white/10 text-white hover:bg-white/20 border border-white/30"
              >
                <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24">
                  <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.17 6.839 9.49.5.092.682-.217.682-.482 0-.237-.008-.866-.013-1.7-2.782.604-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.464-1.11-1.464-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.336-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.269 2.75 1.025A9.578 9.578 0 0112 6.836c.85.004 1.705.114 2.504.336 1.909-1.294 2.747-1.025 2.747-1.025.546 1.377.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.578.688.48C19.138 20.167 22 16.42 22 12c0-5.523-4.477-10-10-10z"/>
                </svg>
                GitHub
              </a>
              <a
                href="https://abada.kr"
                target="_blank"
                rel="noopener noreferrer"
                className="btn bg-white/10 text-white hover:bg-white/20 border border-white/30"
              >
                <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
                </svg>
                abada.kr
              </a>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
