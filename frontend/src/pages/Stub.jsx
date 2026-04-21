import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import Starfield from "@/components/Starfield";
import { Link } from "react-router-dom";
import { ArrowLeft } from "lucide-react";

export default function Stub({ name = "Coming Soon" }) {
  return (
    <div className="page" data-testid={`stub-page-${name.toLowerCase().replace(/\s/g, "-")}`}>
      <Navbar />
      <main
        className="page-main relative overflow-hidden"
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "calc(100vh - 4rem)",
        }}
      >
        <Starfield density={0.00012} />
        <div className="radial-glow" aria-hidden="true" />
        <div className="grid-overlay" aria-hidden="true" />

        <div
          className="container-narrow relative text-center"
          style={{ zIndex: 1, padding: "6rem 1.5rem" }}
        >
          <span className="badge anim-fade delay-1" data-testid="stub-badge">
            <span className="dot" />
            Phase 3
          </span>
          <h1
            data-testid="stub-title"
            className="font-heading anim-rise delay-2 mt-6"
            style={{
              fontSize: "clamp(2.5rem, 8vw, 5rem)",
              fontWeight: 500,
              letterSpacing: "-0.035em",
              lineHeight: 1,
              background:
                "linear-gradient(180deg, #ffffff 0%, #b5b5b5 100%)",
              WebkitBackgroundClip: "text",
              backgroundClip: "text",
              color: "transparent",
            }}
          >
            {name}
          </h1>
          <p
            data-testid="stub-message"
            className="anim-rise delay-3 mt-5 mx-auto max-w-md"
            style={{
              color: "var(--text-dim)",
              fontSize: "1rem",
              lineHeight: 1.55,
            }}
          >
            Coming in Phase 3.
            <br />
            <span style={{ color: "var(--text-muted)", fontSize: "0.875rem" }}>
              We&apos;re assembling the pieces. Check back soon.
            </span>
          </p>
          <div className="anim-rise delay-4 mt-8">
            <Link to="/" data-testid="stub-back-home" className="btn btn-ghost">
              <ArrowLeft size={14} /> Back to home
            </Link>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
