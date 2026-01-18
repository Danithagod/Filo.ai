import React, { useEffect, useRef } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Brain, Menu, X } from 'lucide-react';
import { gsap } from 'gsap';
import './Navbar.css';

const Navbar = ({ show }) => {
  const [isOpen, setIsOpen] = React.useState(false);
  const navRef = useRef(null);
  const location = useLocation();

  useEffect(() => {
    if (show) {
      gsap.to(navRef.current, {
        y: 0,
        opacity: 1,
        duration: 1,
        ease: 'power4.out',
      });
    }
  }, [show]);

  const navLinks = [
    { name: 'Home', path: '/' },
    { name: 'Features', path: '/features' },
    { name: 'Pricing', path: '/pricing' },
    { name: 'About', path: '/about' },
  ];

  return (
    <nav className="navbar-container" ref={navRef} style={{ opacity: 0, transform: 'translateY(-100px)' }} role="navigation" aria-label="Main navigation">
      <div className="navbar-pill">
        <Link to="/" className="nav-logo" aria-label="Semantic Butler Home">
          <Brain size={24} className="logo-icon" />
          <span>Semantic Butler</span>
        </Link>

        <div className={`nav-links ${isOpen ? 'active' : ''}`} role="menubar">
          {navLinks.map((link) => (
            <Link
              key={link.path}
              to={link.path}
              className={`nav-item ${location.pathname === link.path ? 'active' : ''}`}
              onClick={() => setIsOpen(false)}
              role="menuitem"
              aria-current={location.pathname === link.path ? 'page' : undefined}
            >
              {link.name}
            </Link>
          ))}
          <Link to="/pricing" className="btn-nav-primary" role="menuitem" aria-label="Download Semantic Butler">Download</Link>
        </div>

        <button className="nav-toggle" onClick={() => setIsOpen(!isOpen)} aria-label={isOpen ? 'Close navigation menu' : 'Open navigation menu'} aria-expanded={isOpen}>
          {isOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>
    </nav>
  );
};

export default Navbar;
