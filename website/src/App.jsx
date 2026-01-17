import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import Lenis from 'lenis';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Background from './components/Background/Background';
import Navbar from './components/Navbar/Navbar';
import Loader from './components/Loader/Loader';
import Home from './pages/Home/Home';
import Features from './pages/Features/Features';
import About from './pages/About/About';
import './App.css';

// ScrollToTop component to reset scroll on navigation
const ScrollToTop = () => {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
    ScrollTrigger.refresh();
  }, [pathname]);
  return null;
};

gsap.registerPlugin(ScrollTrigger);

function App() {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      orientation: 'vertical',
      gestureOrientation: 'vertical',
      smoothWheel: true,
      wheelMultiplier: 1,
      smoothTouch: false,
      touchMultiplier: 2,
      infinite: false,
    });

    lenis.on('scroll', () => {
      ScrollTrigger.update();
    });

    function raf(time) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }

    requestAnimationFrame(raf);

    // Initial refresh
    setTimeout(() => {
      ScrollTrigger.refresh();
    }, 500);

    return () => {
      lenis.destroy();
    };
  }, []);

  return (
    <Router>
      <ScrollToTop />
      <div className="app-container">
        {loading && <Loader onFinished={() => setLoading(false)} />}

        <Background />
        <Navbar show={!loading} />

        <main className="content-wrapper">
          <Routes>
            <Route path="/" element={<Home show={!loading} />} />
            <Route path="/features" element={<Features show={!loading} />} />
            <Route path="/about" element={<About show={!loading} />} />
          </Routes>
        </main>

        <footer className="footer">
          <div className="container footer-grid">
            <div className="footer-brand">
              <div className="logo">Semantic Butler</div>
              <p>Private AI for your local data.</p>
            </div>
            <div className="footer-links">
              <div className="link-group">
                <h4>Product</h4>
                <a href="/features">Features</a>
                <a href="/download">Download</a>
              </div>
              <div className="link-group">
                <h4>Resources</h4>
                <a href="/docs">Documentation</a>
                <a href="/github">GitHub</a>
                <a href="/api">API Reference</a>
              </div>
              <div className="link-group">
                <h4>Company</h4>
                <a href="/about">About</a>
                <a href="/privacy">Privacy</a>
                <a href="/terms">Terms</a>
              </div>
            </div>
          </div>
          <div className="footer-bottom">
            <div className="container">
              <p>© 2026 Semantic Butler. All rights reserved.</p>
            </div>
          </div>
        </footer>
      </div>
    </Router>
  );
}

export default App;