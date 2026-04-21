import DocLayout from "@/components/DocLayout";
import DocSidebar from "@/components/DocSidebar";
import CodeBlock from "@/components/CodeBlock";

// GitHub raw URL — stable public CDN accessible from Roblox
const GITHUB_RAW = "https://raw.githubusercontent.com/lowserzeditexe-lab/SpaceUI/main/backend/spaceui";
const LOADSTRING = `loadstring(game:HttpGet("${GITHUB_RAW}/spaceui.lua"))()`;

const FIRST_WINDOW = `local SpaceUI = loadstring(game:HttpGet(
    "${GITHUB_RAW}/spaceui.lua"
))()

local Window = SpaceUI:CreateWindow({
    Title    = "My Script",
    SubTitle = "v1.0",
})

local Main = Window:AddTab({ Name = "Main" })

Main:AddButton({
    Name     = "Say hi",
    Callback = function()
        SpaceUI:Notify({ Title = "Hi", Duration = 2 })
    end,
})

Main:AddToggle({
    Name     = "Enable",
    Default  = false,
    Callback = function(v) print("toggle:", v) end,
})

Main:AddSlider({
    Name    = "Speed",
    Min     = 0,
    Max     = 100,
    Default = 50,
    Suffix  = "%",
})`;

const CONFIG_SNIPPET = `local Window = SpaceUI:CreateWindow({
    Title        = "My Script",
    ConfigFolder = "MyScript",
})

local Main = Window:AddTab({ Name = "Main" })

Main:AddToggle({
    Name    = "Enable",
    Default = false,
    Flag    = "enabled",          -- persisted under this key
    Callback = function(v) end,
})

-- On script start, rehydrate from disk:
Window:LoadConfig()

-- And auto-save on every change:
Window:SetAutoSave(true)

-- Or save manually:
-- Window:SaveConfig()`;

const TOGGLE_KEY = `local Window = SpaceUI:CreateWindow({
    Title     = "My Script",
    ToggleKey = Enum.KeyCode.Insert,   -- default is RightShift
})

-- Or toggle programmatically:
-- Window:Toggle()`;

const sections = [
  { id: "install",     label: "Installation" },
  { id: "first",       label: "Your first window" },
  { id: "config",      label: "Config system" },
  { id: "toggle-key",  label: "Toggle key" },
  { id: "parenting",   label: "Parenting & executor compat" },
];

export default function GettingStarted() {
  return (
    <DocLayout
      sidebar={<DocSidebar sections={sections} />}
      hero={
        <div className="mb-14" data-testid="gs-hero">
          <span
            className="badge"
            style={{
              color: "var(--text-muted)",
              fontFamily: "var(--font-mono)",
              letterSpacing: "0.2em",
              fontSize: "0.6875rem",
              textTransform: "uppercase",
            }}
          >
            <span className="dot" />
            Getting Started
          </span>
          <h1
            className="font-heading mt-5"
            data-testid="gs-title"
            style={{
              fontSize: "clamp(2.25rem, 5vw, 3.5rem)",
              fontWeight: 500,
              letterSpacing: "-0.035em",
              lineHeight: 1.05,
            }}
          >
            Install SpaceUI <br className="hidden sm:block" />
            in under 10 seconds.
          </h1>
          <p
            className="mt-5 max-w-xl"
            style={{ color: "var(--text-dim)", fontSize: "1rem", lineHeight: 1.6 }}
          >
            A minimalist Roblox UI kit. Paste one line and you&apos;re done.
          </p>
        </div>
      }
    >
      <Section id="install" title="1. Installation">
        <p style={pStyle}>
          SpaceUI is a single file. Load it with <code style={inlineCode}>loadstring</code>:
        </p>
        <CodeBlock code={LOADSTRING} testId="gs-install-code" label="lua · loadstring" />
        <p style={noteStyle}>
          The returned table has <code style={inlineCode}>CreateWindow</code>,{" "}
          <code style={inlineCode}>Notify</code>, and <code style={inlineCode}>Version</code>.
        </p>
      </Section>

      <Section id="first" title="2. Your first window">
        <p style={pStyle}>
          Create a window, add a tab, then add some components. Everything chains through
          method calls.
        </p>
        <CodeBlock code={FIRST_WINDOW} testId="gs-first-code" label="lua" />
        <p style={noteStyle}>
          Press <code style={inlineCode}>RightShift</code> to toggle the UI on and off.
        </p>
      </Section>

      <Section id="config" title="3. Config system">
        <p style={pStyle}>
          Any component with a <code style={inlineCode}>Flag</code> is persisted. Call{" "}
          <code style={inlineCode}>:SaveConfig()</code> and <code style={inlineCode}>:LoadConfig()</code>{" "}
          whenever you want — or let SpaceUI auto-save on every change.
        </p>
        <CodeBlock code={CONFIG_SNIPPET} testId="gs-config-code" label="lua" />
        <p style={noteStyle}>
          Configs are written to{" "}
          <code style={inlineCode}>SpaceUI/&lt;ConfigFolder&gt;/config.json</code>. When the
          executor has no filesystem, SpaceUI falls back to an in-memory store and logs a warning.
        </p>
      </Section>

      <Section id="toggle-key" title="4. Toggle key">
        <p style={pStyle}>
          The default is <code style={inlineCode}>Enum.KeyCode.RightShift</code>. Override it per window:
        </p>
        <CodeBlock code={TOGGLE_KEY} testId="gs-togglekey-code" label="lua" />
        <p style={noteStyle}>
          Typing inside a <code style={inlineCode}>TextBox</code> never triggers the toggle.
        </p>
      </Section>

      <Section id="parenting" title="5. Parenting & executor compat">
        <ul style={{ ...pStyle, listStyle: "none", padding: 0 }}>
          {[
            <>Prefers <code style={inlineCode}>gethui()</code> if your executor exposes it.</>,
            <>Falls back to <code style={inlineCode}>CoreGui</code> when available.</>,
            <>Falls back to <code style={inlineCode}>LocalPlayer.PlayerGui</code> otherwise.</>,
          ].map((t, i) => (
            <li
              key={i}
              style={{
                display: "flex",
                alignItems: "flex-start",
                gap: 10,
                padding: "6px 0",
              }}
            >
              <span
                style={{
                  width: 5,
                  height: 5,
                  borderRadius: "50%",
                  background: "var(--text)",
                  marginTop: 9,
                  flexShrink: 0,
                }}
              />
              <span>{t}</span>
            </li>
          ))}
        </ul>
        <p style={noteStyle}>
          Multiple windows are supported — each drags independently, and
          notifications stack in a shared top-right holder.
        </p>
      </Section>
    </DocLayout>
  );
}

function Section({ id, title, children }) {
  return (
    <section
      id={id}
      data-testid={`gs-section-${id}`}
      style={{
        paddingTop: 32,
        paddingBottom: 40,
        borderBottom: "1px solid var(--border)",
      }}
    >
      <h2
        className="font-heading"
        style={{
          fontSize: "1.625rem",
          fontWeight: 500,
          letterSpacing: "-0.02em",
          marginBottom: 20,
        }}
      >
        {title}
      </h2>
      {children}
    </section>
  );
}

const pStyle = {
  color: "var(--text-dim)",
  fontSize: "0.9375rem",
  lineHeight: 1.7,
  marginBottom: 20,
};

const noteStyle = {
  color: "var(--text-muted)",
  fontSize: "0.8125rem",
  lineHeight: 1.6,
  marginTop: 16,
};

const inlineCode = {
  fontFamily: "var(--font-mono)",
  fontSize: "0.8125em",
  padding: "1px 6px",
  borderRadius: 4,
  background: "rgba(255,255,255,0.06)",
  color: "var(--text)",
};
