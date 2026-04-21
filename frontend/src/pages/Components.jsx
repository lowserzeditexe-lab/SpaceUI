import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import DocLayout from "@/components/DocLayout";
import DocSidebar from "@/components/DocSidebar";
import CodeBlock from "@/components/CodeBlock";
import ComponentPreview from "@/components/ComponentPreview";
import PropsTable from "@/components/PropsTable";

const API = `${process.env.REACT_APP_BACKEND_URL || ""}/api`;

export default function Components() {
  const [data, setData] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    axios
      .get(`${API}/components`)
      .then((r) => !cancelled && setData(r.data))
      .catch((e) => !cancelled && setError(e.message));
    return () => { cancelled = true; };
  }, []);

  const sections = useMemo(
    () => data.map((c) => ({ id: c.id, label: c.name, group: c.group })),
    [data],
  );

  return (
    <DocLayout
      sidebar={<DocSidebar sections={sections} title="Components" />}
      hero={
        <div className="mb-12" data-testid="components-hero">
          <span className="badge">
            <span className="dot" />
            {data.length} components
          </span>
          <h1
            className="font-heading mt-5"
            data-testid="components-title"
            style={{
              fontSize: "clamp(2.25rem, 5vw, 3.5rem)",
              fontWeight: 500,
              letterSpacing: "-0.035em",
              lineHeight: 1.05,
            }}
          >
            Components
          </h1>
          <p
            className="mt-5 max-w-xl"
            style={{ color: "var(--text-dim)", fontSize: "1rem", lineHeight: 1.6 }}
          >
            Every control in SpaceUI, with a live preview and a copy-ready
            Lua snippet. Pure monochrome.
          </p>
        </div>
      }
    >
      {error && (
        <p
          data-testid="components-error"
          style={{ color: "var(--text-muted)", fontFamily: "var(--font-mono)" }}
        >
          failed to load components: {error}
        </p>
      )}
      {data.map((c) => (
        <section
          key={c.id}
          id={c.id}
          data-testid={`component-${c.id}`}
          style={{
            paddingTop: 48,
            paddingBottom: 48,
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
            {c.group}
          </p>
          <h2
            className="font-heading mt-2"
            style={{
              fontSize: "1.75rem",
              fontWeight: 500,
              letterSpacing: "-0.02em",
              lineHeight: 1.1,
            }}
          >
            {c.name}
          </h2>
          <p
            className="mt-3 max-w-2xl"
            style={{ color: "var(--text-dim)", fontSize: "0.9375rem", lineHeight: 1.7 }}
          >
            {c.description}
          </p>

          <div className="mt-8">
            <Label text="Preview" />
            <ComponentPreview id={c.id} />
          </div>

          <div className="mt-8">
            <Label text="Usage" />
            <CodeBlock
              code={c.snippet}
              testId={`snippet-${c.id}`}
              label="lua"
            />
          </div>

          {c.props && c.props.length > 0 && (
            <div className="mt-8">
              <Label text="Props" />
              <PropsTable rows={c.props} testId={`props-${c.id}`} />
            </div>
          )}
        </section>
      ))}
    </DocLayout>
  );
}

function Label({ text }) {
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
