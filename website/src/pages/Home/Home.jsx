import React, { useEffect, useRef } from 'react';
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

  useEffect(() => {
    if (!show) return;

    // Hero Animations
    const tl = gsap.timeline({ defaults: { ease: 'power4.out', duration: 1.2 } });

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
    gsap.to(sideLeftRef.current, {
      scrollTrigger: {
        trigger: 'body',
        start: 'top top',
        end: '500 top',
        scrub: true
      },
      xPercent: -100,
      opacity: 0
    });

    gsap.to(sideRightRef.current, {
      scrollTrigger: {
        trigger: 'body',
        start: 'top top',
        end: '500 top',
        scrub: true
      },
      xPercent: 100,
      opacity: 0
    });

    // Horizontal scroll for features
    const featuresSection = featuresSectionRef.current;
    const featuresTrack = featuresTrackRef.current;

    if (featuresSection && featuresTrack) {
      gsap.to(featuresTrack, {
        x: () => -(featuresTrack.scrollWidth - window.innerWidth),
        ease: 'none',
        scrollTrigger: {
          trigger: featuresSection,
          start: 'top top',
          end: () => `+=${featuresTrack.scrollWidth}`,
          scrub: 1,
          pin: true,
          pinSpacing: true,
          invalidateOnRefresh: true,
        }
      });

      // Feature items entrance (within horizontal scroll)
      gsap.fromTo('.feature-card',
        { opacity: 0.3, scale: 0.9 },
        {
          scrollTrigger: {
            trigger: featuresSection,
            start: 'top top',
            end: () => `+=${featuresTrack.scrollWidth}`,
            scrub: 1,
          },
          opacity: 1,
          scale: 1,
          stagger: 0.1,
        }
      );
    }

    // Agent Flow Animations
    if (agentFlowRef.current) {
      gsap.fromTo('.flow-step',
        { y: 40, opacity: 0 },
        {
          scrollTrigger: {
            trigger: agentFlowRef.current,
            start: 'top 80%',
          },
          y: 0,
          opacity: 1,
          stagger: 0.2,
          duration: 1,
          ease: 'power3.out'
        }
      );
    }

    // Trust ticker animation
    gsap.to('.trust-track', {
      xPercent: -50,
      duration: 30,
      ease: 'none',
      repeat: -1
    });

  }, [show]);

  const features = [
    {
      title: 'Concept Search',
      desc: 'Our neural index understands semantic intent, finding files based on meaning rather than just keywords.',
      icon: <Search size={32} />
    },
    {
      title: 'Local Orchestration',
      desc: 'The Butler handles file movements, renaming, and organization through natural language commands.',
      icon: <Cpu size={32} />
    },
    {
      title: 'Privacy Core',
      desc: 'Built on a high-performance Rust engine with a local vector database. Your data never leaves your RAM.',
      icon: <Shield size={32} />
    },
    {
      title: 'Multi-Model Support',
      desc: 'Seamlessly switch between local Llama/Mistral instances and cloud-based models via OpenRouter.',
      icon: <Database size={32} />
    },
    {
      title: 'Smart Cataloging',
      desc: 'AI automatically tags and categorizes every document, generating human-readable metadata instantly.',
      icon: <Tags size={32} />
    },
    {
      title: 'Cost Tracking',
      desc: 'Detailed metrics for token usage and costs, ensuring you stay within your performance budget.',
      icon: <Zap size={32} />
    }
  ];

  return (
    <div className="home-page" style={{ opacity: show ? 1 : 0 }}>
      {/* Dynamic Collapsing Sides */}
      <div className="side-dynamic left" ref={sideLeftRef}>
        <div className="side-content">
          <FileText size={18} />
          <div className="side-line"></div>
          <span>LOCAL</span>
        </div>
      </div>
      <div className="side-dynamic right" ref={sideRightRef}>
        <div className="side-content">
          <span>PRIVATE</span>
          <div className="side-line"></div>
          <Lock size={18} />
        </div>
      </div>

      <section className="hero" ref={heroRef}>
        <div className="container hero-content">
          <div className="hero-badge">
            <Zap size={14} />
            <span>v2.0 Now Available</span>
          </div>
          <h1 className="hero-title">
            Your Second <span className="text-gradient">Brain</span> <br />
            for Local Files
          </h1>
          <p className="hero-subtitle">
            Experience the future of personal data management. Deep semantic search,
            AI orchestration, and privacy-first local processing.
          </p>
          <div className="hero-actions">
            <button className="btn-primary-large">Get Started Free <ChevronRight size={20} /></button>
            <button className="btn-secondary-large">View GitHub</button>
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
              <span key={i} className="trust-item">TRUSTED BY 10,000+ DEVELOPERS • OPEN SOURCE • LOCAL FIRST • </span>
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
            <h2 className="section-title">The <span className="text-gradient">Agent</span> Workflow</h2>
            <p>From natural language intent to secure local execution.</p>
          </div>

          <div className="flow-visual">
            <div className="flow-step glass-card">
              <div className="step-number">1</div>
              <div className="step-icon"><Brain size={32} /></div>
              <h3>Intent Analysis</h3>
              <p>LLM parses your request to understand the objective.</p>
            </div>
            <div className="flow-connector"></div>
            <div className="flow-step glass-card">
              <div className="step-number">2</div>
              <div className="step-icon"><Search size={32} /></div>
              <h3>Context Retrieval</h3>
              <p>Butler finds relevant files via Semantic Search.</p>
            </div>
            <div className="flow-connector"></div>
            <div className="flow-step glass-card highlight">
              <div className="step-number">3</div>
              <div className="step-icon"><Zap size={32} /></div>
              <h3>Local Execution</h3>
              <p>Action is performed securely on your machine.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="integration-section">
        <div className="container">
          <div className="integration-content glass-card">
            <div className="integration-text">
              <h2>Seamless Integration</h2>
              <p>Semantic Butler connects with your existing tools through a powerful CLI and local API.</p>
              <ul className="integration-list">
                <li><ChevronRight size={16} /> Native Windows/macOS/Linux Support</li>
                <li><ChevronRight size={16} /> REST API for Custom Workflows</li>
                <li><ChevronRight size={16} /> Markdown & PDF Deep Parsing</li>
              </ul>
            </div>
            <div className="integration-code">
              <pre>
                <code>
                  {`# Install via CLI
curl -sL get.semanticbutler.com | sh

# Index your workspace
butler index ~/Documents

# Ask your Butler
butler ask "Summarize my last tax return"`}
                </code>
              </pre>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;
