import { Link } from "react-router-dom";

export default function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer
      data-testid="footer"
      className="w-full"
      style={{ borderTop: "1px solid var(--border)" }}
    >
      <div className="container-narrow py-8 flex flex-col sm:flex-row items-center justify-between gap-4">
        <p
          data-testid="footer-tagline"
          className="text-xs"
          style={{ color: "var(--text-muted)", fontFamily: "var(--font-mono)" }}
        >
          SpaceUI · Made for Roblox · {year}
        </p>
        <nav className="flex items-center gap-6">
          <Link
            to="/getting-started"
            data-testid="footer-link-docs"
            className="nav-link"
          >
            Docs
          </Link>
          <Link
            to="/components"
            data-testid="footer-link-components"
            className="nav-link"
          >
            Components
          </Link>
          <a href="#" data-testid="footer-link-github" className="nav-link">
            GitHub
          </a>
        </nav>
      </div>
    </footer>
  );
}
