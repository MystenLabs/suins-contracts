import React, { useState, useCallback } from 'react';

interface VideoProps {
  source?: 'youtube';
  videoId: string;
  title?: string;
  aspectRatio?: '16/9' | '4/3' | '1/1';
}

export default function Video({ 
  source = 'youtube', 
  videoId, 
  title = 'Video',
  aspectRatio = '16/9' 
}: VideoProps) {
  const [isLoaded, setIsLoaded] = useState(false);

  const handleClick = useCallback(() => {
    setIsLoaded(true);
  }, []);

  if (source !== 'youtube') {
    console.warn(`Video source "${source}" is not supported yet`);
    return null;
  }

  // Try different thumbnail qualities in order
  // Start with hqdefault as it's most reliable
  const [thumbnailErrorCount, setThumbnailErrorCount] = useState(0);
  
  const thumbnailQualities = [
    'hqdefault',     // 480x360 (almost always available)
    'mqdefault',     // 320x180 (always available)
    'sddefault',     // 640x480 (sometimes available)
    'maxresdefault', // 1280x720 (rarely available for older videos)
    '0'              // Fallback to frame 0 which always exists
  ];
  
  const quality = thumbnailQualities[Math.min(thumbnailErrorCount, thumbnailQualities.length - 1)];
  const thumbnailUrl = `https://img.youtube.com/vi/${videoId}/${quality}.jpg`;
  const embedUrl = `https://www.youtube.com/embed/${videoId}?autoplay=1`;

  return (
    <div className="w-1/2 mx-auto pb-8 pt-4">
      <div 
        className="relative w-full overflow-hidden rounded-lg bg-black" 
        style={{ aspectRatio }}
      >
      {!isLoaded ? (
        <button
          className="relative w-full h-full p-0 m-0 border-none bg-transparent cursor-pointer overflow-hidden group"
          onClick={handleClick}
          aria-label={`Play ${title}`}
        >
          <img
            src={thumbnailUrl}
            alt={`${title} thumbnail`}
            className="absolute inset-0 w-full h-full object-cover"
            loading="lazy"
            onError={() => setThumbnailErrorCount(prev => prev + 1)}
          />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[68px] h-[48px] opacity-80 transition-all duration-250 group-hover:opacity-90 group-hover:scale-110">
            <svg
              className="w-full h-full"
              viewBox="0 0 68 48"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M66.52 7.74c-.78-2.93-3.07-5.23-6-6.01C55.36 0.5 34 0.5 34 0.5s-21.36 0-26.52 1.23c-2.93.78-5.22 3.08-6 6.01C0.25 12.9 0.25 24 0.25 24s0 11.1 1.23 16.26c.78 2.93 3.07 5.22 6 6.01 5.16 1.23 26.52 1.23 26.52 1.23s21.36 0 26.52-1.23c2.93-.79 5.22-3.08 6-6.01C67.75 35.1 67.75 24 67.75 24s0-11.1-1.23-16.26z"
                fill="#FF0000"
              />
              <path
                d="M27 34.5V13.5L45 24z"
                fill="#FFFFFF"
              />
            </svg>
          </div>
        </button>
      ) : (
        <iframe
          src={embedUrl}
          title={title}
          className="absolute inset-0 w-full h-full border-0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
        />
      )}
      </div>
    </div>
  );
}