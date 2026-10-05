// src/App.tsx
import React, { useEffect, useState } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  useNavigate,
  Navigate,
  Outlet,
} from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext";
import Sidebar from "./components/layout/Sidebar";
import Dashboard from "./pages/Dashboard";
import Visitors from "./pages/Visitors";
import Vehicles from "./pages/Vehicles";
import Billing from "./pages/Billing";
import Helpdesk from "./pages/Helpdesk";
import DailyHelp from "./pages/DailyHelp";
import Directory from "./pages/Directory";
import Notices from "./pages/Notices";
import Amenities from "./pages/Amenities";
import MasterData from "./pages/MasterData";
import AssignMember from "./pages/AssignMember";
import Login from "./pages/Login";
import SuperAdminSocietyPicker from "./pages/SuperAdminSocietyPicker";
import Guards from "./pages/Guards"; // ADD Import

// FIX #21: Wrapper for routes that require a logged-in user
const RequireAuth = () => {
  const { isInitializing, currentUser } = useAuth();
  const [hasToken, setHasToken] = useState(false);

  useEffect(() => {
    setHasToken(!!localStorage.getItem("auth_token"));
  }, [isInitializing, currentUser]);

  if (isInitializing) {
    return <div className="p-8 text-center text-slate-500">Initializing App...</div>;
  }

  if (!hasToken) {
    // Redirect to Login if no token
    return <Navigate to="/login" replace />;
  }

  // FIX #20: If SuperAdmin but no society selected, force to Picker
  if (currentUser?.isSuperAdmin && !currentUser.societyId) {
    return <Navigate to="/picker" replace />;
  }

  // If all checks pass, render the child routes
  return <Outlet />;
};

function AppContent() {
  const { currentUser, loading, userList, switchContext } = useAuth();
  const navigate = useNavigate();

  // Handle Dropdown Change
  const handleUserChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
    //const selectedId = e.target.value;
    //const userToSwitch = userList.find((u) => u.id === selectedId);
     const selectedKey = e.target.value;
     const userToSwitch = userList.find((u) => u.uniqueKey === selectedKey);
    if (userToSwitch) {
      await switchContext(userToSwitch);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem("auth_token");
    navigate("/login");
    window.location.reload(); // Force full reset on logout
  };

  return (
    <Routes>
      {/* Public Route */}
      <Route path="/login" element={<Login />} />

      {/* FIX #19: Single Unified Protected Route Structure */}
      <Route element={<RequireAuth />}>
        
        {/* SuperAdmin Picker Route (Only accessible if logged in) */}
        <Route path="/picker" element={<SuperAdminSocietyPicker />} />

        {/* Main Application Layout Wrapper */}
        <Route
          element={
            <div className="flex bg-slate-50 min-h-screen">
              <Sidebar />
              <main className="flex-1 ml-64">
                <div className="h-16 bg-white border-b flex items-center px-8 justify-between shadow-sm">
                  <h2 className="font-semibold text-slate-700">
                    {currentUser?.isSuperAdmin ? `🏠 ${currentUser.name}` : "Admin Portal"}
                  </h2>
                  <div className="flex items-center gap-4">
                    {loading && (
                      <span className="text-xs text-blue-500 animate-pulse">
                        Switching Context...
                      </span>
                    )}
                    {currentUser?.isSuperAdmin ? (
                      <button
                        onClick={() => navigate("/picker")}
                        className="text-sm text-blue-600 hover:text-blue-800 font-medium"
                      >
                        🏠 Switch Society
                      </button>
                    ) : (
                      <>
                        <div className="text-sm text-slate-500">Acting As:</div>
                        <select
                          disabled={loading}
                          //value={currentUser?.id || ""}
                          value={currentUser?.uniqueKey || ""} 
                          onChange={handleUserChange}
                          className="border border-slate-300 rounded px-3 py-1 text-sm bg-slate-50 focus:outline-none focus:border-blue-500"
                        >
                          {userList.map((user) => (
                           // <option key={user.id} value={user.id}>
                           //   {user.name}
                           // </option>
                             <option key={user.uniqueKey} value={user.uniqueKey}> {/* CHANGE: Use uniqueKey here */}
                                {user.name}
                              </option>
                          ))}
                        </select>
                      </>
                    )}
                    <button
                      onClick={handleLogout}
                      className="text-slate-400 hover:text-red-500 text-sm ml-2"
                      title="Logout"
                    >
                      Logout
                    </button>
                  </div>
                </div>
                <Outlet /> {/* Page content renders here */}
              </main>
            </div>
          }
        >
          {/* Nested Routes inside Main Layout */}
          <Route path="/" element={<Dashboard />} />
          <Route path="/visitors" element={<Visitors />} />
           <Route path="/guards" element={<Guards />} /> {/* ADD ROUTE */}
          <Route path="/notices" element={<Notices />} />
          <Route path="/amenities" element={<Amenities />} />
          <Route path="/master" element={<MasterData />} />
          <Route path="/helpdesk" element={<Helpdesk />} />
          <Route path="/daily-help" element={<DailyHelp />} />
          <Route path="/vehicles" element={<Vehicles />} />
          <Route path="/directory" element={<Directory />} />
          <Route path="/billing" element={<Billing />} />
          <Route path="/assign-member" element={<AssignMember />} />
        </Route>
      </Route>

      {/* Fallback redirect */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <AuthProvider>
      <Router>
        <AppContent />
      </Router>
    </AuthProvider>
  );
}

export default App;