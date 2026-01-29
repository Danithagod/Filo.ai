import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { gsap } from 'gsap';
import { Cpu, Shield, ChevronRight, Search, Zap, Tag, FolderTree } from 'lucide-react';
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
            title: "AI-Powered Search",
            icon: <Search size={40} />,
            features: [
                { name: "Semantic Search", desc: "Find files by meaning, not just keywords. Our neural index understands context and intent." },
                { name: "Hybrid Search Mode", desc: "Combine semantic understanding with traditional keyword matching for comprehensive results." },
                { name: "AI Conversational Search", desc: "Ask questions in natural language and get intelligent, contextual answers about your files." }
            ]
        },
        {
            title: "Tag Management",
            icon: <Tag size={40} />,
            features: [
                { name: "Smart Tagging System", desc: "Organize files with tags grouped by topics, entities, and keywords. Full tag manager with merge and rename capabilities." },
                { name: "@-Mention File Tagging", desc: "Tag files directly in chat using @-mentions. Quick file attachment as you compose your queries." },
                { name: "Related Tags Discovery", desc: "Explore tag relationships and co-occurrences to discover connections in your file system." }
            ]
        },
        {
            title: "Local-First Architecture",
            icon: <Shield size={40} />,
            features: [
                { name: "Privacy Respecting", desc: "Your file index and metadata stay on your machine. Only queries are sent to AI models." },
                { name: "Cross-Platform Desktop", desc: "Native Windows, macOS, and Linux support with optimized performance for each platform." },
                { name: "Real-Time Indexing", desc: "Automatic file indexing with progress tracking and comprehensive content extraction." }
            ]
        },
        {
            title: "Intelligent Assistance",
            icon: <Cpu size={40} />,
            features: [
                { name: "AI Chat Interface", desc: "Interact with your files through conversation. Ask questions, get summaries, and find what you need." },
                { name: "Multi-Model Support", desc: "Access 200+ AI models via OpenRouter including GPT-4, Claude, and Gemini." },
                { name: "Advanced Filtering", desc: "Refine searches by file type, date range, tags, and search facets for precise results." }
            ]
        },
        {
            title: "File Management",
            icon: <FolderTree size={40} />,
            features: [
                { name: "Full File Browser", desc: "Navigate your entire file system with an integrated file manager supporting multiple views." },
                { name: "Document Preview", desc: "Preview files with extracted content, metadata, and AI-generated snippets." },
                { name: "Search History", desc: "Access recent searches and continue where you left off." }
            ]
        },
        {
            title: "Index Management",
            icon: <Zap size={40} />,
            features: [
                { name: "Health Dashboard", desc: "Monitor index status with comprehensive health metrics and error reporting." },
                { name: "Progress Tracking", desc: "Real-time indexing progress with detailed status updates for each job." },
                { name: "Multiple File Types", desc: "Support for documents, PDFs, markdown, code, and many other file formats." }
            ]
        }
    ];

    return (
        <div className={`features-page page-content${show ? ' visible' : ''}`}>
            <section className="features-hero">
                <div className="container">
                    <h1 className="hero-title">Powerful <span className="text-gradient">Capabilities</span></h1>
                    <p className="hero-subtitle">Deep dive into the technology that powers your intelligent desktop search assistant.</p>
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
                    <h2>Ready to transform your file search?</h2>
                    <p>Download Filo today and experience true desktop intelligence.</p>
                    <Link to="/download" className="btn-primary-large">Get Started Now <ChevronRight size={20} /></Link>
                </div>
            </section>
        </div>
    );
};

export default Features;
