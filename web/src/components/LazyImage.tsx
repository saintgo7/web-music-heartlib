import { useState, useRef, useEffect, type ImgHTMLAttributes } from 'react';

interface LazyImageProps extends Omit<ImgHTMLAttributes<HTMLImageElement>, 'onLoad' | 'onError'> {
  src: string;
  alt: string;
  placeholderSrc?: string;
  webpSrc?: string;
  threshold?: number;
  onLoad?: () => void;
  onError?: () => void;
}

/**
 * LazyImage component with:
 * - Native lazy loading with Intersection Observer fallback
 * - WebP support with fallback
 * - Placeholder/blur-up loading pattern
 * - Proper aspect ratio to prevent CLS
 */
export default function LazyImage({
  src,
  alt,
  placeholderSrc,
  webpSrc,
  threshold = 0.1,
  className = '',
  style,
  width,
  height,
  onLoad,
  onError,
  ...props
}: LazyImageProps) {
  const [isLoaded, setIsLoaded] = useState(false);
  const [isInView, setIsInView] = useState(false);
  const [hasError, setHasError] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);

  // Use Intersection Observer for browsers that need it
  useEffect(() => {
    const img = imgRef.current;
    if (!img) return;

    // Check if native lazy loading is supported - set initial state
    const supportsNativeLazy = 'loading' in HTMLImageElement.prototype;

    if (supportsNativeLazy) {
      // Use requestAnimationFrame to avoid synchronous state update in effect
      const frameId = requestAnimationFrame(() => {
        setIsInView(true);
      });
      return () => cancelAnimationFrame(frameId);
    }

    // Fallback to Intersection Observer
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsInView(true);
          observer.disconnect();
        }
      },
      { threshold, rootMargin: '50px' }
    );

    observer.observe(img);

    return () => observer.disconnect();
  }, [threshold]);

  const handleLoad = () => {
    setIsLoaded(true);
    onLoad?.();
  };

  const handleError = () => {
    setHasError(true);
    onError?.();
  };

  // Calculate aspect ratio for placeholder
  const aspectRatio = width && height ? Number(height) / Number(width) : undefined;

  return (
    <div
      className={`relative overflow-hidden ${className}`}
      style={{
        ...style,
        aspectRatio: aspectRatio ? `${Number(width)} / ${Number(height)}` : undefined,
      }}
    >
      {/* Placeholder */}
      {!isLoaded && placeholderSrc && (
        <img
          src={placeholderSrc}
          alt=""
          aria-hidden="true"
          className="absolute inset-0 w-full h-full object-cover blur-lg scale-110"
          style={{ filter: 'blur(20px)', transform: 'scale(1.1)' }}
        />
      )}

      {/* Main image with WebP support */}
      {isInView && !hasError && (
        <picture>
          {webpSrc && <source srcSet={webpSrc} type="image/webp" />}
          <img
            ref={imgRef}
            src={src}
            alt={alt}
            width={width}
            height={height}
            loading="lazy"
            decoding="async"
            onLoad={handleLoad}
            onError={handleError}
            className={`w-full h-full object-cover transition-opacity duration-300 ${
              isLoaded ? 'opacity-100' : 'opacity-0'
            }`}
            {...props}
          />
        </picture>
      )}

      {/* Error fallback */}
      {hasError && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-100 text-gray-400">
          <svg
            className="w-12 h-12"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
            />
          </svg>
        </div>
      )}
    </div>
  );
}
