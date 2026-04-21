import { NavLink, Link } from "react-router-dom";
import { Github, Search } from "lucide-react";

const links = [
  { to: "/getting-started", label: "Docs" },
  { to: "/components", label: "Components" },
  { to: "/examples", label: "Examples" },
  { to: "/reference", label: "API" },
];

function openSearch() {
  window.dispatchEvent(new CustomEvent("spaceui:open-search"));
}

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
          <button
            data-testid="nav-search-btn"
            onClick={openSearch}
            aria-label="Open search"
            className="hidden sm:inline-flex items-center gap-2"
            style={{
              padding: "6px 10px",
              borderRadius: 8,
              border: "1px solid var(--border)",
              background: "rgba(255,255,255,0.02)",
              color: "var(--text-dim)",
              fontSize: "0.8125rem",
              transition:
                "border-color 200ms ease-out, color 200ms ease-out, background 200ms ease-out",
              cursor: "pointer",
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.borderColor = "var(--border-strong)";
              e.currentTarget.style.color = "var(--text)";
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.borderColor = "var(--border)";
              e.currentTarget.style.color = "var(--text-dim)";
            }}
          >
            <Search size={13} />
            <span className="hidden lg:inline">Search</span>
            <span
              style={{
                padding: "1px 5px",
                borderRadius: 4,
                border: "1px solid var(--border)",
                fontSize: "0.6875rem",
                fontFamily: "var(--font-mono)",
                marginLeft: 2,
              }}
              className="hidden lg:inline"
            >
              ⌘K
            </span>
          </button>
          <button
            data-testid="nav-search-btn-mobile"
            onClick={openSearch}
            aria-label="Open search"
            className="sm:hidden inline-flex items-center justify-center"
            style={{
              width: 34,
              height: 34,
              borderRadius: 8,
              border: "1px solid var(--border)",
              background: "rgba(255,255,255,0.02)",
              color: "var(--text-dim)",
              cursor: "pointer",
            }}
          >
            <Search size={15} />
          </button>
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
