import "@/App.css";
import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "@/pages/Home";
import Stub from "@/pages/Stub";
import GettingStarted from "@/pages/GettingStarted";
import Components from "@/pages/Components";
import Examples from "@/pages/Examples";
import ApiReference from "@/pages/ApiReference";
import SearchPalette from "@/components/SearchPalette";

function AppShell() {
  const [searchOpen, setSearchOpen] = useState(false);

  useEffect(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setSearchOpen((s) => !s);
      }
    };
    window.addEventListener("keydown", onKey);
    // Let Navbar open the palette through a window-level event so we don't
    // need to prop-drill the setter through routes.
    const onOpen = () => setSearchOpen(true);
    window.addEventListener("spaceui:open-search", onOpen);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("spaceui:open-search", onOpen);
    };
  }, []);

  return (
    <>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/getting-started" element={<GettingStarted />} />
        <Route path="/components" element={<Components />} />
        <Route path="/examples" element={<Examples />} />
        <Route path="/reference" element={<ApiReference />} />
        <Route path="*" element={<Stub name="Not Found" />} />
      </Routes>
      <SearchPalette open={searchOpen} onOpenChange={setSearchOpen} />
    </>
  );
}

function App() {
  return (
    <div className="App">
      <BrowserRouter>
        <AppShell />
      </BrowserRouter>
    </div>
  );
}

export default App;
