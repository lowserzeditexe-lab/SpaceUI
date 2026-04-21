import { useState } from "react";
import { Copy, Check } from "lucide-react";

export default function CodeBlock({ code, label = "lua", testId = "code-block" }) {
  const [copied, setCopied] = useState(false);

  const onCopy = async () => {
    // Flip UI state immediately so feedback is independent of the
    // clipboard API — it can reject silently in sandboxed iframes.
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);

    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(code);
        return;
      }
    } catch (_e) {
      // fall through to execCommand fallback
    }

    // Fallback for non-secure / restricted contexts (preview iframes).
    try {
      const ta = document.createElement("textarea");
      ta.value = code;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.top = "-1000px";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
    } catch (_e) {
      // swallow — UI state already flipped
    }
  };

  return (
    <div
      data-testid={testId}
      className="codeblock w-full"
    >
      <div
        className="flex items-center justify-between px-4 py-2.5"
        style={{ borderBottom: "1px solid var(--border)" }}
      >
        <span
          className="text-xs"
          style={{
            color: "var(--text-muted)",
            fontFamily: "var(--font-mono)",
            letterSpacing: "0.06em",
            textTransform: "uppercase",
          }}
        >
          {label}
        </span>
        <button
          data-testid={`${testId}-copy`}
          onClick={onCopy}
          aria-label="Copy code"
          className="inline-flex items-center gap-1.5 text-xs rounded-md px-2 py-1 transition-colors"
          style={{
            color: copied ? "var(--text)" : "var(--text-dim)",
            border: "1px solid var(--border)",
            background: "rgba(255,255,255,0.02)",
          }}
        >
          {copied ? (
            <>
              <Check size={13} />
              <span data-testid={`${testId}-copied`}>Copied</span>
            </>
          ) : (
            <>
              <Copy size={13} />
              <span>Copy</span>
            </>
          )}
        </button>
      </div>
      <pre
        className="px-4 py-4 overflow-x-auto"
        style={{
          margin: 0,
          fontFamily: "var(--font-mono)",
          fontSize: "0.8125rem",
          lineHeight: 1.6,
          color: "var(--text)",
        }}
      >
        <code data-testid={`${testId}-code`}>{code}</code>
      </pre>
    </div>
  );
}
