export default function PropsTable({ rows, testId = "props-table" }) {
  if (!rows || rows.length === 0) {
    return (
      <p
        data-testid={`${testId}-empty`}
        className="text-sm"
        style={{ color: "var(--text-muted)", fontFamily: "var(--font-mono)" }}
      >
        — no options —
      </p>
    );
  }

  const hasDefault = rows.some((r) => r.default !== undefined);
  const hasRequired = rows.some((r) => r.required !== undefined);

  return (
    <div
      data-testid={testId}
      className="w-full overflow-x-auto"
      style={{
        border: "1px solid var(--border)",
        borderRadius: 10,
      }}
    >
      <table
        className="w-full"
        style={{
          borderCollapse: "collapse",
          fontSize: "0.8125rem",
        }}
      >
        <thead>
          <tr
            style={{
              color: "var(--text-muted)",
              fontFamily: "var(--font-mono)",
              letterSpacing: "0.08em",
              textTransform: "uppercase",
              fontSize: "0.6875rem",
            }}
          >
            <th style={th}>Prop</th>
            <th style={th}>Type</th>
            {hasDefault && <th style={th}>Default</th>}
            {hasRequired && <th style={th}>Req</th>}
            <th style={{ ...th, width: "45%" }}>Description</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr
              key={i}
              style={{
                borderTop: "1px solid var(--border)",
                color: "var(--text)",
              }}
            >
              <td style={{ ...td, fontFamily: "var(--font-mono)", color: "var(--text)" }}>
                {r.name}
              </td>
              <td
                style={{
                  ...td,
                  fontFamily: "var(--font-mono)",
                  color: "var(--text-dim)",
                  whiteSpace: "nowrap",
                }}
              >
                {r.type}
              </td>
              {hasDefault && (
                <td
                  style={{
                    ...td,
                    fontFamily: "var(--font-mono)",
                    color: "var(--text-muted)",
                    whiteSpace: "nowrap",
                  }}
                >
                  {r.default ?? "—"}
                </td>
              )}
              {hasRequired && (
                <td style={{ ...td, color: "var(--text-dim)" }}>
                  {r.required ? "yes" : "—"}
                </td>
              )}
              <td style={{ ...td, color: "var(--text-dim)" }}>{r.desc}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

const th = {
  textAlign: "left",
  padding: "10px 14px",
  fontWeight: 500,
  borderBottom: "1px solid var(--border)",
};

const td = {
  padding: "10px 14px",
  verticalAlign: "top",
  lineHeight: 1.5,
};
