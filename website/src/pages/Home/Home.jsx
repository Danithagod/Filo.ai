import React, { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { Brain, Search, Tags, Cpu, Shield, Zap, ChevronRight, FileText, Database, Lock } from 'lucide-react';
import './Home.css';

gsap.registerPlugin(ScrollTrigger);

const Home = ({ show }) => {
  const heroRef = useRef(null);
  const visualRef = useRef(null);
  const sideLeftRef = useRef(null);
  const sideRightRef = useRef(null);
  const featuresSectionRef = useRef(null);
  const featuresTrackRef = useRef(null);
  const agentFlowRef = useRef(null);

  // Store animation references to ensure proper cleanup
  // This prevents race conditions when useEffect runs multiple times quickly
  const animationsRef = useRef({
    timeline: null,
    triggers: [],
    tickerAnimation: null
  });

  useEffect(() => {
    if (!show) return;

    // Clean up any existing animations before creating new ones
    // This handles the case where useEffect runs again before cleanup
    const animations = animationsRef.current;
    animations.triggers.forEach(trigger => trigger?.kill());
    animations.triggers = [];
    animations.timeline?.kill();
    animations.tickerAnimation?.kill();

    // Hero Animations
    const tl = gsap.timeline({ defaults: { ease: 'power4.out', duration: 1.2 } });
    animations.timeline = tl;

    tl.fromTo('.hero-badge',
      { y: 20, opacity: 0 },
      { y: 0, opacity: 1, duration: 0.8 }
    )
      .fromTo('.hero-title',
        { y: 60, opacity: 0 },
        { y: 0, opacity: 1, duration: 1.2, delay: -0.6 }
      )
      .fromTo('.hero-subtitle',
        { y: 40, opacity: 0 },
        { y: 0, opacity: 1, duration: 1.2, delay: -1 }
      )
      .fromTo('.hero-actions',
        { y: 30, opacity: 0 },
        { y: 0, opacity: 1, duration: 1.2, delay: -1 }
      )
      .fromTo(visualRef.current,
        { scale: 0.9, opacity: 0, y: 50 },
        { scale: 1, opacity: 1, y: 0, duration: 1.2, delay: -0.8 }
      );

    // Collapsing sides on scroll
    const leftTrigger = ScrollTrigger.create({
      trigger: 'body',
      start: 'top top',
      end: '500 top',
      scrub: true,
      animation: gsap.to(sideLeftRef.current, { xPercent: -100, opacity: 0 })
    });
    animations.triggers.push(leftTrigger);

    const rightTrigger = ScrollTrigger.create({
      trigger: 'body',
      start: 'top top',
      end: '500 top',
      scrub: true,
      animation: gsap.to(sideRightRef.current, { xPercent: 100, opacity: 0 })
    });
    animations.triggers.push(rightTrigger);

    // Horizontal scroll for features
    const featuresSection = featuresSectionRef.current;
    const featuresTrack = featuresTrackRef.current;

    if (featuresSection && featuresTrack) {
      const featureScrollTrigger = ScrollTrigger.create({
        trigger: featuresSection,
        start: 'top top',
        end: () => `+=${featuresTrack.scrollWidth}`,
        scrub: 1,
        pin: true,
        pinSpacing: true,
        invalidateOnRefresh: true,
        animation: gsap.to(featuresTrack, {
          x: () => -(featuresTrack.scrollWidth - window.innerWidth),
          ease: 'none'
        })
      });
      animations.triggers.push(featureScrollTrigger);

      // Feature items entrance (within horizontal scroll)
      const featureCardTrigger = ScrollTrigger.create({
        trigger: featuresSection,
        start: 'top top',
        end: () => `+=${featuresTrack.scrollWidth}`,
        scrub: 1,
        animation: gsap.fromTo('.feature-card',
          { opacity: 0.3, scale: 0.9 },
          { opacity: 1, scale: 1, stagger: 0.1 }
        )
      });
      animations.triggers.push(featureCardTrigger);
    }

    // Agent Flow Animations
    if (agentFlowRef.current) {
      const agentFlowTrigger = ScrollTrigger.create({
        trigger: agentFlowRef.current,
        start: 'top 80%',
        animation: gsap.fromTo('.flow-step',
          { y: 40, opacity: 0 },
          { y: 0, opacity: 1, stagger: 0.2, duration: 1, ease: 'power3.out' }
        )
      });
      animations.triggers.push(agentFlowTrigger);
    }

    // Trust ticker animation
    const tickerAnimation = gsap.to('.trust-track', {
      xPercent: -50,
      duration: 30,
      ease: 'none',
      repeat: -1
    });
    animations.tickerAnimation = tickerAnimation;

    return () => {
      // Use refs to ensure we're cleaning up the correct animations
      const currentAnimations = animationsRef.current;
      currentAnimations.triggers.forEach(trigger => trigger?.kill());
      currentAnimations.triggers = [];
      currentAnimations.timeline?.kill();
      currentAnimations.timeline = null;
      currentAnimations.tickerAnimation?.kill();
      currentAnimations.tickerAnimation = null;
    };

  }, [show]);

  const features = [
    {
      title: 'Concept Search',
      desc: 'Our neural index understands semantic intent, finding files based on meaning rather than just keywords.',
      icon: <Search size={32} />
    },
    {
      title: 'AI Orchestration',
      desc: 'The Butler handles file movements, renaming, and organization through natural language commands.',
      icon: <Cpu size={32} />
    },
    {
      title: 'Privacy Focused',
      desc: 'Built on Serverpod with a local vector database. Your file indexing and organization stays on your machine.',
      icon: <Shield size={32} />
    },
    {
      title: 'Multi-Model Support',
      desc: 'Access 200+ AI models including GPT-4, Claude, and Gemini via OpenRouter integration.',
      icon: <Database size={32} />
    },
    {
      title: 'Smart Cataloging',
      desc: 'AI automatically tags and categorizes every document, generating human-readable metadata instantly.',
      icon: <Tags size={32} />
    },
    {
      title: 'Usage Monitoring',
      desc: 'Detailed metrics for token usage and costs, with a comprehensive index health dashboard.',
      icon: <Zap size={32} />
    }
  ];

  return (
    <div className={`home-page page-content${show ? ' visible' : ''}`}>
      {/* Dynamic Collapsing Sides */}
      <div className="side-dynamic left" ref={sideLeftRef}>
        <div className="side-content">
          <FileText size={18} />
          <div className="side-line"></div>
          <span>DESKTOP</span>
        </div>
      </div>
      <div className="side-dynamic right" ref={sideRightRef}>
        <div className="side-content">
          <span>SECURE</span>
          <div className="side-line"></div>
          <Lock size={18} />
        </div>
      </div>

      <section className="hero" ref={heroRef}>
        <div className="container hero-content">
          <div className="hero-badge">
            <Zap size={14} />
            <span>Now with OpenRouter Integration</span>
          </div>
          <h1 className="hero-title">
            Your Intelligent <span className="text-gradient">Assistant</span> <br />
            for Local Files
          </h1>
          <p className="hero-subtitle">
            Organize, search, and manage your documents with the power of modern AI. 
            Deep semantic search, automated tagging, and natural language control.
          </p>
          <div className="hero-actions">
            <Link to="/pricing" className="btn-primary-large" aria-label="Get started with Semantic Butler for free">Download Now <ChevronRight size={20} /></Link>
            <a href="https://github.com" target="_blank" rel="noopener noreferrer" className="btn-secondary-large" aria-label="View Semantic Butler on GitHub">View GitHub</a>
          </div>
        </div>

        <div className="hero-visual-container" ref={visualRef}>
          <div className="hero-visual glass-card">
            <div className="visual-inner">
              <div className="scan-line"></div>
              <Database size={80} className="visual-icon pulse" />
              <div className="data-points">
                {[...Array(12)].map((_, i) => (
                  <div key={i} className={`point point-${i}`}></div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="trust-section">
        <div className="trust-ticker">
          <div className="trust-track">
            {[...Array(10)].map((_, i) => (
              <span key={i} className="trust-item">POWERED BY SERVERPOD • FLUTTER DESKTOP • AI-FIRST WORKFLOW • </span>
            ))}
          </div>
        </div>
      </section>

      <section className="features-section" id="features" ref={featuresSectionRef}>
        <div className="section-header container">
          <h2 className="section-title">Built for the <span className="text-gradient">Modern</span> Workflow</h2>
          <p>Powerful tools to help you find and use your data instantly.</p>
        </div>

        <div className="features-container">
          <div className="features-track" ref={featuresTrackRef}>
            {features.map((feature, i) => (
              <div key={i} className="feature-card glass-card">
                <div className="feature-icon-wrapper">
                  {feature.icon}
                </div>
                <h3>{feature.title}</h3>
                <p>{feature.desc}</p>
                <div className="feature-card-footer">
                  <span className="feature-number">0{i + 1}</span>
                  <div className="feature-line"></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="agent-flow-section" ref={agentFlowRef}>
        <div className="container">
          <div className="section-header">
            <h2 className="section-title">The <span className="text-gradient">Butler</span> Flow</h2>
            <p>From natural language intent to seamless file operations.</p>
          </div>

          <div className="flow-visual">
            <div className="flow-step glass-card">
              <div className="step-number">1</div>
              <div className="step-icon"><Brain size={32} /></div>
              <h3>Intent Analysis</h3>
              <p>The AI agent parses your request to understand the objective.</p>
            </div>
            <div className="flow-connector"></div>
            <div className="flow-step glass-card">
              <div className="step-number">2</div>
              <div className="step-icon"><Search size={32} /></div>
              <h3>Context Retrieval</h3>
              <p>Butler finds relevant files via semantic and local search.</p>
            </div>
            <div className="flow-connector"></div>
            <div className="flow-step glass-card highlight">
              <div className="step-number">3</div>
              <div className="step-icon"><Zap size={32} /></div>
              <h3>Smart Execution</h3>
              <p>Action is performed via the desktop file operations service.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="integration-section">
        <div className="container">
          <div className="integration-content glass-card">
            <div className="integration-text">
              <h2>Desktop Power</h2>
              <p>Semantic Butler integrates deeply with your operating system to provide a seamless management experience.</p>
              <ul className="integration-list">
                <li><ChevronRight size={16} /> Native Windows/macOS/Linux Support</li>
                <li><ChevronRight size={16} /> Real-time File System Monitoring</li>
                <li><ChevronRight size={16} /> Markdown & PDF Deep Parsing</li>
              </ul>
            </div>
            <div className="integration-code">
              <div className="integration-text">
                <h3>Rich AI Toolset</h3>
                <p>The agent has access to a variety of tools to help you manage your digital workspace:</p>
                <ul className="integration-list" style={{ marginTop: '1rem' }}>
                  <li><Search size={16} /> Semantic & Deep File Search</li>
                  <li><FileText size={16} /> Summarization & Metadata Extraction</li>
                  <li><Cpu size={16} /> Batch Rename, Move, and Organization</li>
                  <li><Database size={16} /> Index Health & Cost Analytics</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;
