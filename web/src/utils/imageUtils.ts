/**
 * Responsive image srcset generator
 * Usage: generateSrcSet('/images/hero', [320, 640, 1024, 1920], 'jpg')
 */
export function generateSrcSet(
  basePath: string,
  widths: number[],
  extension: string = 'jpg'
): string {
  return widths
    .map((w) => `${basePath}-${w}w.${extension} ${w}w`)
    .join(', ');
}

/**
 * Get appropriate image size based on viewport
 */
export function getImageSizes(
  breakpoints: Record<string, string> = {
    sm: '100vw',
    md: '50vw',
    lg: '33vw',
  }
): string {
  const entries = Object.entries(breakpoints);
  const sizes = entries.map(([bp, size], index) => {
    const breakpointValues: Record<string, number> = {
      sm: 640,
      md: 768,
      lg: 1024,
      xl: 1280,
      '2xl': 1536,
    };

    const minWidth = breakpointValues[bp];
    if (index === entries.length - 1) {
      return size;
    }
    return minWidth ? `(min-width: ${minWidth}px) ${size}` : size;
  });

  return sizes.join(', ');
}
