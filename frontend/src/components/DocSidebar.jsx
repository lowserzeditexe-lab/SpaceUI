import { useEffect, useState } from "react";

/**
 * Sticky left sidebar for documentation pages.
 * Sections: [{ id, label, group? }]
 * Uses IntersectionObserver to highlight the active anchor while scrolling.
 */
export default function DocSidebar({ sections, title = "On this page" }) {
  const [active, setActive] = useState(sections[0]?.id);

  useEffect(() => {
    const els = sections
      .map((s) => document.getElementById(s.id))
      .filter(Boolean);
    if (!els.length) return;

    const obs = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible[0]) setActive(visible[0].target.id);
      },
      { rootMargin: "-96px 0px -60% 0px", threshold: 0 },
    );
    els.forEach((el) => obs.observe(el));
    return () => obs.disconnect();
  }, [sections]);

  const onClick = (e, id) => {
    e.preventDefault();
    const el = document.getElementById(id);
    if (!el) return;
    const top = el.getBoundingClientRect().top + window.scrollY - 88;
    window.scrollTo({ top, behavior: "smooth" });
    setActive(id);
  };

  // Group by optional "group" field
  const groups = [];
  let current = null;
  for (const s of sections) {
    if (s.group && (!current || current.name !== s.group)) {
      current = { name: s.group, items: [] };
      groups.push(current);
    } else if (!s.group) {
      current = { name: null, items: [] };
      groups.push(current);
    }
    current.items.push(s);
  }

  return (
    <aside
      data-testid="doc-sidebar"
      className="hidden lg:block"
      style={{
        position: "sticky",
        top: 88,
        alignSelf: "flex-start",
        width: 220,
        flexShrink: 0,
        paddingRight: "1.5rem",
        borderRight: "1px solid var(--border)",
        maxHeight: "calc(100vh - 96px)",
        overflowY: "auto",
      }}
    >
      <p
        className="text-xs mb-4"
        style={{
          color: "var(--text-muted)",
          fontFamily: "var(--font-mono)",
          letterSpacing: "0.2em",
          textTransform: "uppercase",
        }}
      >
        {title}
      </p>
      <nav className="flex flex-col gap-0.5">
        {groups.map((g, gi) => (
          <div key={gi} className={gi > 0 ? "mt-4" : ""}>
            {g.name && (
              <p
                className="text-xs mb-2"
                style={{
                  color: "var(--text-muted)",
                  fontFamily: "var(--font-mono)",
                  letterSpacing: "0.1em",
                  textTransform: "uppercase",
                }}
              >
                {g.name}
              </p>
            )}
            {g.items.map((s) => {
              const isActive = active === s.id;
              return (
                <a
                  key={s.id}
                  href={`#${s.id}`}
                  data-testid={`sidebar-link-${s.id}`}
                  onClick={(e) => onClick(e, s.id)}
                  style={{
                    display: "block",
                    padding: "6px 10px",
                    borderRadius: 6,
                    fontSize: "0.8125rem",
                    color: isActive ? "var(--text)" : "var(--text-dim)",
                    background: isActive
                      ? "rgba(255,255,255,0.05)"
                      : "transparent",
                    borderLeft: isActive
                      ? "1px solid rgba(255,255,255,0.6)"
                      : "1px solid transparent",
                    transition: "color 200ms ease-out, background 200ms ease-out",
                    textDecoration: "none",
                  }}
                >
                  {s.label}
                </a>
              );
            })}
          </div>
        ))}
      </nav>
    </aside>
  );
}
