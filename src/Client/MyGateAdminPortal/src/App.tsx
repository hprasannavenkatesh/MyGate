// src/App.tsx
import React, { useEffect, useState } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  useNavigate,
  Navigate,
} from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext"; // Import Context
import Sidebar from "./components/layout/Sidebar";
import Dashboard from "./pages/Dashboard";
import Visitors from "./pages/Visitors";
import Vehicles from "./pages/Vehicles";
import Billing from "./pages/Billing";
import Notices from "./pages/Notices";
import Amenities from "./pages/Amenities";
import MasterData from "./pages/MasterData";
import AssignMember from "./pages/AssignMember";
import Login from "./pages/Login";
import SuperAdminSocietyPicker from "./pages/SuperAdminSocietyPicker";

function AppContent() {
  // 1. Get userList from Context (This works for both TEST_USERS and API data)
  //const { currentUser, setCurrentUser, loading, userList, switchContext } = useAuth();
  const { currentUser, loading, isInitializing, userList, switchContext } =
    useAuth();
  const navigate = useNavigate(); // ← ADD
  // If not logged in, show login page
  const [hasToken, setHasToken] = useState(false);

  // Check if token exists
  useEffect(() => {
    const token = localStorage.getItem("auth_token");
    setHasToken(!!token);
  }, [isInitializing]); // Re-check after context switches

  // FIX: Wait for AuthContext to finish reading the token
  if (isInitializing) {
    return (
      <div className="p-8 text-center text-slate-500">Initializing App...</div>
    );
  }
  if (!hasToken) {
    return (
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="*" element={<Login />} />
      </Routes>
    );
  }

  // 🚀 NEW: SUPERADMIN ROUTING LOGIC
  // If they are a SuperAdmin but haven't picked a society yet, force them to the Picker
  if (currentUser?.isSuperAdmin && !currentUser.societyId) {
    return (
      <Routes>
        <Route path="/picker" element={<SuperAdminSocietyPicker />} />
        <Route path="*" element={<Navigate to="/picker" replace />} />
      </Routes>
    );
  }

  // 2. Handle Dropdown Change
  const handleUserChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedId = e.target.value;

    // Find the user object from the Context list
    // (The Context automatically handles whether this list is Hardcoded or from API)
    const userToSwitch = userList.find((u) => u.id === selectedId);

    if (userToSwitch) {
      await switchContext(userToSwitch);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem("auth_token");
    setHasToken(false);
    navigate("/login");
  };

  return (
    <div className="flex bg-slate-50 min-h-screen">
      <Sidebar />
      <main className="flex-1 ml-64">
        {/* --- Header --- */}
        <div className="h-16 bg-white border-b flex items-center px-8 justify-between shadow-sm">
          <h2 className="font-semibold text-slate-700">Admin Portal</h2>

          <div className="flex items-center gap-4">
            {loading && (
              <span className="text-xs text-blue-500 animate-pulse">
                Switching Context...
              </span>
            )}

            {/* SUPERADMIN: Show Switch Society Button instead of Dropdown */}
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
                  value={currentUser?.id || ""}
                  onChange={handleUserChange}
                  className="border border-slate-300 rounded px-3 py-1 text-sm bg-slate-50 focus:outline-none focus:border-blue-500"
                >
                  {/* 
                 NOTE: We map over 'userList' from AuthContext. 
                 Currently, this uses TEST_USERS.
                 In the future, when you uncomment the API fetch in AuthContext.tsx,
                 this dropdown will automatically populate with Database users.
              */}
                  {userList.map((user) => (
                    <option key={user.id} value={user.id}>
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

        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/visitors" element={<Visitors />} />
          <Route path="/notices" element={<Notices />} />
          <Route path="/amenities" element={<Amenities />} />
          <Route path="/master" element={<MasterData />} />
          <Route path="/vehicles" element={<Vehicles />} />
          <Route path="/billing" element={<Billing />} />
          <Route path="/assign-member" element={<AssignMember />} />
        </Routes>
      </main>
    </div>
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
