import { Link } from "react-router-dom";
import { ArrowRight, ChevronDown, Sparkles, Settings2, Contrast } from "lucide-react";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import Starfield from "@/components/Starfield";
import CodeBlock from "@/components/CodeBlock";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL || "";
// Note: Using /api/spaceui.lua for K8s ingress routing compatibility
// The ingress routes /api/* to backend, all other paths to frontend
const LOADSTRING = `loadstring(game:HttpGet("${BACKEND_URL}/api/spaceui.lua"))()`;

const features = [
  {
    icon: Sparkles,
    title: "Fluent API",
    desc: "Chainable, expressive, minimal. Build UIs that read like prose.",
  },
  {
    icon: Settings2,
    title: "Config System",
    desc: "Persisted, typed config for every control. One source of truth.",
  },
  {
    icon: Contrast,
    title: "Black & White",
    desc: "A strict monochrome palette. No saturation, no noise. Just signal.",
  },
];

export default function Home() {
  return (
    <div className="page" data-testid="home-page">
      <Navbar />
      <main className="page-main">
        {/* HERO */}
        <section
          data-testid="hero-section"
          className="relative overflow-hidden"
          style={{
            minHeight: "calc(100vh - 4rem)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          {/* Background layers */}
          <Starfield />
          <div className="radial-glow" aria-hidden="true" />
          <div className="grid-overlay" aria-hidden="true" />

          <div
            className="container-narrow relative"
            style={{ zIndex: 1, paddingTop: "6rem", paddingBottom: "8rem" }}
          >
            <div className="flex flex-col items-center text-center">
              <span
                data-testid="hero-badge"
                className="badge anim-fade delay-1"
              >
                <span className="dot" />
                v1.0 · Built for Roblox devs
              </span>

              <h1
                data-testid="hero-title"
                className="hero-title anim-rise delay-2 mt-6 sm:mt-8"
                style={{
                  fontSize: "clamp(3.75rem, 13vw, 10.5rem)",
                }}
              >
                SpaceUI
              </h1>

              <p
                data-testid="hero-subtitle"
                className="anim-rise delay-3 mt-5 max-w-xl"
                style={{
                  color: "var(--text-dim)",
                  fontSize: "1.0625rem",
                  lineHeight: 1.55,
                }}
              >
                A minimalist Roblox UI Kit.
                <br className="hidden sm:block" />
                <span style={{ color: "var(--text)" }}>
                  {" "}Black, white, infinite.
                </span>
              </p>

              {/* Loadstring CTA */}
              <div
                data-testid="hero-cta"
                className="anim-rise delay-4 mt-10 w-full max-w-2xl"
              >
                <CodeBlock code={LOADSTRING} label="lua · loadstring" testId="loadstring-block" />
              </div>

              <div className="anim-rise delay-5 mt-6 flex items-center gap-3">
                <Link
                  to="/getting-started"
                  data-testid="hero-read-docs"
                  className="btn btn-ghost"
                >
                  Read the docs <ArrowRight size={14} />
                </Link>
                <Link
                  to="/components"
                  data-testid="hero-browse-components"
                  className="btn btn-primary"
                >
                  Browse components
                </Link>
              </div>
            </div>
          </div>

          {/* Scroll indicator */}
          <div
            data-testid="scroll-indicator"
            aria-hidden="true"
            className="absolute left-1/2 -translate-x-1/2"
            style={{ bottom: "1.75rem", color: "var(--text-muted)" }}
          >
            <div className="flex flex-col items-center gap-1 anim-bob">
              <span
                style={{
                  fontSize: "0.625rem",
                  fontFamily: "var(--font-mono)",
                  letterSpacing: "0.2em",
                  textTransform: "uppercase",
                }}
              >
                Scroll
              </span>
              <ChevronDown size={14} />
            </div>
          </div>
        </section>

        {/* FEATURES */}
        <section
          data-testid="features-section"
          className="relative"
          style={{
            borderTop: "1px solid var(--border)",
            paddingTop: "6rem",
            paddingBottom: "7rem",
          }}
        >
          <div className="container-narrow">
            <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-6 mb-12">
              <div>
                <p
                  style={{
                    color: "var(--text-muted)",
                    fontFamily: "var(--font-mono)",
                    fontSize: "0.75rem",
                    letterSpacing: "0.2em",
                    textTransform: "uppercase",
                  }}
                >
                  Principles
                </p>
                <h2
                  className="font-heading mt-2"
                  style={{
                    fontSize: "clamp(1.75rem, 4vw, 2.5rem)",
                    fontWeight: 500,
                    letterSpacing: "-0.03em",
                    lineHeight: 1.05,
                  }}
                >
                  Designed around a <br className="hidden sm:block" />
                  single idea.
                </h2>
              </div>
              <p
                className="max-w-sm"
                style={{
                  color: "var(--text-dim)",
                  fontSize: "0.9375rem",
                  lineHeight: 1.6,
                }}
              >
                Strip every unnecessary pixel. Keep the API quiet. Let the
                interface disappear behind the idea.
              </p>
            </div>

            <div
              data-testid="features-grid"
              className="grid grid-cols-1 md:grid-cols-3 gap-4"
            >
              {features.map((f, i) => {
                const Icon = f.icon;
                return (
                  <article
                    key={f.title}
                    data-testid={`feature-card-${i}`}
                    className="card p-6"
                  >
                    <div
                      className="flex items-center justify-center"
                      style={{
                        width: 38,
                        height: 38,
                        borderRadius: 9,
                        border: "1px solid var(--border)",
                        background: "rgba(255,255,255,0.02)",
                      }}
                    >
                      <Icon size={18} color="var(--text)" />
                    </div>
                    <h3
                      className="font-heading mt-5"
                      style={{
                        fontSize: "1.125rem",
                        fontWeight: 500,
                        letterSpacing: "-0.01em",
                      }}
                    >
                      {f.title}
                    </h3>
                    <p
                      className="mt-2"
                      style={{
                        color: "var(--text-dim)",
                        fontSize: "0.875rem",
                        lineHeight: 1.55,
                      }}
                    >
                      {f.desc}
                    </p>
                    <div
                      className="mt-6 flex items-center gap-2 opacity-0"
                      style={{
                        color: "var(--text-muted)",
                        fontSize: "0.75rem",
                        fontFamily: "var(--font-mono)",
                        letterSpacing: "0.1em",
                        textTransform: "uppercase",
                      }}
                    >
                      <span>0{i + 1}</span>
                    </div>
                    <span
                      aria-hidden="true"
                      style={{
                        position: "absolute",
                        top: "1rem",
                        right: "1rem",
                        fontSize: "0.625rem",
                        fontFamily: "var(--font-mono)",
                        letterSpacing: "0.2em",
                        color: "var(--text-muted)",
                      }}
                    >
                      0{i + 1}
                    </span>
                  </article>
                );
              })}
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
