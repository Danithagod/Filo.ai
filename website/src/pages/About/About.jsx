import React, { useEffect } from 'react';
import { gsap } from 'gsap';
import { Users, Heart, ShieldCheck, Globe } from 'lucide-react';
import './About.css';

const About = ({ show }) => {
  useEffect(() => {
    if (show) {
      const tl = gsap.timeline({ defaults: { ease: 'power3.out', duration: 1 } });

      tl.fromTo('.about-hero .hero-title',
        { opacity: 0, y: 30 },
        { opacity: 1, y: 0, duration: 1 }
      )
        .fromTo('.about-hero .hero-subtitle',
          { opacity: 0, y: 20 },
          { opacity: 1, y: 0, duration: 1, delay: -0.6 }
        )
        .fromTo('.about-content-section',
          { opacity: 0, y: 40 },
          { opacity: 1, y: 0, stagger: 0.3, duration: 1, delay: -0.4 }
        );

      return () => {
        tl.kill();
      };
    }
  }, [show]);

  return (
    <div className={`about-page page-content${show ? ' visible' : ''}`}>
      <section className="about-hero">
        <div className="container">
          <h1 className="hero-title">Our <span className="text-gradient">Mission</span></h1>
          <p className="hero-subtitle">Empowering users with intelligent desktop assistance through local-first file management and modern AI integration.</p>
        </div>
      </section>

      <section className="about-content-section container">
        <div className="about-glass glass-card">
          <div className="about-text">
            <h2>The Desktop AI Gap</h2>
            <p>In an era dominated by cloud-based AI, we believe your personal data management should be local and secure. Semantic Butler was built to bridge the gap between powerful AI reasoning and local file organization, ensuring your document structure remains private while leveraging the best available language models.</p>
          </div>
          <div className="about-stats">
            <div className="stat-card glass-card">
              <ShieldCheck size={32} />
              <h4>Local-First</h4>
              <p>File extraction and indexing happens on your device.</p>
            </div>
            <div className="stat-card glass-card">
              <Globe size={32} />
              <h4>Multi-Model</h4>
              <p>Choose the best AI for the job via OpenRouter.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="about-content-section container">
        <div className="team-grid">
          <div className="team-header">
            <h2>Built for <span className="text-gradient">Efficiency</span></h2>
            <p>We're dedicated to building tools that respect user privacy and system performance.</p>
          </div>
          <div className="about-features-grid">
            <div className="about-feature-item glass-card">
              <Users size={24} className="text-gradient-icon" />
              <h3>User Centric</h3>
              <p>Designed to fit naturally into existing desktop workflows.</p>
            </div>
            <div className="about-feature-item glass-card">
              <Heart size={24} className="text-gradient-icon" />
              <h3>Passion for UX</h3>
              <p>We believe utility shouldn't come at the cost of a beautiful experience.</p>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default About;
