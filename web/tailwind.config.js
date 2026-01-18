/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // ABADA brand colors
        'abada': {
          'primary': '#6366f1',      // Indigo
          'secondary': '#8b5cf6',    // Purple
          'accent': '#f43f5e',       // Rose
          'dark': '#1e1b4b',         // Dark indigo
          'light': '#e0e7ff',        // Light indigo
        }
      },
      fontFamily: {
        'sans': ['Pretendard', 'Inter', 'system-ui', '-apple-system', 'sans-serif'],
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.5s ease-out',
        'bounce-slow': 'bounce 3s infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
  plugins: [],
}
