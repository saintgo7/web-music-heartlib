import { useState } from 'react';
import { Link } from 'react-router-dom';

interface Sample {
  id: number;
  title: string;
  lyrics: string;
  tags: string[];
  audioUrl: string;
  createdAt: string;
  createdBy: string;
}

// Mock data - in production, this would come from an API
const sampleData: Sample[] = [
  {
    id: 1,
    title: 'Morning Light',
    lyrics: '[Verse]\nThe morning light comes through the window\nA brand new day is here\n[Chorus]\nThis is my moment...',
    tags: ['pop', 'happy', 'morning'],
    audioUrl: '/samples/sample-1.mp3',
    createdAt: '2026-01-16',
    createdBy: 'User123',
  },
  {
    id: 2,
    title: 'Midnight Dream',
    lyrics: '[Verse]\nWhen the night falls silent\n[Bridge]\nDreams are calling me...',
    tags: ['ambient', 'relaxing', 'night'],
    audioUrl: '/samples/sample-2.mp3',
    createdAt: '2026-01-17',
    createdBy: 'User456',
  },
  {
    id: 3,
    title: 'City Lights',
    lyrics: '[Verse]\nNeon signs flashing bright\nIn the heart of the city tonight...',
    tags: ['electronic', 'urban', 'energetic'],
    audioUrl: '/samples/sample-3.mp3',
    createdAt: '2026-01-18',
    createdBy: 'User789',
  },
  {
    id: 4,
    title: 'Ocean Waves',
    lyrics: '[Verse]\nWaves crashing on the shore\nPeaceful sounds forevermore...',
    tags: ['ambient', 'nature', 'calm'],
    audioUrl: '/samples/sample-4.mp3',
    createdAt: '2026-01-18',
    createdBy: 'User101',
  },
];

export default function GalleryPreview() {
  const [playingId, setPlayingId] = useState<number | null>(null);

  const handlePlay = (id: number) => {
    setPlayingId(playingId === id ? null : id);
  };

  return (
    <section className="section bg-gradient-to-b from-white to-gray-50" id="gallery-preview">
      <div className="container">
        {/* Section Header */}
        <div className="text-center mb-16">
          <span className="inline-block px-4 py-2 rounded-full bg-abada-light text-abada-primary text-sm font-medium mb-4">
            Community Gallery
          </span>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold text-gray-900 mb-4">
            Listen to <span className="gradient-text">AI-Generated Music</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Explore what others have created with ABADA Music Studio.
            Every track was generated using AI from simple text prompts.
          </p>
        </div>

        {/* Sample Grid */}
        <div className="grid md:grid-cols-2 gap-6 max-w-4xl mx-auto mb-12">
          {sampleData.map((sample) => (
            <div
              key={sample.id}
              className="bg-white rounded-2xl p-6 shadow-sm hover:shadow-lg transition-all duration-300 border border-gray-100"
            >
              {/* Header */}
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-lg font-bold text-gray-900">{sample.title}</h3>
                  <p className="text-sm text-gray-500">by {sample.createdBy}</p>
                </div>
                <span className="text-xs text-gray-400">{sample.createdAt}</span>
              </div>

              {/* Lyrics Preview */}
              <div className="bg-gray-50 rounded-xl p-4 mb-4">
                <p className="text-sm text-gray-600 whitespace-pre-line line-clamp-3">
                  {sample.lyrics}
                </p>
              </div>

              {/* Tags */}
              <div className="flex flex-wrap gap-2 mb-4">
                {sample.tags.map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1 bg-abada-light text-abada-primary text-xs font-medium rounded-full"
                  >
                    {tag}
                  </span>
                ))}
              </div>

              {/* Audio Player Mock */}
              <div className="flex items-center gap-4 p-4 bg-gradient-to-r from-abada-primary/5 to-abada-secondary/5 rounded-xl">
                <button
                  onClick={() => handlePlay(sample.id)}
                  className="w-12 h-12 rounded-full bg-abada-primary text-white flex items-center justify-center flex-shrink-0 hover:bg-abada-secondary transition-colors"
                  aria-label={playingId === sample.id ? 'Pause' : 'Play'}
                >
                  {playingId === sample.id ? (
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zM7 8a1 1 0 012 0v4a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v4a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                    </svg>
                  ) : (
                    <svg className="w-5 h-5 ml-0.5" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clipRule="evenodd" />
                    </svg>
                  )}
                </button>

                {/* Waveform */}
                <div className="flex-1 h-10 flex items-center gap-0.5">
                  {[...Array(40)].map((_, i) => (
                    <div
                      key={i}
                      className={`flex-1 rounded-full transition-all duration-150 ${
                        playingId === sample.id ? 'bg-abada-primary' : 'bg-abada-primary/30'
                      }`}
                      style={{
                        height: `${Math.random() * 70 + 30}%`,
                        animationDelay: `${i * 50}ms`,
                      }}
                    ></div>
                  ))}
                </div>

                <span className="text-sm text-gray-500 flex-shrink-0">
                  {Math.floor(Math.random() * 2) + 2}:{String(Math.floor(Math.random() * 60)).padStart(2, '0')}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* View All CTA */}
        <div className="text-center">
          <Link to="/gallery" className="btn btn-secondary">
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
            </svg>
            View Full Gallery
          </Link>
        </div>
      </div>
    </section>
  );
}
