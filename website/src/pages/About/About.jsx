import React, { useEffect } from 'react';
import { gsap } from 'gsap';
import { Users, Zap, Search, Lock } from 'lucide-react';
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
          <p className="hero-subtitle">Redefining desktop productivity through AI-powered semantic search, local-first architecture, and intelligent file discovery.</p>
        </div>
      </section>

      <section className="about-content-section container">
        <div className="about-glass glass-card">
          <div className="about-text">
            <h2>Privacy by Design</h2>
            <p>We believe your digital workspace should be your own. Filo takes a local-first approach to file search. Your file index and document metadata stay on your machine, while only your search queries are sent to AI models for processing.</p>
          </div>
          <div className="about-stats">
            <div className="stat-card glass-card">
              <Lock size={32} />
              <h4>Local-First</h4>
              <p>Your file index stays on your machine.</p>
            </div>
            <div className="stat-card glass-card">
              <Zap size={32} />
              <h4>High Performance</h4>
              <p>Optimized for rapid desktop search.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="about-content-section container">
        <div className="team-grid">
          <div className="team-header">
            <h2>Built for <span className="text-gradient">Efficiency</span></h2>
            <p>We&apos;re dedicated to building tools that help you find what you need instantly while respecting your privacy.</p>
          </div>
          <div className="about-features-grid">
            <div className="about-feature-item glass-card">
              <Search size={24} className="text-gradient-icon" />
              <h3>Semantic Discovery</h3>
              <p>Find files by meaning and context, not just exact keywords.</p>
            </div>
            <div className="about-feature-item glass-card">
              <Users size={24} className="text-gradient-icon" />
              <h3>User Centric</h3>
              <p>Designed to fit naturally into your desktop workflow.</p>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default About;
