import React, { useEffect } from 'react';
import { gsap } from 'gsap';
import { Monitor, Apple, Terminal } from 'lucide-react';
import Logo from '../../components/Logo/Logo';
import './Download.css';

const Download = ({ show }) => {
  useEffect(() => {
    if (show) {
      const tl = gsap.timeline({ defaults: { ease: 'power3.out', duration: 1 } });

      tl.fromTo('.download-hero h1',
        { opacity: 0, y: 30 },
        { opacity: 1, y: 0 }
      )
        .fromTo('.download-hero p',
          { opacity: 0, y: 20 },
          { opacity: 1, y: 0, delay: -0.6 }
        )
        .fromTo('.download-section',
          { opacity: 0, y: 40 },
          { opacity: 1, y: 0, stagger: 0.2, delay: -0.4 }
        );

      return () => {
        tl.kill();
      };
    }
  }, [show]);

  const platforms = [
    {
      id: 'windows',
      name: 'Windows',
      icon: <Monitor size={48} />,
      desc: 'Native performance for Windows 10 & 11. Optimized for modern multi-core CPUs.',
      version: 'v1.0.4-stable'
    },
    {
      id: 'macos',
      name: 'macOS',
      icon: <Apple size={48} />,
      desc: 'Universal binary with native support for Apple Silicon (M1/M2/M3) and Intel.',
      version: 'v1.0.4-stable'
    },
    {
      id: 'linux',
      name: 'Linux',
      icon: <Terminal size={48} />,
      desc: 'Distributed via AppImage and Snap. Built for speed and flexibility.',
      version: 'v1.0.4-beta'
    }
  ];

  return (
    <div className={`download-page page-content${show ? ' visible' : ''}`}>
      <section className="download-hero">
        <div className="container">
          <h1 className="hero-title">
            <span className="get-text">Get</span>
            <div className="logo-title-wrapper">
              <Logo size={280} className="hero-logo-svg" />
            </div>
          </h1>
          <p className="hero-subtitle">Choose your platform and start searching your local data with AI-powered intelligence.</p>
        </div>
      </section>

      <div className="container">
        <div className="download-grid">
          {platforms.map((platform) => (
            <div key={platform.id} className="download-section glass-card">
              <div className="platform-header">
                <div className="platform-icon">{platform.icon}</div>
                <h2>{platform.name}</h2>
                <span className="version-badge">{platform.version}</span>
              </div>

              <p className="platform-desc">{platform.desc}</p>

              <div className="platform-actions">
                <button className="btn-primary-large">
                  Download for {platform.name}
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Download;