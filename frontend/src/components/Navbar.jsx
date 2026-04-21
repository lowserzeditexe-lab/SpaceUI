import { NavLink, Link } from "react-router-dom";
import { Github } from "lucide-react";

const links = [
  { to: "/getting-started", label: "Docs" },
  { to: "/components", label: "Components" },
  { to: "/examples", label: "Examples" },
];

export default function Navbar() {
  return (
    <header
      data-testid="navbar"
      className="sticky top-0 z-50 w-full"
      style={{
        background: "rgba(10,10,10,0.55)",
        backdropFilter: "blur(20px)",
        WebkitBackdropFilter: "blur(20px)",
        borderBottom: "1px solid var(--border)",
      }}
    >
      <div className="container-narrow flex items-center justify-between h-16">
        <Link
          to="/"
          data-testid="nav-logo"
          className="flex items-center gap-2"
          style={{ color: "var(--text)" }}
        >
          <LogoMark />
          <span
            className="font-heading text-lg"
            style={{ fontWeight: 600, letterSpacing: "-0.02em" }}
          >
            SpaceUI
          </span>
        </Link>

        <nav className="hidden md:flex items-center gap-8">
          {links.map((l) => (
            <NavLink
              key={l.to}
              to={l.to}
              data-testid={`nav-link-${l.label.toLowerCase().replace(/\s/g, "-")}`}
              className={({ isActive }) =>
                `nav-link ${isActive ? "active" : ""}`
              }
            >
              {l.label}
            </NavLink>
          ))}
          <a
            href="#"
            data-testid="nav-link-github"
            className="nav-link flex items-center gap-1.5"
            aria-label="GitHub"
          >
            <Github size={14} />
            GitHub
          </a>
        </nav>

        <div className="flex items-center gap-2">
          <Link
            to="/getting-started"
            data-testid="nav-cta-docs"
            className="btn btn-ghost hidden sm:inline-flex"
          >
            Read docs
          </Link>
        </div>
      </div>
    </header>
  );
}

function LogoMark() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 22 22"
      fill="none"
      aria-hidden="true"
    >
      <circle
        cx="11"
        cy="11"
        r="10"
        stroke="currentColor"
        strokeOpacity="0.35"
      />
      <circle cx="11" cy="11" r="2" fill="currentColor" />
      <circle
        cx="11"
        cy="11"
        r="6"
        stroke="currentColor"
        strokeOpacity="0.2"
      />
    </svg>
  );
}
