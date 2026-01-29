import React, { useState, useEffect } from 'react';
import { Routes, Route, useLocation, Link } from 'react-router-dom';
import Lenis from 'lenis';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Background from './components/Background/Background';
import Navbar from './components/Navbar/Navbar';
import Loader from './components/Loader/Loader';
import NavLoader from './components/NavLoader/NavLoader';
import Home from './pages/Home/Home';
import Features from './pages/Features/Features';
import About from './pages/About/About';
import Download from './pages/Download/Download';
import NotFound from './pages/NotFound/NotFound';
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
  const [navigating, setNavigating] = useState(false);
  const location = useLocation();

  useEffect(() => {
    setNavigating(true);
    const timeout = setTimeout(() => setNavigating(false), 500);
    return () => clearTimeout(timeout);
  }, [location.pathname]);

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

    let rafId;
    function raf(time) {
      lenis.raf(time);
      rafId = requestAnimationFrame(raf);
    }

    rafId = requestAnimationFrame(raf);

    // Initial refresh
    const refreshTimeout = setTimeout(() => {
      ScrollTrigger.refresh();
    }, 500);

    return () => {
      lenis.destroy();
      if (rafId) {
        cancelAnimationFrame(rafId);
      }
      clearTimeout(refreshTimeout);
    };
  }, []);

  return (
    <>
      <ScrollToTop />
      <div className="app-container">
        {loading && <Loader onFinished={() => setLoading(false)} />}
        {navigating && <NavLoader />}

        <Background />
        <Navbar show={!loading} />

        <main className="content-wrapper">
          <Routes>
            <Route path="/" element={<Home show={!loading} />} />
            <Route path="/features" element={<Features show={!loading} />} />
            <Route path="/about" element={<About show={!loading} />} />
            <Route path="/download" element={<Download show={!loading} />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </main>

        <footer className="footer" role="contentinfo">
          <div className="container footer-grid">
            <div className="footer-brand">
              <div className="logo">Filo</div>
              <p>AI-powered semantic search for your local files.</p>
            </div>
            <nav className="footer-links" aria-label="Footer navigation">
              <div className="link-group">
                <h4>Product</h4>
                <Link to="/features">Features</Link>
                <Link to="/download">Download</Link>
                <Link to="/about">About</Link>
              </div>
              <div className="link-group">
                <h4>Resources</h4>
                <a href="https://github.com" target="_blank" rel="noopener noreferrer">GitHub</a>
              </div>
            </nav>
          </div>
          <div className="footer-bottom">
            <div className="container">
              <p>© 2026 Filo. All rights reserved.</p>
            </div>
          </div>
        </footer>
      </div>
    </>
  );
}

export default App;