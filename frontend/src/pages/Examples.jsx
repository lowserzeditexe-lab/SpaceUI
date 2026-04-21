import { useEffect, useState } from "react";
import axios from "axios";
import { Copy, Check, ChevronDown, ChevronUp } from "lucide-react";
import DocLayout from "@/components/DocLayout";
import CodeBlock from "@/components/CodeBlock";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL || "";
const API = `${BACKEND_URL}/api`;

export default function Examples() {
  const [data, setData] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    axios
      .get(`${API}/examples`)
      .then((r) => !cancelled && setData(r.data))
      .catch((e) => !cancelled && setError(e.message));
    return () => { cancelled = true; };
  }, []);

  return (
    <DocLayout
      hero={
        <div className="mb-12" data-testid="examples-hero">
          <span className="badge">
            <span className="dot" />
            {data.length} examples
          </span>
          <h1
            className="font-heading mt-5"
            data-testid="examples-title"
            style={{
              fontSize: "clamp(2.25rem, 5vw, 3.5rem)",
              fontWeight: 500,
              letterSpacing: "-0.035em",
              lineHeight: 1.05,
            }}
          >
            Examples
          </h1>
          <p
            className="mt-5 max-w-xl"
            style={{ color: "var(--text-dim)", fontSize: "1rem", lineHeight: 1.6 }}
          >
            Production-ready scripts built with SpaceUI. Copy, paste, adapt.
          </p>
        </div>
      }
    >
      {error && (
        <p
          data-testid="examples-error"
          style={{ color: "var(--text-muted)", fontFamily: "var(--font-mono)" }}
        >
          failed to load examples: {error}
        </p>
      )}
      <div className="flex flex-col gap-6">
        {data.map((ex) => (
          <ExampleCard key={ex.id} ex={ex} />
        ))}
      </div>
    </DocLayout>
  );
}

function ExampleCard({ ex }) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const copyScript = async () => {
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(ex.code);
        return;
      }
    } catch (_e) { /* fallthrough */ }
    try {
      const ta = document.createElement("textarea");
      ta.value = ex.code;
      ta.style.position = "fixed";
      ta.style.top = "-1000px";
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
    } catch (_e) { /* noop */ }
  };

  return (
    <article
      data-testid={`example-${ex.id}`}
      id={ex.id}
      className="card"
      style={{ padding: 24 }}
    >
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="flex items-center gap-2">
            <h2
              className="font-heading"
              style={{
                fontSize: "1.375rem",
                fontWeight: 500,
                letterSpacing: "-0.015em",
              }}
            >
              {ex.name}
            </h2>
            {ex.featured && (
              <span
                data-testid={`example-${ex.id}-featured`}
                style={{
                  padding: "2px 8px",
                  fontSize: "0.625rem",
                  fontFamily: "var(--font-mono)",
                  letterSpacing: "0.12em",
                  textTransform: "uppercase",
                  border: "1px solid var(--border-strong)",
                  borderRadius: 999,
                  color: "var(--text)",
                  background: "rgba(255,255,255,0.05)",
                }}
              >
                Featured
              </span>
            )}
          </div>
          <p
            className="mt-2 max-w-2xl"
            style={{ color: "var(--text-dim)", fontSize: "0.9375rem", lineHeight: 1.65 }}
          >
            {ex.description}
          </p>
          <p
            className="mt-3"
            style={{
              color: "var(--text-muted)",
              fontFamily: "var(--font-mono)",
              fontSize: "0.6875rem",
              letterSpacing: "0.12em",
              textTransform: "uppercase",
            }}
          >
            {ex.code.split("\n").length} lines
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            data-testid={`example-${ex.id}-copy`}
            onClick={copyScript}
            className="btn btn-ghost"
          >
            {copied ? (
              <>
                <Check size={14} />
                <span data-testid={`example-${ex.id}-copied`}>Copied</span>
              </>
            ) : (
              <>
                <Copy size={14} />
                Copy script
              </>
            )}
          </button>
          <button
            data-testid={`example-${ex.id}-toggle`}
            onClick={() => setOpen((o) => !o)}
            className="btn btn-primary"
          >
            {open ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            {open ? "Hide" : "View code"}
          </button>
        </div>
      </div>

      {open && (
        <div className="mt-6" data-testid={`example-${ex.id}-code`}>
          <CodeBlock
            code={ex.code}
            testId={`example-${ex.id}-block`}
            label={`lua · ${ex.id}`}
            maxHeight={520}
          />
        </div>
      )}

      <div className="mt-6" data-testid={`example-${ex.id}-oneliner`}>
        <p
          className="mb-2"
          style={{
            color: "var(--text-muted)",
            fontFamily: "var(--font-mono)",
            fontSize: "0.6875rem",
            letterSpacing: "0.2em",
            textTransform: "uppercase",
          }}
        >
          One-liner install
        </p>
        <CodeBlock
          code={`loadstring(game:HttpGet("${BACKEND_URL}/api/examples/${ex.id}.lua"))()`}
          testId={`example-${ex.id}-oneliner-block`}
          label={`lua · ${ex.id}.lua`}
        />
      </div>
    </article>
  );
}
