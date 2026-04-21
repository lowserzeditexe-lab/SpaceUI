import "@/App.css";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "@/pages/Home";
import Stub from "@/pages/Stub";

function App() {
  return (
    <div className="App">
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route
            path="/getting-started"
            element={<Stub name="Getting Started" />}
          />
          <Route path="/components" element={<Stub name="Components" />} />
          <Route path="/examples" element={<Stub name="Examples" />} />
          <Route path="/api" element={<Stub name="API Reference" />} />
          <Route path="*" element={<Stub name="Not Found" />} />
        </Routes>
      </BrowserRouter>
    </div>
  );
}

export default App;
