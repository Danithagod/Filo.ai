import { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { Search, Tags, Cpu, Shield, Zap, ChevronRight, FileText, Database, Lock } from 'lucide-react';
import Logo from '../../components/Logo/Logo';
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
  const rotatingTextRef = useRef(null);
  const maskRef = useRef(null);

  // Store animation references to ensure proper cleanup
  const animationsRef = useRef({
    timeline: null,
    triggers: [],
    tickerAnimation: null
  });

  useEffect(() => {
    if (!show) return;

    const words = ['Desktop', 'Privacy', 'Files'];
    let currentIndex = 0;

    const rotateText = () => {
      currentIndex = (currentIndex + 1) % words.length;
      const element = rotatingTextRef.current;
      const mask = maskRef.current;
      
      if (!element || !mask) return;

      // Create a temporary span to measure the width of the next word
      const temp = document.createElement('span');
      temp.style.visibility = 'hidden';
      temp.style.position = 'absolute';
      temp.style.whiteSpace = 'nowrap';
      temp.style.fontSize = window.getComputedStyle(element).fontSize;
      temp.style.fontWeight = window.getComputedStyle(element).fontWeight;
      temp.style.fontFamily = window.getComputedStyle(element).fontFamily;
      temp.style.letterSpacing = window.getComputedStyle(element).letterSpacing;
      temp.textContent = words[currentIndex];
      document.body.appendChild(temp);
      const nextWidth = temp.getBoundingClientRect().width;
      document.body.removeChild(temp);

      const tl = gsap.timeline();
      
      tl.to(element, {
        yPercent: -120,
        opacity: 0,
        duration: 0.5,
        ease: 'power3.in',
        onComplete: () => {
          element.textContent = words[currentIndex];
          gsap.set(element, { yPercent: 120, opacity: 0 });
        }
      })
      .to(mask, {
        width: nextWidth,
        duration: 0.6,
        ease: 'power4.inOut'
      }, '-=0.3')
      .to(element, {
        yPercent: 0,
        opacity: 1,
        duration: 0.6,
        ease: 'power4.out'
      }, '-=0.3');
    };

    const rotationInterval = setInterval(rotateText, 3000);

    // Initialize mask width
    if (maskRef.current && rotatingTextRef.current) {
      gsap.set(maskRef.current, { width: rotatingTextRef.current.getBoundingClientRect().width });
    }

    // Clean up any existing animations before creating new ones
    const animations = animationsRef.current;
    animations.triggers.forEach(trigger => trigger?.kill());
    animations.triggers = [];
    animations.timeline?.kill();
    animations.tickerAnimation?.kill();

    // Hero Animations
    const tl = gsap.timeline({ defaults: { ease: 'power4.out', duration: 1.4 } });
    animations.timeline = tl;

    tl.fromTo('.hero-badge',
      { y: 20, opacity: 0, scale: 0.95 },
      { y: 0, opacity: 1, scale: 1, duration: 1 }
    )
      .fromTo('.hero-title',
        { opacity: 0 },
        { opacity: 1, duration: 1.5, delay: -0.8 }
      )
      .fromTo('.hero-subtitle',
        { y: 20, opacity: 0 },
        { y: 0, opacity: 1, duration: 1.2, delay: -1 }
      )
      .fromTo('.hero-actions',
        { y: 20, opacity: 0 },
        { y: 0, opacity: 1, duration: 1.2, delay: -1 }
      )
      .fromTo(visualRef.current,
        { scale: 0.9, opacity: 0, y: 60 },
        { scale: 1, opacity: 1, y: 0, duration: 1.6, delay: -1 }
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
      clearInterval(rotationInterval);
      // Use captured animations to ensure proper cleanup
      const currentAnimations = animations;
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
      title: 'Semantic Search',
      desc: 'Our neural index understands semantic intent, finding files based on meaning rather than just keywords.',
      icon: <Search size={32} />
    },
    {
      title: 'AI Chat Assistant',
      desc: 'Interact with your files through natural language. Ask questions, get summaries, and find what you need instantly.',
      icon: <Cpu size={32} />
    },
    {
      title: 'Privacy Focused',
      desc: 'Built on Serverpod with a local-first approach. Your file index stays on your machine with optional cloud AI for queries.',
      icon: <Shield size={32} />
    },
    {
      title: 'Multi-Model Support',
      desc: 'Access 200+ AI models including GPT-4, Claude, and Gemini via OpenRouter integration for intelligent queries.',
      icon: <Database size={32} />
    },
    {
      title: 'Smart Indexing',
      desc: 'Real-time file indexing with progress tracking. Supports multiple file types with comprehensive content extraction.',
      icon: <Tags size={32} />
    },
    {
      title: 'Index Health Dashboard',
      desc: 'Monitor your index status with detailed metrics and comprehensive health monitoring tools.',
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
            <div className="title-line">
              <span className="static-text">Your Intelligent</span>
              <span className="rotating-mask" ref={maskRef}>
                <span className="text-gradient rotating-word" ref={rotatingTextRef}>Desktop</span>
              </span>
            </div>
            <div className="title-line">
              Data Intelligence
            </div>
          </h1>
          <p className="hero-subtitle">
            Experience the next generation of file search. Filo combines deep neural search
            with AI-powered chat to help you find and interact with your documents through
            natural language queries.
          </p>
          <div className="hero-actions">
            <Link to="/download" className="btn-primary-large" aria-label="Get started with Filo for free">Download Now <ChevronRight size={20} /></Link>
            <a href="https://github.com" target="_blank" rel="noopener noreferrer" className="btn-secondary-large" aria-label="View Filo on GitHub">View GitHub</a>
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
            <h2 className="section-title">The <span className="text-gradient">Filo</span> Flow</h2>
            <p>From natural language queries to intelligent search results.</p>
          </div>

          <div className="flow-visual">
            <div className="flow-step glass-card">
              <div className="step-number">1</div>
              <div className="step-icon"><Logo size={32} /></div>
              <h3>Query Analysis</h3>
              <p>The AI assistant parses your natural language query to understand your intent.</p>
            </div>
            <div className="flow-connector"></div>
            <div className="flow-step glass-card">
              <div className="step-number">2</div>
              <div className="step-icon"><Search size={32} /></div>
              <h3>Smart Retrieval</h3>
              <p>Filo searches using semantic, hybrid, or AI-powered modes to find relevant files.</p>
            </div>
            <div className="flow-connector"></div>
            <div className="flow-step glass-card highlight">
              <div className="step-number">3</div>
              <div className="step-icon"><Zap size={32} /></div>
              <h3>Intelligent Results</h3>
              <p>Get ranked results with previews, snippets, and AI-generated insights.</p>
            </div>
          </div>
        </div>
      </section>

      <section className="privacy-focus-section">
        <div className="container">
          <div className="privacy-grid">
            <div className="privacy-content">
              <div className="hero-badge" style={{ opacity: 1 }}>
                <Shield size={14} />
                <span>Privacy First</span>
              </div>
              <h2 className="section-title">Local-First <span className="text-gradient">Privacy</span> Architecture</h2>
              <p>Filo is built on a local-first philosophy. Your file index and document metadata stay on your machine. Only search queries are sent to AI models for processing, not your full documents.</p>
              
              <div className="privacy-features">
                <div className="p-feat">
                  <Lock size={20} />
                  <div>
                    <h4>Local Vector DB</h4>
                    <p>High-performance neural indexing stored securely in your application data folder.</p>
                  </div>
                </div>
                <div className="p-feat">
                  <Shield size={20} />
                  <div>
                    <h4>OpenRouter Privacy</h4>
                    <p>Only text fragments required for specific queries are processed, with optional local model support.</p>
                  </div>
                </div>
              </div>
            </div>
            <div className="privacy-visual glass-card">
              <div className="shield-icon-large">
                <Shield size={120} />
                <div className="shield-rings">
                  <div className="ring"></div>
                  <div className="ring"></div>
                  <div className="ring"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="integration-section">
        <div className="container">
          <div className="integration-content glass-card">
            <div className="integration-text">
              <h2>Desktop Power</h2>
              <p>Filo integrates deeply with your operating system to provide a seamless management experience.</p>
              <ul className="integration-list">
                <li><ChevronRight size={16} /> Native Windows/macOS/Linux Support</li>
                <li><ChevronRight size={16} /> Real-time File System Monitoring</li>
                <li><ChevronRight size={16} /> Markdown & PDF Deep Parsing</li>
              </ul>
            </div>
            <div className="integration-code">
              <div className="integration-text">
                <h3>Rich AI Toolset</h3>
                <p>The assistant has access to a variety of tools to help you manage your digital workspace:</p>
                <ul className="integration-list" style={{ marginTop: '1rem' }}>
                  <li><Search size={16} /> Semantic, Hybrid & AI-Powered Search</li>
                  <li><FileText size={16} /> Document Preview & Content Extraction</li>
                  <li><Cpu size={16} /> Conversational File Queries</li>
                  <li><Database size={16} /> Index Health & Search Analytics</li>
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
