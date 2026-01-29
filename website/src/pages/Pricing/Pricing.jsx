import React, { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { gsap } from 'gsap';
import { Check, Zap, Shield, Crown } from 'lucide-react';
import './Pricing.css';

const Pricing = ({ show }) => {
  useEffect(() => {
    if (show) {
      const animation = gsap.from('.pricing-card', {
        y: 50,
        opacity: 0,
        duration: 0.8,
        stagger: 0.2,
        ease: 'power3.out'
      });

      return () => {
        animation.kill();
      };
    }
  }, [show]);

  const tiers = [
    {
      name: 'Starter',
      price: '$0',
      description: 'Perfect for personal file search.',
      icon: <Zap size={24} />,
      features: ['Up to 5,000 indexed files', 'Standard Semantic Search', 'AI Chat Assistant', 'Community Support']
    },
    {
      name: 'Pro',
      price: '$12',
      description: 'For power users and professionals.',
      icon: <Shield size={24} />,
      features: ['Unlimited indexed files', 'Advanced AI Search Modes', 'OpenRouter Multi-Model Support', 'Priority Support'],
      popular: true
    },
    {
      name: 'Enterprise',
      price: '$39',
      description: 'Advanced features for complex workflows.',
      icon: <Crown size={24} />,
      features: ['Smart Index Health Monitoring', 'Unlimited Search History', 'Advanced Filtering Options', 'Dedicated Support']
    }
  ];

  return (
    <div className={`pricing-page page-content${show ? ' visible' : ''}`}>
      <section className="pricing-hero">
        <div className="container">
          <h1 className="hero-title">Simple, Transparent <span className="text-gradient">Pricing</span></h1>
          <p className="hero-subtitle">Choose the plan that fits your digital workspace needs.</p>
        </div>
      </section>

      <section className="pricing-grid-section">
        <div className="container">
          <div className="pricing-grid">
            {tiers.map((tier, i) => (
              <div key={i} className={`pricing-card glass-card ${tier.popular ? 'popular' : ''}`}>
                {tier.popular && <div className="popular-badge">Most Popular</div>}
                <div className="tier-header">
                  <div className="tier-icon">{tier.icon}</div>
                  <h3>{tier.name}</h3>
                  <div className="price">
                    <span className="amount">{tier.price}</span>
                    <span className="period">/month</span>
                  </div>
                  <p className="tier-desc">{tier.description}</p>
                </div>
                <ul className="tier-features">
                  {tier.features.map((feature, j) => (
                    <li key={j}><Check size={16} /> {feature}</li>
                  ))}
                </ul>
                <Link to="/pricing" className={`btn-tier ${tier.popular ? 'btn-primary' : 'btn-secondary'}`}>
                  Get Started
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
};

export default Pricing;
