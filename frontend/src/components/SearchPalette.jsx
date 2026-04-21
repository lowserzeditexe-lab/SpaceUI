import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Command } from "cmdk";
import axios from "axios";
import { Search, Box, Code2, Hash } from "lucide-react";

const API = `${process.env.REACT_APP_BACKEND_URL || ""}/api`;

/**
 * Global search palette. Triggered by Cmd/Ctrl+K (handled in App.js)
 * and by the Navbar Search pill. Shows Components, Methods, and Examples.
 */
export default function SearchPalette({ open, onOpenChange }) {
  const [loaded, setLoaded] = useState(false);
  const [components, setComponents] = useState([]);
  const [methods, setMethods] = useState([]);
  const [examples, setExamples] = useState([]);
  const [search, setSearch] = useState("");
  const navigate = useNavigate();

  useEffect(() => {
    if (!open || loaded) return;
    let cancelled = false;
    Promise.all([
      axios.get(`${API}/components`).then((r) => r.data).catch(() => []),
      axios.get(`${API}/methods`).then((r) => r.data).catch(() => []),
      axios.get(`${API}/examples`).then((r) => r.data).catch(() => []),
    ]).then(([c, m, e]) => {
      if (cancelled) return;
      setComponents(c);
      setMethods(m);
      setExamples(e);
      setLoaded(true);
    });
    return () => { cancelled = true; };
  }, [open, loaded]);

  // Close on Escape is handled by cmdk internally. We also add Esc to backdrop.
  useEffect(() => {
    if (!open) return;
    const onKey = (e) => {
      if (e.key === "Escape") onOpenChange(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onOpenChange]);

  const go = (path) => {
    onOpenChange(false);
    setSearch("");
    // Use a small delay so the palette close animation has a frame,
    // then navigate + scroll-to anchor if present.
    setTimeout(() => {
      navigate(path);
      if (path.includes("#")) {
        const id = path.split("#")[1];
        setTimeout(() => {
          const el = document.getElementById(id);
          if (el) {
            const top = el.getBoundingClientRect().top + window.scrollY - 88;
            window.scrollTo({ top, behavior: "smooth" });
          }
        }, 120);
      }
    }, 60);
  };

  if (!open) return null;

  return (
    <div
      data-testid="search-palette"
      role="dialog"
      aria-modal="true"
      onMouseDown={(e) => {
        // click on backdrop only
        if (e.target === e.currentTarget) onOpenChange(false);
      }}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 100,
        background: "rgba(0,0,0,0.7)",
        backdropFilter: "blur(8px)",
        WebkitBackdropFilter: "blur(8px)",
        display: "flex",
        alignItems: "flex-start",
        justifyContent: "center",
        paddingTop: "12vh",
      }}
    >
      <div
        style={{
          width: "min(600px, calc(100vw - 24px))",
          maxHeight: "70vh",
          background: "var(--bg-elevated)",
          border: "1px solid var(--border-strong)",
          borderRadius: 12,
          overflow: "hidden",
          display: "flex",
          flexDirection: "column",
          boxShadow: "0 30px 80px rgba(0,0,0,0.5)",
        }}
      >
        <Command
          label="Search SpaceUI"
          shouldFilter={true}
          loop
          className="spaceui-cmd"
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              padding: "14px 16px",
              borderBottom: "1px solid var(--border)",
            }}
          >
            <Search size={15} color="var(--text-dim)" />
            <Command.Input
              data-testid="search-input"
              autoFocus
              value={search}
              onValueChange={setSearch}
              placeholder="Search components, methods, examples…"
              style={{
                flex: 1,
                background: "transparent",
                border: "none",
                outline: "none",
                color: "var(--text)",
                fontSize: "0.9375rem",
                fontFamily: "var(--font-body)",
              }}
            />
            <KeyHint text="Esc" />
          </div>

          <Command.List
            style={{
              overflowY: "auto",
              padding: "6px 6px 10px",
              maxHeight: "calc(70vh - 60px)",
            }}
          >
            <Command.Empty
              style={{
                padding: "32px 20px",
                textAlign: "center",
                color: "var(--text-muted)",
                fontSize: "0.8125rem",
                fontFamily: "var(--font-mono)",
              }}
            >
              {loaded ? "Nothing found." : "Loading…"}
            </Command.Empty>

            {components.length > 0 && (
              <Command.Group heading={<GroupLabel>Components</GroupLabel>}>
                {components.map((c) => (
                  <Row
                    key={`c-${c.id}`}
                    testId={`search-item-${c.id}`}
                    icon={<Box size={14} />}
                    value={`component ${c.name} ${c.description} ${c.id}`}
                    onSelect={() => go(`/components#${c.id}`)}
                    title={c.name}
                    subtitle={c.description}
                  />
                ))}
              </Command.Group>
            )}

            {methods.length > 0 && (
              <Command.Group heading={<GroupLabel>Methods</GroupLabel>}>
                {methods.map((m) => (
                  <Row
                    key={`m-${m.id}`}
                    testId={`search-item-${m.id}`}
                    icon={<Hash size={14} />}
                    value={`method ${m.signature} ${m.description} ${m.id}`}
                    onSelect={() => go(`/reference#${m.id}`)}
                    title={m.signature}
                    subtitle={m.description}
                    mono
                  />
                ))}
              </Command.Group>
            )}

            {examples.length > 0 && (
              <Command.Group heading={<GroupLabel>Examples</GroupLabel>}>
                {examples.map((e) => (
                  <Row
                    key={`e-${e.id}`}
                    testId={`search-item-${e.id}`}
                    icon={<Code2 size={14} />}
                    value={`example ${e.name} ${e.description} ${e.id}`}
                    onSelect={() => go(`/examples#${e.id}`)}
                    title={e.name}
                    subtitle={e.description}
                  />
                ))}
              </Command.Group>
            )}
          </Command.List>
        </Command>
      </div>

      <style>{`
        .spaceui-cmd [cmdk-group-heading] {
          padding: 10px 12px 4px;
        }
        .spaceui-cmd [cmdk-item] {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 10px 12px;
          border-radius: 8px;
          cursor: pointer;
          color: var(--text-dim);
          border-left: 2px solid transparent;
          transition: background 120ms ease-out, color 120ms ease-out,
                      border-color 120ms ease-out;
        }
        .spaceui-cmd [cmdk-item][data-selected="true"] {
          background: rgba(255,255,255,0.06);
          color: var(--text);
          border-left-color: rgba(255,255,255,0.7);
        }
      `}</style>
    </div>
  );
}

function GroupLabel({ children }) {
  return (
    <span
      style={{
        color: "var(--text-muted)",
        fontFamily: "var(--font-mono)",
        fontSize: "0.6875rem",
        letterSpacing: "0.2em",
        textTransform: "uppercase",
      }}
    >
      {children}
    </span>
  );
}

function Row({ icon, title, subtitle, onSelect, value, testId, mono }) {
  return (
    <Command.Item value={value} onSelect={onSelect} data-testid={testId}>
      <span style={{ color: "var(--text-muted)", flexShrink: 0 }}>{icon}</span>
      <span
        style={{
          display: "flex",
          flexDirection: "column",
          minWidth: 0,
          flex: 1,
        }}
      >
        <span
          style={{
            color: "var(--text)",
            fontSize: mono ? "0.8125rem" : "0.875rem",
            fontFamily: mono ? "var(--font-mono)" : "var(--font-body)",
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
          }}
        >
          {title}
        </span>
        <span
          style={{
            color: "var(--text-muted)",
            fontSize: "0.75rem",
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
          }}
        >
          {subtitle}
        </span>
      </span>
    </Command.Item>
  );
}

function KeyHint({ text }) {
  return (
    <span
      style={{
        padding: "2px 6px",
        borderRadius: 4,
        border: "1px solid var(--border)",
        color: "var(--text-muted)",
        fontSize: "0.6875rem",
        fontFamily: "var(--font-mono)",
      }}
    >
      {text}
    </span>
  );
}
