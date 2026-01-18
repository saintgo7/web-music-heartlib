import { useState } from 'react';

interface FAQItem {
  question: string;
  answer: string;
  category: string;
}

const faqData: FAQItem[] = [
  // General
  {
    category: 'General',
    question: 'What is ABADA Music Studio?',
    answer: 'ABADA Music Studio is a free, open-source AI music generation platform. It uses the HeartMuLa AI model to generate music from text lyrics and style tags. The application runs completely offline on your computer.',
  },
  {
    category: 'General',
    question: 'Is ABADA Music Studio really free?',
    answer: 'Yes! ABADA Music Studio is 100% free and open source. There are no subscriptions, no ads, and no hidden costs. You can use it as much as you want.',
  },
  {
    category: 'General',
    question: 'What AI model does it use?',
    answer: 'ABADA Music Studio uses HeartMuLa, a 3 billion parameter AI model specifically trained for music generation. The model can generate vocals, instruments, and full songs from text descriptions.',
  },
  // Installation
  {
    category: 'Installation',
    question: 'What are the system requirements?',
    answer: 'Minimum: 8GB RAM, 15GB disk space, Windows 10/macOS 12/Ubuntu 20.04. Recommended: 16GB RAM, SSD storage, NVIDIA GPU (RTX 2060+) or Apple Silicon (M1+) for faster generation.',
  },
  {
    category: 'Installation',
    question: 'Why is the first run taking so long?',
    answer: 'On first run, ABADA Music Studio downloads AI models (~6GB) from HuggingFace servers. This is a one-time download that may take 15-30 minutes depending on your internet connection.',
  },
  {
    category: 'Installation',
    question: 'Windows shows a security warning. Is it safe?',
    answer: 'Yes, it\'s safe. Windows shows this warning for new applications that haven\'t been widely downloaded yet. Click "More info" then "Run anyway" to proceed. The installer is signed and verified.',
  },
  {
    category: 'Installation',
    question: 'How do I uninstall the application?',
    answer: 'Windows: Use "Add or Remove Programs" in Settings. macOS: Drag the app to Trash. Linux: Run the uninstall script or delete ~/.mulastudio folder.',
  },
  // Usage
  {
    category: 'Usage',
    question: 'How long does music generation take?',
    answer: 'With GPU acceleration (NVIDIA RTX 2060+ or Apple Silicon): 2-3 minutes. CPU-only mode: 8-15 minutes. Longer songs take more time.',
  },
  {
    category: 'Usage',
    question: 'What format should lyrics be in?',
    answer: 'Use structure tags like [Verse], [Chorus], [Bridge], [Outro] to organize your lyrics. Each section should be on separate lines. The AI uses these tags to structure the generated music.',
  },
  {
    category: 'Usage',
    question: 'What style tags can I use?',
    answer: 'You can use genre tags (pop, rock, jazz, classical), mood tags (happy, sad, energetic), instrument tags (piano, guitar, drums), and vocal tags (male, female, choir). Combine multiple tags for specific styles.',
  },
  {
    category: 'Usage',
    question: 'Where are generated files saved?',
    answer: 'Generated music is saved to ~/MuLaStudio_Outputs (Mac/Linux) or %USERPROFILE%\\MuLaStudio_Outputs (Windows) as MP3 files with timestamps.',
  },
  // Technical
  {
    category: 'Technical',
    question: 'Why is my GPU not being detected?',
    answer: 'Make sure you have the latest NVIDIA drivers installed (for NVIDIA GPUs). The installer should detect your GPU automatically. Check the console output for CUDA errors. Apple Silicon is detected automatically on macOS.',
  },
  {
    category: 'Technical',
    question: 'Can I run multiple generations at once?',
    answer: 'We recommend running one generation at a time to avoid memory issues. Each generation uses significant GPU/CPU and RAM resources.',
  },
  {
    category: 'Technical',
    question: 'Does it work offline?',
    answer: 'Yes! After the initial model download, ABADA Music Studio works completely offline. No internet connection is required for music generation.',
  },
  {
    category: 'Technical',
    question: 'How much disk space does it use?',
    answer: 'The application itself is small (~80MB installer), but AI models require about 6GB. Generated music files are typically 3-10MB each depending on length.',
  },
  // Licensing
  {
    category: 'Licensing',
    question: 'Can I use generated music commercially?',
    answer: 'The HeartMuLa model is licensed under CC BY-NC 4.0, which allows free use for non-commercial purposes. For commercial use, please contact us for licensing options.',
  },
  {
    category: 'Licensing',
    question: 'Do I own the music I create?',
    answer: 'You have rights to the music you create, but the underlying AI model has a non-commercial license. For personal projects, YouTube videos, and non-profit use, you\'re free to use the generated music.',
  },
  {
    category: 'Licensing',
    question: 'Can I modify and redistribute the software?',
    answer: 'Yes! ABADA Music Studio is open source. You can view, modify, and redistribute the code under the same CC BY-NC 4.0 license. Contributions are welcome on GitHub.',
  },
];

const categories = ['All', ...new Set(faqData.map(item => item.category))];

export default function FAQPage() {
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [openIndex, setOpenIndex] = useState<number | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  const filteredFAQ = faqData.filter(item => {
    const matchesCategory = selectedCategory === 'All' || item.category === selectedCategory;
    const matchesSearch = searchQuery === '' ||
      item.question.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.answer.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  return (
    <main className="pt-20 min-h-screen bg-gradient-to-b from-gray-50 to-white">
      <div className="container py-16">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Frequently Asked <span className="gradient-text">Questions</span>
          </h1>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Find answers to common questions about ABADA Music Studio.
          </p>
        </div>

        {/* Search */}
        <div className="max-w-2xl mx-auto mb-8">
          <div className="relative">
            <input
              type="text"
              placeholder="Search questions..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full px-6 py-4 rounded-xl border border-gray-200 focus:border-abada-primary focus:ring-2 focus:ring-abada-primary/20 outline-none transition-all text-gray-900 placeholder-gray-400"
            />
            <svg
              className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>

        {/* Category Filter */}
        <div className="flex flex-wrap justify-center gap-2 mb-12">
          {categories.map((category) => (
            <button
              key={category}
              onClick={() => setSelectedCategory(category)}
              className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                selectedCategory === category
                  ? 'bg-abada-primary text-white shadow-lg'
                  : 'bg-white text-gray-600 hover:bg-abada-light hover:text-abada-primary border border-gray-200'
              }`}
            >
              {category}
            </button>
          ))}
        </div>

        {/* FAQ List */}
        <div className="max-w-3xl mx-auto">
          {filteredFAQ.length > 0 ? (
            <div className="space-y-4">
              {filteredFAQ.map((item, index) => (
                <div
                  key={index}
                  className="bg-white rounded-xl border border-gray-100 overflow-hidden"
                >
                  <button
                    onClick={() => setOpenIndex(openIndex === index ? null : index)}
                    className="w-full px-6 py-4 flex items-center justify-between text-left hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex items-start gap-4">
                      <span className="px-2 py-1 bg-abada-light text-abada-primary text-xs font-medium rounded">
                        {item.category}
                      </span>
                      <span className="font-medium text-gray-900">{item.question}</span>
                    </div>
                    <svg
                      className={`w-5 h-5 text-gray-400 flex-shrink-0 transition-transform ${
                        openIndex === index ? 'rotate-180' : ''
                      }`}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>
                  {openIndex === index && (
                    <div className="px-6 pb-4">
                      <div className="pl-16 border-l-2 border-abada-light ml-4">
                        <p className="text-gray-600 leading-relaxed">{item.answer}</p>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12">
              <div className="w-16 h-16 mx-auto rounded-full bg-gray-100 flex items-center justify-center mb-4">
                <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No questions found</h3>
              <p className="text-gray-600">
                Try adjusting your search or category filter.
              </p>
            </div>
          )}
        </div>

        {/* Contact Section */}
        <div className="max-w-3xl mx-auto mt-16 text-center">
          <div className="bg-gradient-to-r from-abada-primary/10 to-abada-secondary/10 rounded-3xl p-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              Still Have Questions?
            </h2>
            <p className="text-gray-600 mb-6">
              Can't find what you're looking for? We're here to help.
            </p>
            <div className="flex flex-wrap justify-center gap-4">
              <a
                href="https://github.com/saintgo7/web-music-heartlib/discussions"
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-primary"
              >
                Ask in Community
              </a>
              <a
                href="mailto:contact@abada.kr"
                className="btn btn-secondary"
              >
                Contact Support
              </a>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
