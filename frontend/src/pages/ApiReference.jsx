import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import DocLayout from "@/components/DocLayout";
import DocSidebar from "@/components/DocSidebar";
import CodeBlock from "@/components/CodeBlock";
import PropsTable from "@/components/PropsTable";

const API = `${process.env.REACT_APP_BACKEND_URL || ""}/api`;

export default function ApiReference() {
  const [methods, setMethods] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    axios
      .get(`${API}/methods`)
      .then((r) => !cancelled && setMethods(r.data))
      .catch((e) => !cancelled && setError(e.message));
    return () => { cancelled = true; };
  }, []);

  const sections = useMemo(
    () =>
      methods.map((m) => ({
        id: m.id,
        label: m.signature.split("(")[0].split(" ").slice(-1)[0],
        group: m.group,
      })),
    [methods],
  );

  return (
    <DocLayout
      sidebar={<DocSidebar sections={sections} title="Reference" />}
      hero={
        <div className="mb-12" data-testid="api-hero">
          <span className="badge">
            <span className="dot" />
            API Reference
          </span>
          <h1
            className="font-heading mt-5"
            data-testid="api-title"
            style={{
              fontSize: "clamp(2.25rem, 5vw, 3.5rem)",
              fontWeight: 500,
              letterSpacing: "-0.035em",
              lineHeight: 1.05,
            }}
          >
            Every method, <br className="hidden sm:block" />
            every option.
          </h1>
          <p
            className="mt-5 max-w-xl"
            style={{ color: "var(--text-dim)", fontSize: "1rem", lineHeight: 1.6 }}
          >
            One method, one block. Signature, options, returns, and an
            example snippet.
          </p>
        </div>
      }
    >
      {error && (
        <p
          data-testid="api-error"
          style={{ color: "var(--text-muted)", fontFamily: "var(--font-mono)" }}
        >
          failed to load methods: {error}
        </p>
      )}
      {methods.map((m) => (
        <section
          key={m.id}
          id={m.id}
          data-testid={`method-${m.id}`}
          style={{
            paddingTop: 40,
            paddingBottom: 40,
            borderBottom: "1px solid var(--border)",
          }}
        >
          <p
            style={{
              color: "var(--text-muted)",
              fontFamily: "var(--font-mono)",
              letterSpacing: "0.12em",
              textTransform: "uppercase",
              fontSize: "0.6875rem",
            }}
          >
            {m.group}
          </p>

          <div
            className="mt-3"
            style={{
              fontFamily: "var(--font-mono)",
              fontSize: "0.9375rem",
              padding: "10px 14px",
              borderRadius: 8,
              border: "1px solid var(--border)",
              background: "rgba(255,255,255,0.02)",
              color: "var(--text)",
              overflowX: "auto",
            }}
          >
            {m.signature}
          </div>

          <p
            className="mt-4 max-w-2xl"
            style={{ color: "var(--text-dim)", fontSize: "0.9375rem", lineHeight: 1.7 }}
          >
            {m.description}
          </p>

          {m.options && m.options.length > 0 && (
            <div className="mt-6">
              <MiniLabel text="Options" />
              <PropsTable rows={m.options} testId={`method-${m.id}-props`} />
            </div>
          )}

          {m.returns && (
            <div className="mt-6">
              <MiniLabel text="Returns" />
              <p
                style={{
                  color: "var(--text-dim)",
                  fontFamily: "var(--font-mono)",
                  fontSize: "0.8125rem",
                }}
              >
                {m.returns}
              </p>
            </div>
          )}

          {m.example && (
            <div className="mt-6">
              <MiniLabel text="Example" />
              <CodeBlock
                code={m.example}
                testId={`method-${m.id}-example`}
                label="lua"
              />
            </div>
          )}
        </section>
      ))}
    </DocLayout>
  );
}

function MiniLabel({ text }) {
  return (
    <p
      className="mb-3"
      style={{
        color: "var(--text-muted)",
        fontFamily: "var(--font-mono)",
        fontSize: "0.6875rem",
        letterSpacing: "0.2em",
        textTransform: "uppercase",
      }}
    >
      {text}
    </p>
  );
}
