// src/App.tsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext'; // Import Context
import Sidebar from './components/layout/Sidebar';
import Dashboard from './pages/Dashboard';
import Visitors from './pages/Visitors';
import Vehicles from './pages/Vehicles';
import Billing from './pages/Billing';

function AppContent() {
  // 1. Get userList from Context (This works for both TEST_USERS and API data)
  //const { currentUser, setCurrentUser, loading, userList, switchContext } = useAuth();
   const { currentUser, loading, isInitializing,userList, switchContext } = useAuth();
  // FIX: Wait for AuthContext to finish reading the token
  if (isInitializing) {
    return <div className="p-8 text-center text-slate-500">Initializing App...</div>;
  }

  // 2. Handle Dropdown Change
  const handleUserChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedId = e.target.value;

    // Find the user object from the Context list
    // (The Context automatically handles whether this list is Hardcoded or from API)
    const userToSwitch = userList.find(u => u.id === selectedId);

    if (userToSwitch) {
      await switchContext(userToSwitch);
    }
  };

  return (
    <div className="flex bg-slate-50 min-h-screen">
      <Sidebar />
      <main className="flex-1 ml-64">
        {/* --- Header --- */}
        <div className="h-16 bg-white border-b flex items-center px-8 justify-between shadow-sm">
          <h2 className="font-semibold text-slate-700">Admin Portal</h2>
          
          <div className="flex items-center gap-4">
            {loading && <span className="text-xs text-blue-500 animate-pulse">Switching Context...</span>}
            
            <div className="text-sm text-slate-500">Acting As:</div>
            
            <select 
              disabled={loading} 
              value={currentUser?.id || ''} 
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
          </div>
        </div>

        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/visitors" element={<Visitors />} />
          <Route path="/vehicles" element={<Vehicles />} />
          <Route path="/billing" element={<Billing />} />
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