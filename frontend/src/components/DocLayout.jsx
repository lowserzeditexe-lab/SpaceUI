import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

/**
 * Wrapper for documentation pages.
 * Provides the page scaffold, a subtle radial glow, and a 3-column
 * layout slot (sidebar | content). Pages compose their own inner layout.
 */
export default function DocLayout({ children, sidebar, hero }) {
  return (
    <div className="page" data-testid="doc-layout">
      <Navbar />
      <main className="page-main relative">
        <div
          aria-hidden="true"
          style={{
            position: "absolute",
            inset: 0,
            background:
              "radial-gradient(ellipse 800px 500px at 50% 0%, rgba(255,255,255,0.035), transparent 70%)",
            pointerEvents: "none",
            zIndex: 0,
          }}
        />
        <div
          className="container-narrow relative"
          style={{
            zIndex: 1,
            paddingTop: "5rem",
            paddingBottom: "8rem",
            maxWidth: 1200,
          }}
        >
          {hero}
          <div
            className="flex gap-10"
            style={{ alignItems: "flex-start" }}
          >
            {sidebar}
            <div
              className="flex-1 min-w-0"
              style={{ maxWidth: sidebar ? 820 : "100%" }}
            >
              {children}
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
