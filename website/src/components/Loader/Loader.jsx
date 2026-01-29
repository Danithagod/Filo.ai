import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import Logo from '../Logo/Logo';
import './Loader.css';

const Loader = ({ onFinished }) => {
  const loaderRef = useRef(null);
  const progressRef = useRef(null);

  useEffect(() => {
    const tl = gsap.timeline({
      onComplete: () => {
        if (onFinished) onFinished();
      }
    });

    tl.to(progressRef.current, {
      width: '100%',
      duration: 1.5,
      ease: 'power2.inOut'
    })
      .to(loaderRef.current, {
        opacity: 0,
        duration: 0.5,
        ease: 'power2.out'
      });
  }, [onFinished]);

  return (
    <div className="loader-wrapper" ref={loaderRef} role="status" aria-label="Loading Filo" aria-live="polite">
      <div className="loader-content">
        <Logo size={120} className="loader-icon pulse" aria-hidden="true" />
        <div className="progress-container" aria-label="Loading progress">
          <div className="progress-bar" ref={progressRef} role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>
        </div>
      </div>
    </div>
  );
};

export default Loader;
