/* eslint-disable react/prop-types */

/**
 * ComponentPreview — static HTML/CSS recreation of every SpaceUI
 * component, designed to look indistinguishable from the Roblox render.
 * Strictly monochrome. Renders based on `id`.
 */

const rowStyle = {
  position: "relative",
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "0 12px",
  height: 38,
  borderRadius: 8,
  background: "rgba(28,28,28,0.6)",
  border: "1px solid rgba(255,255,255,0.12)",
};

const labelStyle = {
  color: "#FAFAFA",
  fontSize: 13,
  fontFamily: "var(--font-body)",
  fontWeight: 500,
};

const valueStyle = {
  color: "#A1A1A1",
  fontFamily: "var(--font-mono)",
  fontSize: 11,
};

function PreviewShell({ children, height = 180 }) {
  return (
    <div
      className="glass relative overflow-hidden"
      style={{
        borderRadius: 12,
        padding: 16,
        minHeight: height,
        background: "rgba(17,17,17,0.55)",
        border: "1px solid rgba(255,255,255,0.1)",
      }}
    >
      {children}
    </div>
  );
}

// ───────────────────────────── component renderers ─────────────────────────────

function WindowPreview() {
  return (
    <PreviewShell height={230}>
      <div
        style={{
          width: "100%",
          maxWidth: 420,
          margin: "0 auto",
          background: "#0a0a0a",
          border: "1px solid rgba(255,255,255,0.14)",
          borderRadius: 12,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            height: 36,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "0 14px",
            borderBottom: "1px solid rgba(255,255,255,0.08)",
          }}
        >
          <div style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
            <span style={{ ...labelStyle, fontFamily: "var(--font-heading)", fontSize: 14 }}>
              My Script
            </span>
            <span style={{ color: "#6B6B6B", fontSize: 10, fontFamily: "var(--font-body)" }}>
              v1.0
            </span>
          </div>
          <span style={{ color: "#A1A1A1", fontSize: 16, lineHeight: 1 }}>×</span>
        </div>
        <div style={{ display: "flex", height: 130 }}>
          <div
            style={{
              width: 110,
              borderRight: "1px solid rgba(255,255,255,0.08)",
              padding: 10,
              display: "flex",
              flexDirection: "column",
              gap: 4,
            }}
          >
            <TabPill label="Main" active />
            <TabPill label="Config" />
          </div>
          <div style={{ flex: 1, padding: 12, display: "flex", flexDirection: "column", gap: 6 }}>
            <div style={{ ...rowStyle, height: 30 }}>
              <span style={{ ...labelStyle, fontSize: 12 }}>Enable</span>
              <TogglePill on />
            </div>
            <div style={{ ...rowStyle, height: 30 }}>
              <span style={{ ...labelStyle, fontSize: 12 }}>Run</span>
              <PillButton />
            </div>
          </div>
        </div>
      </div>
    </PreviewShell>
  );
}

function TabPill({ label, active }) {
  return (
    <div
      style={{
        position: "relative",
        height: 26,
        padding: "0 10px",
        display: "flex",
        alignItems: "center",
        borderRadius: 7,
        background: active ? "rgba(255,255,255,0.05)" : "transparent",
        color: active ? "#FAFAFA" : "#A1A1A1",
        fontSize: 12,
        fontFamily: "var(--font-body)",
        fontWeight: 500,
      }}
    >
      {active && (
        <span
          style={{
            position: "absolute",
            left: 0,
            top: "50%",
            transform: "translateY(-50%)",
            width: 2,
            height: 14,
            background: "#fff",
            borderRadius: 1,
          }}
        />
      )}
      {label}
    </div>
  );
}

function TabPreview() {
  return (
    <PreviewShell>
      <div
        style={{
          width: 160,
          padding: 12,
          borderRight: "1px solid rgba(255,255,255,0.08)",
          display: "flex",
          flexDirection: "column",
          gap: 4,
        }}
      >
        <TabPill label="Combat" active />
        <TabPill label="Movement" />
        <TabPill label="Visuals" />
        <TabPill label="Config" />
      </div>
    </PreviewShell>
  );
}

function SectionPreview() {
  return (
    <PreviewShell>
      <div style={{ padding: "4px 0" }}>
        <p
          style={{
            ...labelStyle,
            fontFamily: "var(--font-heading)",
            fontSize: 13,
            marginBottom: 6,
          }}
        >
          ESP
        </p>
        <div
          style={{
            height: 1,
            background: "rgba(255,255,255,0.12)",
            marginBottom: 14,
          }}
        />
        <div style={rowStyle}>
          <span style={labelStyle}>Enable ESP</span>
          <TogglePill />
        </div>
      </div>
    </PreviewShell>
  );
}

function PillButton({ text = "Run" }) {
  return (
    <div
      style={{
        background: "#fff",
        color: "#000",
        height: 24,
        padding: "0 14px",
        display: "flex",
        alignItems: "center",
        borderRadius: 8,
        fontSize: 12,
        fontWeight: 500,
      }}
    >
      {text}
    </div>
  );
}

function ButtonPreview() {
  return (
    <PreviewShell>
      <div style={{ ...rowStyle, marginBottom: 10 }}>
        <span style={labelStyle}>Reset character</span>
        <PillButton />
      </div>
      <div style={{ ...rowStyle, height: 48, alignItems: "flex-start", flexDirection: "column", justifyContent: "center", paddingTop: 8, paddingBottom: 8 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%" }}>
          <span style={labelStyle}>Teleport to base</span>
          <PillButton />
        </div>
        <span style={{ color: "#6B6B6B", fontSize: 11, marginTop: 2 }}>
          Returns to your last safe position
        </span>
      </div>
    </PreviewShell>
  );
}

function TogglePill({ on = false }) {
  return (
    <div
      style={{
        width: 34,
        height: 18,
        borderRadius: 9,
        background: on ? "#fff" : "#232323",
        border: "1px solid rgba(255,255,255,0.14)",
        position: "relative",
        transition: "background 200ms",
      }}
    >
      <div
        style={{
          width: 14,
          height: 14,
          borderRadius: 7,
          background: on ? "#000" : "#A1A1A1",
          position: "absolute",
          top: 1,
          left: on ? 18 : 2,
          transition: "left 200ms, background 200ms",
        }}
      />
    </div>
  );
}

function TogglePreview() {
  return (
    <PreviewShell>
      <div style={{ ...rowStyle, marginBottom: 10 }}>
        <span style={labelStyle}>Enable ESP</span>
        <TogglePill on />
      </div>
      <div style={rowStyle}>
        <span style={labelStyle}>Notifications</span>
        <TogglePill />
      </div>
    </PreviewShell>
  );
}

function SliderPreview() {
  return (
    <PreviewShell>
      <div style={{ ...rowStyle, height: 54, flexDirection: "column", alignItems: "stretch", justifyContent: "center", padding: "8px 12px" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span style={labelStyle}>Max distance</span>
          <span style={valueStyle}>600 studs</span>
        </div>
        <div
          style={{
            marginTop: 10,
            height: 4,
            borderRadius: 2,
            background: "#282828",
            position: "relative",
          }}
        >
          <div
            style={{
              position: "absolute",
              inset: 0,
              width: "60%",
              background: "#fff",
              borderRadius: 2,
            }}
          />
          <div
            style={{
              position: "absolute",
              left: "60%",
              top: "50%",
              transform: "translate(-50%, -50%)",
              width: 10,
              height: 10,
              borderRadius: 5,
              background: "#fff",
            }}
          />
        </div>
      </div>
    </PreviewShell>
  );
}

function DropdownPreview() {
  const pill = (
    <div
      style={{
        width: 140,
        height: 24,
        borderRadius: 6,
        background: "#232323",
        border: "1px solid rgba(255,255,255,0.14)",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "0 10px",
        color: "#FAFAFA",
        fontSize: 12,
      }}
    >
      Closest
      <span style={{ color: "#A1A1A1", fontSize: 10 }}>▾</span>
    </div>
  );
  return (
    <PreviewShell height={220}>
      <div style={{ ...rowStyle, marginBottom: 16 }}>
        <span style={labelStyle}>Mode</span>
        {pill}
      </div>
      <div style={{ position: "relative" }}>
        <div style={rowStyle}>
          <span style={labelStyle}>Priority</span>
          {pill}
        </div>
        <div
          style={{
            position: "absolute",
            right: 0,
            top: 42,
            width: 180,
            background: "#161616",
            border: "1px solid rgba(255,255,255,0.14)",
            borderRadius: 8,
            padding: 6,
            boxShadow: "0 10px 30px rgba(0,0,0,0.5)",
          }}
        >
          {["Closest", "LowHealth", "Mouse"].map((o, i) => (
            <div
              key={o}
              style={{
                padding: "6px 10px",
                borderRadius: 6,
                color: i === 0 ? "#FAFAFA" : "#A1A1A1",
                background: i === 0 ? "rgba(255,255,255,0.08)" : "transparent",
                fontSize: 12,
                marginBottom: 2,
              }}
            >
              {o}
            </div>
          ))}
        </div>
      </div>
    </PreviewShell>
  );
}

function InputPreview() {
  return (
    <PreviewShell>
      <div style={rowStyle}>
        <span style={labelStyle}>Display name</span>
        <div
          style={{
            width: 160,
            height: 24,
            borderRadius: 6,
            background: "#232323",
            border: "1px solid rgba(255,255,255,0.14)",
            display: "flex",
            alignItems: "center",
            padding: "0 10px",
            color: "#6B6B6B",
            fontSize: 12,
          }}
        >
          type here…
        </div>
      </div>
    </PreviewShell>
  );
}

function KeybindPreview() {
  return (
    <PreviewShell>
      <div style={{ ...rowStyle, marginBottom: 10 }}>
        <span style={labelStyle}>Panic key</span>
        <div
          style={{
            width: 70,
            height: 24,
            borderRadius: 6,
            background: "#232323",
            border: "1px solid rgba(255,255,255,0.14)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#FAFAFA",
            fontFamily: "var(--font-mono)",
            fontSize: 11,
          }}
        >
          P
        </div>
      </div>
      <div style={rowStyle}>
        <span style={labelStyle}>Aim key</span>
        <div
          style={{
            width: 70,
            height: 24,
            borderRadius: 6,
            background: "#232323",
            border: "1px solid rgba(255,255,255,0.14)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#FAFAFA",
            fontFamily: "var(--font-mono)",
            fontSize: 11,
          }}
        >
          MB2
        </div>
      </div>
    </PreviewShell>
  );
}

function ColorPickerPreview() {
  return (
    <PreviewShell height={230}>
      <div style={{ ...rowStyle, marginBottom: 14 }}>
        <span style={labelStyle}>ESP color</span>
        <div
          style={{
            width: 34,
            height: 22,
            borderRadius: 6,
            background: "#fff",
            border: "1px solid rgba(255,255,255,0.4)",
          }}
        />
      </div>
      <div
        style={{
          width: 200,
          marginLeft: "auto",
          marginRight: 0,
          padding: 10,
          background: "#161616",
          border: "1px solid rgba(255,255,255,0.14)",
          borderRadius: 8,
          boxShadow: "0 10px 30px rgba(0,0,0,0.5)",
        }}
      >
        <div
          style={{
            width: "100%",
            height: 80,
            borderRadius: 6,
            background:
              "linear-gradient(to top, #000, transparent), linear-gradient(to right, #fff, #fff)",
            position: "relative",
          }}
        />
        <div
          style={{
            marginTop: 8,
            height: 10,
            borderRadius: 3,
            background:
              "linear-gradient(90deg, #ff0000,#ffff00,#00ff00,#00ffff,#0000ff,#ff00ff,#ff0000)",
          }}
        />
        <div
          style={{
            marginTop: 6,
            fontFamily: "var(--font-mono)",
            fontSize: 11,
            color: "#A1A1A1",
          }}
        >
          #FFFFFF
        </div>
      </div>
    </PreviewShell>
  );
}

function LabelPreview() {
  return (
    <PreviewShell height={100}>
      <p
        style={{
          color: "#A1A1A1",
          fontSize: 12,
          fontFamily: "var(--font-body)",
        }}
      >
        Press RightShift to toggle the UI.
      </p>
    </PreviewShell>
  );
}

function ParagraphPreview() {
  return (
    <PreviewShell>
      <div
        style={{
          padding: 14,
          borderRadius: 8,
          background: "rgba(255,255,255,0.02)",
          border: "1px solid rgba(255,255,255,0.12)",
        }}
      >
        <p
          style={{
            ...labelStyle,
            fontFamily: "var(--font-heading)",
            marginBottom: 6,
          }}
        >
          Warning
        </p>
        <p style={{ color: "#A1A1A1", fontSize: 12, lineHeight: 1.6 }}>
          This script is open source. Read it before running.
        </p>
      </div>
    </PreviewShell>
  );
}

function DividerPreview() {
  return (
    <PreviewShell height={100}>
      <div
        style={{ padding: "24px 0", display: "flex", flexDirection: "column", gap: 20 }}
      >
        <span style={{ color: "#6B6B6B", fontSize: 11, fontFamily: "var(--font-mono)" }}>
          Section A
        </span>
        <div style={{ height: 1, background: "rgba(255,255,255,0.12)" }} />
        <span style={{ color: "#6B6B6B", fontSize: 11, fontFamily: "var(--font-mono)" }}>
          Section B
        </span>
      </div>
    </PreviewShell>
  );
}

function NotificationPreview() {
  return (
    <PreviewShell height={160}>
      <div
        style={{
          width: 280,
          marginLeft: "auto",
          padding: "12px 14px",
          background: "#161616",
          border: "1px solid rgba(255,255,255,0.12)",
          borderRadius: 10,
          position: "relative",
          overflow: "hidden",
        }}
      >
        <p style={{ ...labelStyle, fontFamily: "var(--font-heading)" }}>Loaded</p>
        <p style={{ color: "#A1A1A1", fontSize: 12, marginTop: 4 }}>
          SpaceUI is ready
        </p>
        <div
          style={{
            position: "absolute",
            bottom: 0,
            left: 0,
            width: "55%",
            height: 1,
            background: "rgba(255,255,255,0.6)",
          }}
        />
      </div>
    </PreviewShell>
  );
}

const renderers = {
  window: WindowPreview,
  tab: TabPreview,
  section: SectionPreview,
  button: ButtonPreview,
  toggle: TogglePreview,
  slider: SliderPreview,
  dropdown: DropdownPreview,
  input: InputPreview,
  keybind: KeybindPreview,
  colorpicker: ColorPickerPreview,
  label: LabelPreview,
  paragraph: ParagraphPreview,
  divider: DividerPreview,
  notification: NotificationPreview,
};

export default function ComponentPreview({ id }) {
  const R = renderers[id];
  if (!R) {
    return (
      <div
        data-testid={`preview-fallback-${id}`}
        style={{
          height: 140,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "var(--text-muted)",
          fontFamily: "var(--font-mono)",
          fontSize: 12,
          border: "1px solid var(--border)",
          borderRadius: 12,
        }}
      >
        preview unavailable
      </div>
    );
  }
  return (
    <div data-testid={`preview-${id}`}>
      <R />
    </div>
  );
}
