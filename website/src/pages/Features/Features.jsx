import React, { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { gsap } from 'gsap';
import { Search, Cpu, Shield, Zap, Database, Tags, ChevronRight, Layout, Lock, Code } from 'lucide-react';
import './Features.css';

    const Features = ({ show }) => {
    useEffect(() => {
        if (show) {
            const tl = gsap.timeline({ defaults: { ease: 'power3.out', duration: 1 } });

            tl.fromTo('.features-hero .hero-title',
                { opacity: 0, y: 30 },
                { opacity: 1, y: 0, duration: 1 }
            )
                .fromTo('.features-hero .hero-subtitle',
                    { opacity: 0, y: 20 },
                    { opacity: 1, y: 0, duration: 1, delay: -0.6 }
                )
                .fromTo('.feature-deep-section',
                    { opacity: 0, y: 50 },
                    { opacity: 1, y: 0, stagger: 0.3, duration: 1, delay: -0.4 }
                );

            return () => {
                tl.kill();
            };
        }
    }, [show]);

    const featureGroups = [
        {
            title: "Intelligent Search",
            icon: <Search size={40} />,
            features: [
                { name: "Semantic Embedding", desc: "Files are converted into high-dimensional vectors for meaning-based retrieval via pgvector." },
                { name: "Hybrid Search", desc: "Combines keyword matching with semantic intent for superior retrieval accuracy." },
                { name: "Contextual Awareness", desc: "Butler understands the relationship between your documents and their categories." }
            ]
        },
        {
            title: "AI Orchestration",
            icon: <Cpu size={40} />,
            features: [
                { name: "Task Automation", desc: "Natural language commands translate into complex, multi-step file operations." },
                { name: "Multi-Model Inference", desc: "Access 200+ models including GPT-4o, Claude 3.5, and Gemini Pro via OpenRouter." },
                { name: "Local-First Processing", desc: "All file extraction, indexing, and management happens on your local hardware." }
            ]
        },
        {
            title: "Security & Performance",
            icon: <Shield size={40} />,
            features: [
                { name: "Serverpod Backend", desc: "High-performance Dart-based server ensures rapid indexing and low latency." },
                { name: "Privacy-Focused", desc: "Your document structure and sensitive file content are managed locally." },
                { name: "Hardware Optimized", desc: "Designed for desktop platforms with native support for Windows, macOS, and Linux." }
            ]
        }
    ];

    return (
        <div className={`features-page page-content${show ? ' visible' : ''}`}>
            <section className="features-hero">
                <div className="container">
                    <h1 className="hero-title">Powerful <span className="text-gradient">Capabilities</span></h1>
                    <p className="hero-subtitle">Deep dive into the technology that powers your intelligent desktop assistant.</p>
                </div>
            </section>

            {featureGroups.map((group, idx) => (
                <section key={idx} className="feature-deep-section container">
                    <div className="feature-group-header">
                        <div className="group-icon-large glass-card">{group.icon}</div>
                        <h2>{group.title}</h2>
                    </div>
                    <div className="feature-sub-grid">
                        {group.features.map((f, i) => (
                            <div key={i} className="feature-sub-card glass-card">
                                <h3>{f.name}</h3>
                                <p>{f.desc}</p>
                            </div>
                        ))}
                    </div>
                </section>
            ))}

            <section className="features-cta container">
                <div className="cta-glass glass-card">
                    <h2>Ready to transform your workflow?</h2>
                    <p>Download Semantic Butler today and experience true desktop intelligence.</p>
                    <Link to="/pricing" className="btn-primary-large">Get Started Now <ChevronRight size={20} /></Link>
                </div>
            </section>
        </div>
    );
};

export default Features;
