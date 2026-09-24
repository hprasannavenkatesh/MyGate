// src/context/AuthContext.tsx
import { createContext, useContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import { parseJwt } from '../utils/jwt';

interface User {
  id: string;
  name: string;
  flat: string;
  societyId: string;
  flatId: string;
  role: string; // Changed from memberType to role
  token?: string;
}

interface AuthContextType {
  currentUser: User | null;
  setCurrentUser: (user: User | null) => void;
  loading: boolean;
  isInitializing: boolean;
  userList: User[];
  switchContext: (user: User) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// NOTE: We still use TEST_USERS just to populate the Dropdown UI 
// until we build a "GetMySocieties" endpoint in TenantService.
const TEST_USERS: User[] = [
  { 
    id: 'ddd44444-4444-4444-4444-444444444444', 
    name: 'Super Admin', 
    flat: 'OFFICE', 
    societyId: 'aaa11111-1111-1111-1111-111111111111', 
    flatId: 'fdd11111-1111-1111-1111-111111111111',
    role: 'Admin' 
  },
  { 
    id: 'eee55555-5555-5555-5555-555555555555', 
    name: 'John Doe (B-204)', 
    flat: 'B-204', 
    societyId: 'aaa11111-1111-1111-1111-111111111111', 
    flatId: 'fbb11111-1111-1111-1111-111111111111', 
    role: 'Resident' 
  },
  { 
    id: 'fff66666-6666-667666-6666-666666666666', 
    name: 'Alice Smith (A-101)', 
    flat: 'A-101', 
    societyId: 'aaa11111-1111-1111-1111-111111111111', 
    flatId: 'faa11111-1111-1111-1111-111111111111', 
    role: 'Resident' 
  },
];

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);
  const [isInitializing, setIsInitializing] = useState(true);
  const [userList, _setUserList] = useState<User[]>(TEST_USERS); 

  // 1. INITIAL LOAD: Read Token from Storage
  useEffect(() => {
    const token = localStorage.getItem('auth_token');
    
    if (token) {
      const decoded = parseJwt(token);
        console.log("📝 DECODED TOKEN (Initial Load):", decoded); 
      if (decoded) {
        // TRUST THE TOKEN CLAIMS DIRECTLY (No more hardcoded fallbacks)
        setCurrentUser({
          id: decoded.sub || "",
          name: decoded.FullName || "Unknown",
          flat: decoded.FlatId ? `Flat ${decoded.FlatId}` : "No Context", // UI display logic
          societyId: decoded.SocietyId || "",
          flatId: decoded.FlatId || "",
          role: decoded.role ||decoded.Role || "",
          token: token
        });
      }
    }
    setIsInitializing(false); 
  }, []);

  // 2. SWITCH CONTEXT: Call API to get Fat Token
  const switchContext = async (userToSwitchTo: User) => {
    setLoading(true);
    try {
      const currentToken = localStorage.getItem('auth_token');

      const response = await fetch('http://localhost:5103/api/auth/select-context', {
        method:'POST',
        headers: {
          'Authorization': `Bearer ${currentToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          userId: userToSwitchTo.id,
          societyId: userToSwitchTo.societyId,
          flatId: userToSwitchTo.flatId,
          memberType: userToSwitchTo.role === "Admin" ? "4" : "1" // Map Role back to Enum int
        })
      });

      if (response.ok) {
        // Backend returns the token string directly
             // FIX: Parse the JSON wrapper first
        const data = await response.json(); 
        const newToken = data.token; // Extract the actual string
         // Save New Token
        localStorage.setItem('auth_token', newToken);

        // Re-Parse the new token to update state instantly (No page reload!)
        const decoded = parseJwt(newToken);
        console.log("📝 DECODED TOKEN (Switch Context):", decoded); // <--- ADD THIS
        setCurrentUser({
          id: decoded.sub || "",
          name: decoded.FullName || "Unknown",
          flat: userToSwitchTo.flat, // Keep UI flat name from dropdown
          societyId: decoded.SocietyId || "",
          flatId: decoded.FlatId || "",
          role: decoded.role || "",
          token: newToken
        });

      } else {
        throw new Error('Failed to switch context');
      }
    } catch (error) {
      console.error('Context Switch Error:', error);
      alert('Failed to switch context. Is IdentityService running?');
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthContext.Provider value={{ currentUser, setCurrentUser, loading, isInitializing, userList, switchContext }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};