import { useState } from 'react';

interface Sample {
  id: number;
  title: string;
  lyrics: string;
  tags: string[];
  audioUrl: string;
  createdAt: string;
  createdBy: string;
  duration: string;
}

// Mock data - in production, this would come from an API
const sampleData: Sample[] = [
  {
    id: 1,
    title: 'Morning Light',
    lyrics: '[Verse]\nThe morning light comes through the window\nA brand new day is here\n[Chorus]\nThis is my moment to shine bright\nNothing can stop me now',
    tags: ['pop', 'happy', 'morning'],
    audioUrl: '/samples/sample-1.mp3',
    createdAt: '2026-01-16',
    createdBy: 'User123',
    duration: '3:24',
  },
  {
    id: 2,
    title: 'Midnight Dream',
    lyrics: '[Verse]\nWhen the night falls silent\nStars begin to gleam\n[Bridge]\nDreams are calling me\nInto the unknown',
    tags: ['ambient', 'relaxing', 'night'],
    audioUrl: '/samples/sample-2.mp3',
    createdAt: '2026-01-17',
    createdBy: 'User456',
    duration: '4:12',
  },
  {
    id: 3,
    title: 'City Lights',
    lyrics: '[Verse]\nNeon signs flashing bright\nIn the heart of the city tonight\n[Chorus]\nWe are alive in this moment',
    tags: ['electronic', 'urban', 'energetic'],
    audioUrl: '/samples/sample-3.mp3',
    createdAt: '2026-01-18',
    createdBy: 'User789',
    duration: '3:48',
  },
  {
    id: 4,
    title: 'Ocean Waves',
    lyrics: '[Verse]\nWaves crashing on the shore\nPeaceful sounds forevermore\n[Chorus]\nLet the ocean set you free',
    tags: ['ambient', 'nature', 'calm'],
    audioUrl: '/samples/sample-4.mp3',
    createdAt: '2026-01-18',
    createdBy: 'User101',
    duration: '5:02',
  },
  {
    id: 5,
    title: 'Summer Vibes',
    lyrics: '[Verse]\nSunshine on my face today\nFeeling good in every way\n[Chorus]\nSummer never ends',
    tags: ['pop', 'summer', 'upbeat'],
    audioUrl: '/samples/sample-5.mp3',
    createdAt: '2026-01-15',
    createdBy: 'MusicLover',
    duration: '3:15',
  },
  {
    id: 6,
    title: 'Rainy Day Jazz',
    lyrics: '[Verse]\nRaindrops on my window pane\nA gentle rhythm, sweet refrain\n[Bridge]\nJazzy notes fill the air',
    tags: ['jazz', 'rainy', 'mellow'],
    audioUrl: '/samples/sample-6.mp3',
    createdAt: '2026-01-14',
    createdBy: 'JazzCat',
    duration: '4:45',
  },
  {
    id: 7,
    title: 'Epic Adventure',
    lyrics: '[Intro]\nThe journey begins now\n[Verse]\nThrough mountains and valleys we go\nBrave hearts never say no',
    tags: ['cinematic', 'epic', 'adventure'],
    audioUrl: '/samples/sample-7.mp3',
    createdAt: '2026-01-13',
    createdBy: 'FilmFan',
    duration: '5:30',
  },
  {
    id: 8,
    title: 'Love Song',
    lyrics: '[Verse]\nYour smile lights up my world\nEvery moment with you is gold\n[Chorus]\nI love you more each day',
    tags: ['ballad', 'romantic', 'emotional'],
    audioUrl: '/samples/sample-8.mp3',
    createdAt: '2026-01-12',
    createdBy: 'RomanticSoul',
    duration: '4:08',
  },
];

const allTags = ['all', ...new Set(sampleData.flatMap(s => s.tags))];

export default function GalleryPage() {
  const [selectedTag, setSelectedTag] = useState<string>('all');
  const [playingId, setPlayingId] = useState<number | null>(null);

  const filteredSamples = selectedTag === 'all'
    ? sampleData
    : sampleData.filter(s => s.tags.includes(selectedTag));

  const handlePlay = (id: number) => {
    setPlayingId(playingId === id ? null : id);
  };

  return (
    <main className="pt-20 min-h-screen bg-gradient-to-b from-gray-50 to-white">
      <div className="container py-16">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Community <span className="gradient-text">Gallery</span>
          </h1>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Explore music created by the ABADA Music Studio community.
            Every track was generated using AI from simple text prompts.
          </p>
        </div>

        {/* Filter Tags */}
        <div className="flex flex-wrap justify-center gap-2 mb-12">
          {allTags.map((tag) => (
            <button
              key={tag}
              onClick={() => setSelectedTag(tag)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                selectedTag === tag
                  ? 'bg-abada-primary text-white shadow-lg'
                  : 'bg-white text-gray-600 hover:bg-abada-light hover:text-abada-primary border border-gray-200'
              }`}
            >
              {tag.charAt(0).toUpperCase() + tag.slice(1)}
            </button>
          ))}
        </div>

        {/* Gallery Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredSamples.map((sample) => (
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
              <div className="bg-gray-50 rounded-xl p-4 mb-4 min-h-[100px]">
                <p className="text-sm text-gray-600 whitespace-pre-line line-clamp-4">
                  {sample.lyrics}
                </p>
              </div>

              {/* Tags */}
              <div className="flex flex-wrap gap-2 mb-4">
                {sample.tags.map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1 bg-abada-light text-abada-primary text-xs font-medium rounded-full cursor-pointer hover:bg-abada-primary hover:text-white transition-colors"
                    onClick={() => setSelectedTag(tag)}
                  >
                    {tag}
                  </span>
                ))}
              </div>

              {/* Audio Player */}
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
                  {[...Array(25)].map((_, i) => (
                    <div
                      key={i}
                      className={`flex-1 rounded-full transition-all duration-150 ${
                        playingId === sample.id ? 'bg-abada-primary animate-pulse' : 'bg-abada-primary/30'
                      }`}
                      style={{
                        height: `${Math.random() * 70 + 30}%`,
                      }}
                    ></div>
                  ))}
                </div>

                <span className="text-sm text-gray-500 flex-shrink-0">
                  {sample.duration}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Empty State */}
        {filteredSamples.length === 0 && (
          <div className="text-center py-16">
            <div className="w-20 h-20 mx-auto rounded-full bg-gray-100 flex items-center justify-center mb-4">
              <svg className="w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">No samples found</h3>
            <p className="text-gray-600 mb-4">No music with the "{selectedTag}" tag yet.</p>
            <button
              onClick={() => setSelectedTag('all')}
              className="btn btn-secondary"
            >
              View All Samples
            </button>
          </div>
        )}

        {/* CTA */}
        <div className="mt-16 text-center bg-gradient-to-r from-abada-primary to-abada-secondary rounded-3xl p-8 md:p-12">
          <h2 className="text-2xl md:text-3xl font-bold text-white mb-4">
            Create Your Own Music
          </h2>
          <p className="text-white/80 mb-6 max-w-xl mx-auto">
            Download ABADA Music Studio and start generating AI music today.
            Share your creations with the community!
          </p>
          <a href="/download" className="btn bg-white text-abada-primary hover:bg-gray-100">
            Download Now
          </a>
        </div>
      </div>
    </main>
  );
}
