// src/pages/Visitors.tsx
import React, { useState, useEffect } from "react";
import { Plus, LogOut, Clock } from "lucide-react";
import {
  getMyVisitors,
  preApproveVisitor,
  markVisitorExit,
  type VisitorDto,
  type PreApproveVisitorCommand,
} from "../api/visitor";
import { useAuth } from '../context/AuthContext'; 

// TODO: Replace this with the actual ID of the logged-in user from your Context
//const MOCK_INVITER_ID = "00000000-0000-0000-0000-000000000000";

const Visitors = () => {
   // Get the current user from Context
  const { currentUser } = useAuth();

  const [visitors, setVisitors] = useState<VisitorDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // State for the "Add Visitor" Modal
  const [isModalOpen, setIsModalOpen] = useState(false);
    const [newVisitor, setNewVisitor] = useState<PreApproveVisitorCommand>({
    visitorName: '',
    visitorMobile: '',
    vehicleNumber: '',
    purpose: '',
    //inviterId: currentUser?.id || '',
    invitedByUserId: currentUser?.id || '', // Pre-fill
    societyId: currentUser?.societyId || '', // Pre-fill
    flatId: currentUser?.flatId || '',         // Pre-fill
    //expectedArrival: new Date().toISOString()
     expectedDate: new Date().toISOString().split('T')[0], // "2024-05-20"
  });

  const fetchVisitors = async () => {
       // console.log("1. fetchVisitors was called");
    //console.log("2. Current User is:", currentUser);
      if (!currentUser?.id) {
         //console.log("3. No user ID found. Stopping spinner.");
         setVisitors([]); // Clear visitors if no user
         setLoading(false);
         return;
      }
      //console.log("4. User ID found! Starting API call for:", currentUser.id);
    setLoading(true);
    setError(null);
    try {
      const data = await getMyVisitors(currentUser.id);
      setVisitors(data);
    } catch (err: any) {
        console.error("6. API FAILED:", err);
      console.error(err);
      setError("Failed to load visitors. Check console.");
      alert("Error: " + (err.response?.data?.message || err.message));
    } finally {
           //console.log("7. Turning off spinner.");
      setLoading(false);
    }
  };

  useEffect(() => {
      //console.log("useEffect triggered. Current User:", currentUser);
    fetchVisitors();
  }, []);

  // Handle Pre-Approve (Create)
  const handlePreApprove = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser) return;
   // ADD THIS LINE TO INSPECT THE STATE:
    console.log("🔍 CURRENT USER CONTEXT:", currentUser); 
    try {
       // Merge form data with Context data
      const commandToSend: PreApproveVisitorCommand = {
        ...newVisitor,
        societyId: currentUser.societyId, // Auto-inject from User
        flatId: currentUser.flatId,       // Auto-inject from User
        //inviterId: currentUser.id,        // Auto-inject from User
         invitedByUserId: currentUser.id,
      };
  console.log("SENDING PAYLOAD:", commandToSend); // Verify payload before sending
      await preApproveVisitor(commandToSend);
      setIsModalOpen(false);
      // Reset form
       setNewVisitor({ 
        visitorName: '', visitorMobile: '', vehicleNumber: '', purpose: '', 
        //inviterId: currentUser.id, 
        invitedByUserId: currentUser.id,
        societyId: currentUser.societyId,
        flatId: currentUser.flatId,
        //expectedArrival: new Date().toISOString() 
          expectedDate: new Date().toISOString().split('T')[0],
      });
      fetchVisitors(); // Refresh list
    } catch (err: any) {
      alert(
        "Failed to pre-approve visitor: " +
          (err.response?.data?.message || err.message),
      );
    }
  };

  // Handle Mark Exit
  const handleMarkExit = async (visitorId: string) => {
    if (!confirm("Are you sure you want to mark this visitor as exited?"))
      return;

    try {
      await markVisitorExit({ visitorId });
      fetchVisitors();
    } catch (err: any) {
      alert(
        "Failed to mark exit: " + (err.response?.data?.message || err.message),
      );
    }
  };

  /*const getStatusBadge = (status: string) => {
    switch (status?.toLowerCase()) {
      case 'entered': return 'bg-blue-100 text-blue-700 border-blue-200';
      case 'exited': return 'bg-slate-100 text-slate-600';
      case 'preapproved': return 'bg-green-100 text-green-700 border-green-200';
      default: return 'bg-orange-100 text-orange-700';
    }
  };*/
  // Handle both Numbers (C# Enums) and Strings
  const getStatusBadge = (status: any) => {
    // 1. Handle Numbers (0: Pending, 1: Entered, 2: Exited)
    if (typeof status === "number") {
      switch (status) {
        case 1:
          return "bg-blue-100 text-blue-700 border-blue-200"; // Entered
        case 2:
          return "bg-slate-100 text-slate-600"; // Exited
        default:
          return "bg-green-100 text-green-700 border-green-200"; // Pending/PreApproved
      }
    }

    // 2. Handle Strings (if backend is fixed later)
    const s = String(status || "").toLowerCase();
    switch (s) {
      case "entered":
        return "bg-blue-100 text-blue-700 border-blue-200";
      case "exited":
        return "bg-slate-100 text-slate-600";
      case "preapproved":
        return "bg-green-100 text-green-700 border-green-200";
      default:
        return "bg-orange-100 text-orange-700";
    }
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Visitor Management</h1>
        <button
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md transition"
        >
          <Plus size={18} />
          Pre-Approve Visitor
        </button>
      </div>

      {error && (
        <div className="bg-red-50 text-red-700 p-4 rounded-md mb-6 border border-red-200">
          {error}
        </div>
      )}

      {loading ? (
        <div className="text-center py-10 text-slate-500">
          Loading visitors...
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b border-slate-200">
                <tr>
                  <th className="px-6 py-4 font-medium">Name</th>
                  <th className="px-6 py-4 font-medium">Contact</th>
                  <th className="px-6 py-4 font-medium">Purpose</th>
                  <th className="px-6 py-4 font-medium">Status</th>
                  <th className="px-6 py-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {visitors.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center text-slate-500">
                      No visitors found.
                    </td>
                  </tr>
                ) : (
                  visitors.map((visitor) => (
                    <tr
                      key={visitor.id}
                      className="hover:bg-slate-50 transition-colors"
                    >
                      <td className="px-6 py-4 font-medium text-slate-800">
                         {visitor.visitorName || '-'} 
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-600">
                        {visitor.visitorMobile || '-'}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-600">
                        {visitor.purpose}
                      </td>

                      <td className="px-6 py-4">
                        <span
                          className={`px-3 py-1 rounded-full text-xs font-semibold border ${getStatusBadge(visitor.status)}`}
                        >
                          {typeof visitor.status === "number"
                            ? visitor.status === 1
                              ? "Entered"
                              : visitor.status === 2
                                ? "Exited"
                                : "PreApproved"
                            : visitor.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        {/* Show Mark Exit only if status is Entered */}
                        {visitor.status?.toLowerCase() === "entered" ? (
                          <button
                            onClick={() => handleMarkExit(visitor.id)}
                            className="inline-flex items-center gap-1 px-3 py-1 bg-red-50 text-red-600 rounded hover:bg-red-100 transition"
                          >
                            <LogOut size={14} />
                            Mark Exit
                          </button>
                        ) : (
                          <span className="text-xs text-slate-400 flex items-center justify-end gap-1">
                            {visitor.status?.toLowerCase() ===
                              "preapproved" && <Clock size={12} />}
                            Waiting
                          </span>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Simple Modal for Pre-Approval */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-md shadow-xl">
            <h2 className="text-xl font-bold mb-4">Pre-Approve Visitor</h2>
            <form onSubmit={handlePreApprove} className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">
                  Visitor Name
                </label>
                <input
                  required
                  type="text"
                  className="w-full border rounded p-2"
                  value={newVisitor.visitorName}
                  onChange={(e) =>
                    setNewVisitor({ ...newVisitor, visitorName: e.target.value })
                  }
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">
                  Visitor Mobile
                </label>
                <input
                  required
                  type="text"
                  className="w-full border rounded p-2"
                  value={newVisitor.visitorMobile}
                  onChange={(e) =>
                    setNewVisitor({
                      ...newVisitor,
                      visitorMobile: e.target.value,
                    })
                  }
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">
                  Purpose
                </label>
                <input
                  required
                  type="text"
                  className="w-full border rounded p-2"
                  value={newVisitor.purpose}
                  onChange={(e) =>
                    setNewVisitor({ ...newVisitor, purpose: e.target.value })
                  }
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">
                  Vehicle (Optional)
                </label>
                <input
                  type="text"
                  className="w-full border rounded p-2"
                  value={newVisitor.vehicleNumber}
                  onChange={(e) =>
                    setNewVisitor({
                      ...newVisitor,
                      vehicleNumber: e.target.value,
                    })
                  }
                />
              </div>
              <div className="flex justify-end gap-2 mt-6">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Pre-Approve
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Visitors;
