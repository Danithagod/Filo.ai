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
    }
  }, [show]);

  return (
    <div className="about-page" style={{ opacity: show ? 1 : 0 }}>
      <section className="about-hero">
        <div className="container">
          <h1 className="hero-title">Our <span className="text-gradient">Mission</span></h1>
          <p className="hero-subtitle">Bringing the power of Large Language Models to your local machine, without compromising privacy.</p>
        </div>
      </section>

      <section className="about-content-section container">
        <div className="about-glass glass-card">
          <div className="about-text">
            <h2>The Privacy Gap</h2>
            <p>In the age of cloud-based AI, we believe your personal data should remain yours. Semantic Butler was born from the need to organize, search, and orchestrate local files using modern AI, while keeping every byte on your hard drive.</p>
          </div>
          <div className="about-stats">
            <div className="stat-card glass-card">
              <ShieldCheck size={32} />
              <h4>100% Local</h4>
              <p>No data ever leaves your device.</p>
            </div>
            <div className="stat-card glass-card">
              <Globe size={32} />
              <h4>Open Source</h4>
              <p>Transparent and community-driven.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="about-content-section container">
        <div className="team-grid">
          <div className="team-header">
            <h2>Built for <span className="text-gradient">Developers</span></h2>
            <p>We're a small team of engineers dedicated to local-first software.</p>
          </div>
          <div className="about-features-grid">
            <div className="about-feature-item glass-card">
              <Users size={24} className="text-gradient-icon" />
              <h3>Community Driven</h3>
              <p>Over 50 contributors have helped shape the core rust engine.</p>
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
