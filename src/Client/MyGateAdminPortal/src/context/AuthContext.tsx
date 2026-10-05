// src/context/AuthContext.tsx
import { createContext, useContext, useState, useEffect } from "react";
import type { ReactNode } from "react";
import { parseJwt } from "../utils/jwt";
import { getMySocieties } from "../api/tenant";
import apiClient from '../api/client';
import {API_URLS} from "../api/apiConfig";

interface User {
   uniqueKey: string; // ADD THIS
  id: string;
  name: string;
  flat: string;
  societyId: string;
  flatId: string;
  role: string;
  memberType: string; // Added to track the raw member type
  token?: string;
  isSuperAdmin: boolean;
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

// Helper: Map String MemberType to Integer for .NET Backend
const mapMemberTypeToInt = (memberType: string): string => {
  const lower = memberType?.toLowerCase();
  if (lower === "committeemember" || lower === "admin") return "4";
  if (lower === "owner") return "0";
  if (lower === "tenant") return "1";
  if (lower === "familyofowner") return "2";
  if (lower === "familyoftenant") return "3";
  return "1"; // Default fallback
};

// Helper: Normalize backend roles to frontend UI roles
const normalizeRole = (role: string): string => {
  const lower = role?.toLowerCase();
  if (lower === "superadmin") return "SuperAdmin";
  if (lower === "admin" || lower === "committeemember") return "Admin"; // Treat CommitteeMember as Admin
  if (lower === "guard") return "Guard";
  return "Resident"; // Default fallback
};

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);
  const [isInitializing, setIsInitializing] = useState(true);
  const [userList, setUserList] = useState<User[]>([]);

  // 1. INITIAL LOAD: Read Token from Storage & Fetch Societies
  useEffect(() => {
    const initializeAuth = async () => {
      const token = localStorage.getItem("auth_token");

      if (token) {
        const decoded = parseJwt(token);
        if (decoded) {
          const userId = decoded.sub || "";
          const role = decoded.role || decoded.Role || "";

          // 🚀 NEW: Detect SuperAdmin by their fixed GUID (since Basic Token has no Role)
          //const SUPERADMIN_ID = "a1b2c3d4-e5f6-7890-1234-567890abcdef";
          //const isSuperAdmin =
          //  role === "SuperAdmin" || userId === SUPERADMIN_ID;
          const isSuperAdmin = role === "SuperAdmin";

           // We must calculate the memberType first to use it in the key
          const initialMemberType = isSuperAdmin
            ? "SuperAdmin"
            : normalizeRole(role) === "Admin"
              ? "CommitteeMember"
              : "Owner";

          // Set current user from token immediately
          const initialUser = {
            uniqueKey: `${userId}_${decoded.FlatId || "no-flat"}`, // ADD THIS
            id: userId,
            name: decoded.FullName || "Unknown",
            isSuperAdmin: isSuperAdmin,
            flat: decoded.FlatId ? `Flat ${decoded.FlatId}` : "No Context",
            societyId: decoded.SocietyId || "",
            flatId: decoded.FlatId || "",
           // role: role, //decoded.role || decoded.Role || "",
           role: normalizeRole(role), // Normalize role for frontend
            //memberType: decoded.role === "Admin" ? "CommitteeMember" : "Owner",
           /* memberType: isSuperAdmin
              ? "SuperAdmin"
              : role === "Admin"
                ? "CommitteeMember"
                : "Owner",*/
                 memberType: initialMemberType, // Use the variable we made
            token: token,
          };
          setCurrentUser(initialUser);

          // NORMAL ADMIN/RESIDENT LOGIC: Fetch their specific societies
          if (!isSuperAdmin) {
            // Fetch real societies from TenantService
            try {
              const societies = await getMySocieties(userId);
              const mappedUsers = societies.map((s) => ({
                 uniqueKey: `${userId}_${s.flatId}_${s.memberType}`, // FIX: Include memberType
                id: userId,
                name: `${s.societyName} - ${s.blockName} - ${s.flatNumber} (${s.memberType})`,
                flat: `${s.blockName} - ${s.flatNumber}`,
                societyId: s.societyId,
                flatId: s.flatId,
                role: s.memberType === "CommitteeMember" ? "Admin" : "Resident",
                memberType: s.memberType,
                isSuperAdmin: false,
              }));
              setUserList(mappedUsers);

              // SAFETY CHECK: If the token is missing SocietyId, auto-switch context!
              if (!initialUser.societyId && mappedUsers.length > 0) {
                console.log(
                  "Token missing SocietyId. Auto-switching context...",
                );
                await switchContext(mappedUsers[0]); // Force a fat token generation
              }
            } catch (err) {
              console.error("Failed to fetch societies on init:", err);
            }
          }
        }
      }
      setIsInitializing(false);
    };

    initializeAuth();
  }, []);

  // 2. SWITCH CONTEXT: Call API to get Fat Token
  const switchContext = async (userToSwitchTo: User) => {
    setLoading(true);
    try {
     
      const response = await apiClient.post(
        `${API_URLS.IDENTITY}/auth/select-context`,
        {
          userId: userToSwitchTo.id,
          societyId: userToSwitchTo.societyId,
          flatId:  userToSwitchTo.flatId || "00000000-0000-0000-0000-000000000000", // Fake FlatId for SA
          memberType: userToSwitchTo.isSuperAdmin
            ? "0"
            : mapMemberTypeToInt(userToSwitchTo.memberType),
          role: userToSwitchTo.isSuperAdmin ? "SuperAdmin" : "",
        },
      );

      //if (response.ok) {
       // const data = await response.json();
       const data = response.data;
        const newToken = data.token;

        localStorage.setItem("auth_token", newToken);

        const decoded = parseJwt(newToken);
        const newRole = decoded.role || decoded.Role || "";
        const newUser = {
           uniqueKey: `${decoded.sub || ""}_${decoded.FlatId || "no-flat"}_${userToSwitchTo.memberType}`, // FIX: Include memberType
          id: decoded.sub || "",
          name: decoded.FullName || "Unknown",
          flat: userToSwitchTo.flat,
          societyId: decoded.SocietyId || "",
          flatId: decoded.FlatId || "",
         // role: newRole,
         role: normalizeRole(newRole), // Normalize role for frontend
          memberType: userToSwitchTo.memberType,
          isSuperAdmin: newRole === "SuperAdmin",
          token: newToken,
        };

        setCurrentUser(newUser);
        console.log(
          "✅ Context Switched! SocietyId:",
          newUser.societyId,
          "Role:",
          newUser.role,
        );
     // } else {
      //  const errorData = await response.json();
      //  throw new Error(errorData.message || "Failed to switch context");
     // }
    } catch (error: any) {
      console.error("Context Switch Error:", error);
      alert(`Failed to switch context: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        setCurrentUser,
        loading,
        isInitializing,
        userList,
        switchContext,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used within AuthProvider");
  return context;
};
