import "@/App.css";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "@/pages/Home";
import Stub from "@/pages/Stub";
import GettingStarted from "@/pages/GettingStarted";
import Components from "@/pages/Components";
import Examples from "@/pages/Examples";
import ApiReference from "@/pages/ApiReference";

function App() {
  return (
    <div className="App">
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/getting-started" element={<GettingStarted />} />
          <Route path="/components" element={<Components />} />
          <Route path="/examples" element={<Examples />} />
          <Route path="/reference" element={<ApiReference />} />
          <Route path="*" element={<Stub name="Not Found" />} />
        </Routes>
      </BrowserRouter>
    </div>
  );
}

export default App;
