
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Sidebar from './components/layout/Sidebar';
import Dashboard from './pages/Dashboard'; // This should be here
import Visitors from './pages/Visitors';
import Vehicles from './pages/Vehicles';
import Billing from './pages/Billing';

function App() {
  return (
    <Router>
      <div className="flex bg-slate-50 min-h-screen">
        <Sidebar />
        <main className="flex-1 ml-64">
          <div className="h-16 bg-white border-b flex items-center px-8 justify-between shadow-sm">
            <h2 className="font-semibold text-slate-700">Admin Portal</h2>
            <div className="text-sm text-slate-500">Society: Grandeur Apartments</div>
          </div>

          <Routes>
            <Route path="/" element={<Dashboard />} /> {/* Real Component */}
            <Route path="/visitors" element={<Visitors />} />
            <Route path="/vehicles" element={<Vehicles />} />
            <Route path="/billing" element={<Billing />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;