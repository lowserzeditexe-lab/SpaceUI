# SpaceUI — PRD

## Problem Statement
Build **SpaceUI** — a Roblox UI Kit library (`spaceui.lua`, loadstring-served by backend)
plus a Grok-inspired documentation website (strict black & white, space-themed).
Tech: FastAPI + React + MongoDB.

## Phases
- **Phase 1 (DONE · 2026-04-21)** — Website foundation + Grok design system.
- **Phase 2 (TODO)** — Implement the actual `spaceui.lua` library (Fluent API, Config System, components in Lua).
- **Phase 3 (TODO)** — Docs / Components / Examples / API pages (currently stubs).

## User Personas
- **Roblox developers** who want a beautiful, minimal UI kit with a one-line loadstring install.
- **Readers of the docs site** who want an elegant, fast, Grok-style browsing experience.

## Core Requirements (static)
- Strict monochrome palette. No color. No purple/blue/green.
- Typography: Space Grotesk (headings), Inter (body), JetBrains Mono (code).
- Space-themed hero (starfield, radial glow, grid overlay).
- Loadstring code block on home with working Copy button.
- `/api/health` returns `{status:"ok", service:"spaceui"}`.
- Lua library served via HTTP with `text/plain` + `Access-Control-Allow-Origin: *`.

## What's Implemented (Phase 1)
- Backend (`/app/backend/server.py`):
  - `GET /api/health` → `{status:"ok", service:"spaceui"}`
  - `GET /api/spaceui.lua` → placeholder Lua, `text/plain; charset=utf-8`, CORS `*`
  - `GET /spaceui.lua` (local only, blocked by K8s ingress externally)
  - `/api/docs` OpenAPI accessible
- Frontend:
  - `/` Home: navbar, hero (SpaceUI title + subtitle + badge), loadstring codeblock w/ copy button, CTAs, scroll indicator, features grid (Fluent API / Config System / Black & White), footer
  - `/getting-started`, `/components`, `/examples`, `/api` → reusable `<Stub name="…" />` with "Coming in Phase 3"
  - Components: Navbar, Footer, Starfield (canvas animation), CodeBlock
  - Global CSS with palette vars, Google Fonts imported

## Platform Constraint (important)
The K8s ingress routes only `/api/*` to the backend — all other paths go to the frontend.
Therefore the loadstring URL is:
`loadstring(game:HttpGet("<REACT_APP_BACKEND_URL>/api/spaceui.lua"))()`
This is slightly different from the original spec wording but is the only way to expose
the Lua file through the preview URL on this platform.

## Backlog
### P0 (Phase 2)
- Implement `spaceui.lua` with Fluent API builder (`Window`, `Tab`, `Section`, `Button`, `Toggle`, `Slider`, `Dropdown`, `Input`, `Keybind`, `Label`, `Paragraph`, `Notification`).
- Config System (persisted save/load of control states).
- Theming (monochrome only, draggable window, minimize, close).
- Replace backend placeholder with the full Lua string.

### P1 (Phase 3)
- `/getting-started` real content (install, first window, config, API skeleton).
- `/components` showcase with live examples + copyable snippets.
- `/examples` curated recipes.
- `/api` reference (auto-gen from Lua types if feasible).

### P2
- Dark/light toggle (site is dark only for brand).
- Search (cmdk palette).
- Version selector for the Lua library (served via `/api/spaceui@<ver>.lua`).
- Analytics for loadstring downloads.
