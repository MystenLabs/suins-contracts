import React, { useState, useEffect } from 'react'
import ReactPlayer from 'react-player/lazy'

const Player = ({ videoId }) => {
  const [hasWindow, setHasWindow] = useState(false);
  const [duration, setDuration] = useState();
  const videoUrl = `https://youtu.be/${videoId}`;

  const handleDuration = (time) => {
    setDuration(time);
  }

  useEffect(() => {
    if (typeof window !== "undefined") {
      setHasWindow(true);
    }
  }, []);

  return (
    <div>    
    <p className="py-4">Watch this quick {duration && <span>{Math.floor(duration)} second</span>} clip to see how.</p>
    <div className='relative pt-[56.25%]'>
      {hasWindow && <ReactPlayer
        className='absolute top-0 left-0'
        url={videoUrl}
        controls={true}
        width='100%'
        height='100%'
        onDuration={handleDuration}
      />}
    </div>
    </div>
  )
}

  export default Player;