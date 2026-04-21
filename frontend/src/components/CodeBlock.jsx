import { useState } from "react";
import { Copy, Check } from "lucide-react";

// Minimal Lua tokenizer — monochrome highlighting.
const KEYWORDS = new Set([
  "local", "function", "end", "if", "then", "else", "elseif", "for", "while",
  "do", "return", "nil", "true", "false", "in", "and", "or", "not",
  "repeat", "until", "break",
]);

function tokenize(code) {
  const out = [];
  let i = 0;
  const push = (t, v) => out.push({ t, v });
  while (i < code.length) {
    const c = code[i];

    // Comments
    if (c === "-" && code[i + 1] === "-") {
      if (code[i + 2] === "[" && code[i + 3] === "[") {
        const end = code.indexOf("]]", i + 4);
        const e = end === -1 ? code.length : end + 2;
        push("c", code.slice(i, e));
        i = e; continue;
      }
      const nl = code.indexOf("\n", i);
      const e = nl === -1 ? code.length : nl;
      push("c", code.slice(i, e));
      i = e; continue;
    }

    // Long string [[ ... ]]
    if (c === "[" && code[i + 1] === "[") {
      const end = code.indexOf("]]", i + 2);
      const e = end === -1 ? code.length : end + 2;
      push("s", code.slice(i, e));
      i = e; continue;
    }

    // Strings
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < code.length && code[j] !== c) {
        if (code[j] === "\\") j += 2; else j += 1;
      }
      push("s", code.slice(i, Math.min(j + 1, code.length)));
      i = Math.min(j + 1, code.length);
      continue;
    }

    // Numbers
    if (/[0-9]/.test(c)) {
      let j = i;
      while (j < code.length && /[0-9.]/.test(code[j])) j += 1;
      push("n", code.slice(i, j));
      i = j; continue;
    }

    // Identifiers / keywords
    if (/[A-Za-z_]/.test(c)) {
      let j = i;
      while (j < code.length && /[A-Za-z0-9_]/.test(code[j])) j += 1;
      const word = code.slice(i, j);
      push(KEYWORDS.has(word) ? "k" : "i", word);
      i = j; continue;
    }

    // Whitespace (preserve)
    if (c === " " || c === "\t" || c === "\n") {
      let j = i;
      while (j < code.length && /[ \t\n]/.test(code[j])) j += 1;
      push("w", code.slice(i, j));
      i = j; continue;
    }

    // Punctuation / operator
    push("p", c);
    i += 1;
  }
  return out;
}

const tokenStyle = {
  k: { color: "#ffffff", fontWeight: 600 },
  s: { color: "#c9c9c9" },
  c: { color: "#6b6b6b", fontStyle: "italic" },
  n: { color: "#e5e5e5" },
  i: { color: "#d0d0d0" },
  p: { color: "#9b9b9b" },
  w: {},
};

export default function CodeBlock({
  code,
  label = "lua",
  language = "lua",
  testId = "code-block",
  maxHeight,
}) {
  const [copied, setCopied] = useState(false);

  const onCopy = async () => {
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(code);
        return;
      }
    } catch (_e) {
      /* fall through */
    }
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
    } catch (_e) { /* noop */ }
  };

  const tokens = language === "lua" ? tokenize(code) : null;

  return (
    <div data-testid={testId} className="codeblock w-full">
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
        className="px-4 py-4 overflow-auto"
        style={{
          margin: 0,
          fontFamily: "var(--font-mono)",
          fontSize: "0.8125rem",
          lineHeight: 1.65,
          color: "var(--text)",
          maxHeight: maxHeight || "none",
        }}
      >
        <code data-testid={`${testId}-code`}>
          {tokens
            ? tokens.map((tk, idx) => (
                <span key={idx} style={tokenStyle[tk.t] || {}}>
                  {tk.v}
                </span>
              ))
            : code}
        </code>
      </pre>
    </div>
  );
}
