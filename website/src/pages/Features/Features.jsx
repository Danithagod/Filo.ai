import React, { useEffect } from 'react';
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
        }
    }, [show]);

    const featureGroups = [
        {
            title: "Intelligent Search",
            icon: <Search size={40} />,
            features: [
                { name: "Semantic Embedding", desc: "Files are converted into high-dimensional vectors for meaning-based retrieval." },
                { name: "Hybrid Search", desc: "Combines keyword matching with semantic intent for perfect accuracy." },
                { name: "Contextual Awareness", desc: "Butler understands the relationship between your documents." }
            ]
        },
        {
            title: "Local AI Orchestration",
            icon: <Cpu size={40} />,
            features: [
                { name: "Task Automation", desc: "Natural language commands translate into complex file operations." },
                { name: "Local LLM Integration", desc: "Compatible with Llama, Mistral, and GGUF models via Ollama." },
                { name: "Zero Cloud Reliance", desc: "All reasoning and processing happens offline on your hardware." }
            ]
        },
        {
            title: "Security & Performance",
            icon: <Shield size={40} />,
            features: [
                { name: "Rust Core", desc: "Lightning fast indexing and low memory footprint powered by Rust." },
                { name: "End-to-End Privacy", desc: "Your data never touches our servers. Period." },
                { name: "Hardware Acceleration", desc: "Utilizes GPU and NPU for local embedding and inference." }
            ]
        }
    ];

    return (
        <div className="features-page" style={{ opacity: show ? 1 : 0 }}>
            <section className="features-hero">
                <div className="container">
                    <h1 className="hero-title">Powerful <span className="text-gradient">Capabilities</span></h1>
                    <p className="hero-subtitle">Deep dive into the technology that powers your local semantic brain.</p>
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
                    <p>Download Semantic Butler today and experience true local intelligence.</p>
                    <button className="btn-primary-large">Get Started Now <ChevronRight size={20} /></button>
                </div>
            </section>
        </div>
    );
};

export default Features;
