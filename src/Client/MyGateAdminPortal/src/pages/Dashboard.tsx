// src/pages/Dashboard.tsx
import { useState, useEffect, useRef } from "react";
import { useAuth } from "../context/AuthContext";
import { getSocietyVisitors } from "../api/visitor";
import { getSocietyInvoices } from "../api/billing";
import { getSocietyTickets } from "../api/helpdesk";
import * as signalR from "@microsoft/signalr";
import { Users, Receipt, Ticket, Loader2 } from "lucide-react";

// CRITICAL FIX: Prevent StrictMode from creating duplicate connections
let isSignalRInitializing = false;

const Dashboard = () => {
  const { currentUser } = useAuth();
  const [emergencyAlert, setEmergencyAlert] = useState<string | null>(null);

  // Live Data States
  const [visitorCount, setVisitorCount] = useState<number | null>(null);
  const [pendingDuesCount, setPendingDuesCount] = useState<number | null>(null);
  const [openTicketsCount, setOpenTicketsCount] = useState<number | null>(null);
  const [isLoadingStats, setIsLoadingStats] = useState(true);

  const connectionRef = useRef<signalR.HubConnection | null>(null);

  // 1. Fetch Context-Aware Data
  useEffect(() => {
    if (!currentUser?.societyId) return;

    const fetchSocietyData = async () => {
      setIsLoadingStats(true);
      try {
        const [visitors, invoices, tickets] = await Promise.all([
          getSocietyVisitors(currentUser.societyId).catch(() => []),
          getSocietyInvoices(currentUser.societyId).catch(() => []),
          getSocietyTickets(currentUser.societyId).catch(() => []),
        ]);

        setVisitorCount(visitors.length);
        setPendingDuesCount(invoices.filter((i) => i.status === 0).length);
        setOpenTicketsCount(tickets.filter((t) => t.status === 0).length);
      } catch (error) {
        console.error("Failed to load dashboard stats", error);
      } finally {
        setIsLoadingStats(false);
      }
    };

    fetchSocietyData();
  }, [currentUser?.societyId]);

  // 2. SignalR Emergency Listener
  useEffect(() => {
    if (!currentUser?.societyId) return;

    // CRITICAL: Fetch the token to authenticate the Gateway connection
    const token = localStorage.getItem("auth_token");
    if (!token) {
      console.error("❌ No auth token found for SignalR connection.");
      isSignalRInitializing = false; // Reset on failure
      return;
    }

    console.log(
      `🔌 Connecting to SignalR for Society: ${currentUser.societyId}`,
    );

    const connection = new signalR.HubConnectionBuilder()
      .withUrl("http://localhost:5116/api/hubs/emergency", {
        skipNegotiation: true,
        transport: signalR.HttpTransportType.WebSockets,
        accessTokenFactory: () => token,
      }) // RealtimeGateway Port
      .withAutomaticReconnect()
      .configureLogging(signalR.LogLevel.Information)
      .build();

    connectionRef.current = connection;
    // Listen for the exact method name invoked by the gateway
    connection.on("ReceiveEmergencyAlert", (message) => {
      console.log("🚨 EMERGENCY ALERT RECEIVED IN REACT:", message);
      const description =
        message?.description || "🚨 EMERGENCY ALERT TRIGGERED IN YOUR SOCIETY!";
      setEmergencyAlert(description);
    });

    connection
      .start()
      .then(() => {
        console.log("✅ SignalR Connected to Realtime$ateway");
        return connection.invoke("JoinSocietyGroup", currentUser.societyId);
      })
      .then(() => {
        console.log(`✅ Joined Society Group: ${currentUser.societyId}`);
      })
      .catch((err) => {
        console.error("❌ SignalR Connection Error:", err);
        isSignalRInitializing = false; // Reset on failure so it can retry
      });
    // Cleanup on unmount
    return () => {
      if (connectionRef.current) {
        connectionRef.current.stop();
        connectionRef.current = null;
      }
      isSignalRInitializing = false; // Reset when component unmounts
    };
  }, [currentUser?.societyId]);

  // 3. Role-Based UI Text Helpers
  const getRoleLabel = () => {
    if (currentUser?.isSuperAdmin) return "SuperAdmin";
    if (currentUser?.role === "Admin") return "Society Admin";
    return "Resident";
  };

  const getScopeLabel = () => {
    if (currentUser?.isSuperAdmin) return "Viewing data for selected society";
    if (currentUser?.role === "Admin")
      return "Viewing all data for your society";
    return "Viewing data for your flat only";
  };

  return (
    <div className="p-8">
      {/* Emergency Alert Overlay */}
      {emergencyAlert && (
        <div className="fixed inset-0 bg-red-900/90 flex items-center justify-center z-50 p-8">
          <div className="bg-white p-8 rounded-lg shadow-2xl text-center max-w-md">
            <div className="text-5xl mb-4">🚨</div>
            <h2 className="text-2xl font-bold text-red-700 mb-4">
              EMERGENCY ALERT
            </h2>
            <p className="text-lg text-slate-800 mb-6">{emergencyAlert}</p>
            <button
              onClick={() => setEmergencyAlert(null)}
              className="bg-red-600 text-white px-6 py-3 rounded-md font-bold hover:bg-red-700"
            >
              ACKNOWLEDGE
            </button>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-800">Dashboard</h1>
        <p className="text-slate-500 mt-1">
          Logged in as{" "}
          <span className="font-semibold text-indigo-600">
            {getRoleLabel()}
          </span>{" "}
          • {getScopeLabel()}
        </p>
      </div>

      {/* Stats Grid */}
      {isLoadingStats ? (
        <div className="flex justify-center items-center h-64">
          <Loader2 className="animate-spin text-slate-400 w-8 h-8" />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Active Visitors Card */}
          <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200 flex items-center gap-4">
            <div className="p-3 bg-blue-50 rounded-full">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500">
                Society Visitors
              </h3>
              <p className="text-2xl font-bold text-slate-800">
                {visitorCount ?? "--"}
              </p>
            </div>
          </div>

          {/* Pending Dues Card */}
          <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200 flex items-center gap-4">
            <div className="p-3 bg-red-50 rounded-full">
              <Receipt className="w-6 h-6 text-red-600" />
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500">
                Pending Dues
              </h3>
              <p className="text-2xl font-bold text-slate-800">
                {pendingDuesCount ?? "--"}
              </p>
            </div>
          </div>

          {/* Open Tickets Card */}
          <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200 flex items-center gap-4">
            <div className="p-3 bg-yellow-50 rounded-full">
              <Ticket className="w-6 h-6 text-yellow-600" />
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-500">
                Open Tickets
              </h3>
              <p className="text-2xl font-bold text-slate-800">
                {openTicketsCount ?? "--"}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;
