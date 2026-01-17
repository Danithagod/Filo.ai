import React, { useEffect } from 'react';
import { gsap } from 'gsap';
import { Check, Zap, Shield, Crown } from 'lucide-react';
import './Pricing.css';

const Pricing = ({ show }) => {
  useEffect(() => {
    if (show) {
      gsap.from('.pricing-card', {
        y: 50,
        opacity: 0,
        duration: 0.8,
        stagger: 0.2,
        ease: 'power3.out'
      });
    }
  }, [show]);

  const tiers = [
    {
      name: 'Starter',
      price: '$0',
      description: 'Perfect for personal file organization.',
      icon: <Zap size={24} />,
      features: ['Up to 10,000 files', 'Standard Semantic Search', 'Community Support', 'Local Processing']
    },
    {
      name: 'Pro',
      price: '$12',
      description: 'For power users and professionals.',
      icon: <Shield size={24} />,
      features: ['Unlimited files', 'Advanced AI Agents', 'Priority Support', 'Custom Tagging Logic', 'API Access'],
      popular: true
    },
    {
      name: 'Team',
      price: '$49',
      description: 'Collaborative AI for small teams.',
      icon: <Crown size={24} />,
      features: ['Shared Semantic Index', 'Team Analytics', 'Admin Dashboard', 'SSO Integration', 'Dedicated Manager']
    }
  ];

  return (
    <div className="pricing-page" style={{ opacity: show ? 1 : 0 }}>
      <section className="pricing-hero">
        <div className="container">
          <h1 className="hero-title">Simple, Transparent <span className="text-gradient">Pricing</span></h1>
          <p className="hero-subtitle">Choose the plan that fits your local intelligence needs.</p>
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
                <button className={`btn-tier ${tier.popular ? 'btn-primary' : 'btn-secondary'}`}>
                  Get Started
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
};

export default Pricing;
