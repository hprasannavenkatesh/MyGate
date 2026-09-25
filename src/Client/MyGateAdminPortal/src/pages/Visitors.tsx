// src/pages/Visitors.tsx
import React, { useState, useEffect, useMemo } from "react";
import {
  Plus,
  LogOut,
  Key,
  ShieldCheck,
  Users,
  LogIn,
  UserCheck,
  UserPlus,
} from "lucide-react";
import {
  getSocietyVisitors,
  preApproveVisitor,
  markVisitorExit,
  regenerateOtp,
  manualEntry,
  walkInEntry,
  type VisitorDto,
  type PreApproveVisitorCommand,
} from "../api/visitor";
import { useAuth } from "../context/AuthContext";
import { format, isToday, parseISO } from "date-fns";

const normalizeStatus = (status: any) => {
  if (status === null || status === undefined) return "Unknown";
  const statusStr = String(status).toLowerCase().trim();
  const statusNum = parseInt(statusStr);
  if (statusNum === 1) return "Entered";
  if (statusNum === 2) return "Exited";
  if (statusNum === 0) return "Pending";
  if (statusStr === "inside" || statusStr === "entered") return "Entered";
  if (statusStr === "exited" || statusStr === "exit") return "Exited";
  if (
    statusStr === "pending" ||
    statusStr === "preapproved" ||
    statusStr === "pre-approved"
  )
    return "Pending";
  return "Unknown";
};

const Visitors = () => {
  const { currentUser } = useAuth();

  const [visitors, setVisitors] = useState<VisitorDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState("All");

  const [exitLoading, setExitLoading] = useState<string | null>(null);
  const [manualEntryLoading, setManualEntryLoading] = useState<string | null>(
    null,
  );
  const [otpLoading, setOtpLoading] = useState<string | null>(null);
  const [generatedOtp, setGeneratedOtp] = useState<{
    visitorId: string;
    otp: string;
    expiresAt: string;
  } | null>(null);
  // Pre-approve modal
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [preApproveResult, setPreApproveResult] = useState<{
    visitorName: string;
    otp: string;
  } | null>(null);
  const [newVisitor, setNewVisitor] = useState<PreApproveVisitorCommand>({
    visitorName: "",
    visitorMobile: "",
    vehicleNumber: "",
    purpose: "",
    invitedByUserId: currentUser?.id || "",
    societyId: currentUser?.societyId || "",
    flatId: currentUser?.flatId || "",
    expectedDate: new Date().toISOString().split("T")[0],
  });

  // Walk-in entry modal
  const [isWalkInModalOpen, setIsWalkInModalOpen] = useState(false);
  const [walkInVisitor, setWalkInVisitor] = useState<PreApproveVisitorCommand>({
    visitorName: "",
    visitorMobile: "",
    vehicleNumber: "",
    purpose: "",
    invitedByUserId: currentUser?.id || "",
    societyId: currentUser?.societyId || "",
    flatId: currentUser?.flatId || "",
    expectedDate: new Date().toISOString().split("T")[0],
  });
  const [walkInLoading, setWalkInLoading] = useState(false);

  // Manual entry modal
  const [isManualEntryModalOpen, setIsManualEntryModalOpen] = useState(false);
  const [manualEntryVisitorId, setManualEntryVisitorId] = useState("");
  const [manualEntryVisitorName, setManualEntryVisitorName] = useState("");
  const [manualEntryReason, setManualEntryReason] = useState("");

  // --- Fetch ALL society visitors (Admin view) ---
  const fetchVisitors = async () => {
    if (!currentUser?.societyId) {
      setVisitors([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const data = await getSocietyVisitors(currentUser.societyId);
      setVisitors(data);
    } catch (err: any) {
      console.error("Failed to load visitors:", err);
      setError("Failed to load visitors.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVisitors();
  }, [currentUser?.societyId]);

  // --- Stats ---
  const stats = useMemo(() => {
    const todayVisitors = visitors.filter((v) => {
      try {
        return isToday(parseISO(v.expectedDate));
      } catch {
        return false;
      }
    });
    return {
      total: todayVisitors.length,
      pending: todayVisitors.filter(
        (v) => normalizeStatus(v.status) === "Pending",
      ).length,
      inside: todayVisitors.filter(
        (v) => normalizeStatus(v.status) === "Entered",
      ).length,
      exited: todayVisitors.filter(
        (v) => normalizeStatus(v.status) === "Exited",
      ).length,
    };
  }, [visitors]);

  // --- Filtered visitors ---
  const filteredVisitors = useMemo(() => {
    if (statusFilter === "All") return visitors;
    return visitors.filter((v) => normalizeStatus(v.status) === statusFilter);
  }, [visitors, statusFilter]);

  // --- Handle Pre-Approve ---
  const handlePreApprove = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser) return;
    try {
      const commandToSend: PreApproveVisitorCommand = {
        ...newVisitor,
        societyId: currentUser.societyId,
        flatId: currentUser.flatId,
        invitedByUserId: currentUser.id,
      };
      const result = await preApproveVisitor(commandToSend);
      setPreApproveResult({
        visitorName: newVisitor.visitorName,
        otp: result.otp,
      });
    } catch (err: any) {
      alert(
        "Failed to pre-approve: " +
          (err.response?.data?.message || err.message),
      );
    }
  };

  const handleClosePreApproveModal = () => {
    setIsModalOpen(false);
    setPreApproveResult(null);
    setNewVisitor({
      visitorName: "",
      visitorMobile: "",
      vehicleNumber: "",
      purpose: "",
      invitedByUserId: currentUser?.id || "",
      societyId: currentUser?.societyId || "",
      flatId: currentUser?.flatId || "",
      expectedDate: new Date().toISOString().split("T")[0],
    });
    fetchVisitors();
  };

  // --- Handle Walk-in Entry ---
  const handleWalkInEntry = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser) return;
    setWalkInLoading(true);
    try {
      const commandToSend: PreApproveVisitorCommand = {
        ...walkInVisitor,
        societyId: currentUser.societyId,
        flatId: currentUser.flatId,
        invitedByUserId: currentUser.id,
      };
      await walkInEntry(commandToSend);
      setIsWalkInModalOpen(false);
      setWalkInVisitor({
        visitorName: "",
        visitorMobile: "",
        vehicleNumber: "",
        purpose: "",
        invitedByUserId: currentUser?.id || "",
        societyId: currentUser?.societyId || "",
        flatId: currentUser?.flatId || "",
        expectedDate: new Date().toISOString().split("T")[0],
      });
      fetchVisitors();
    } catch (err: any) {
      alert(
        "Walk-in entry failed: " + (err.response?.data?.message || err.message),
      );
    } finally {
      setWalkInLoading(false);
    }
  };

  // --- Handle Get OTP ---
  const handleGetOtp = async (visitorId: string) => {
    setOtpLoading(visitorId);
    try {
      const result = await regenerateOtp(visitorId);
      setGeneratedOtp({
        visitorId,
        otp: result.otp,
        expiresAt: result.expiresAt,
      });
    } catch (err: any) {
      alert(
        "Failed to get OTP: " + (err.response?.data?.message || err.message),
      );
    } finally {
      setOtpLoading(null);
    }
  };

  // --- Handle Manual Entry ---
  const handleOpenManualEntry = (visitorId: string, visitorName: string) => {
    setManualEntryVisitorId(visitorId);
    setManualEntryVisitorName(visitorName);
    setManualEntryReason("");
    setIsManualEntryModalOpen(true);
  };

  const handleManualEntry = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!manualEntryReason.trim()) {
      alert("Please provide a reason.");
      return;
    }
    setManualEntryLoading(manualEntryVisitorId);
    try {
      await manualEntry({
        preApprovalId: manualEntryVisitorId,
        reason: manualEntryReason.trim(),
      });
      setIsManualEntryModalOpen(false);
      fetchVisitors();
    } catch (err: any) {
      alert(
        "Manual entry failed: " + (err.response?.data?.message || err.message),
      );
    } finally {
      setManualEntryLoading(null);
    }
  };

  // --- Handle Mark Exit ---
  const handleMarkExit = async (visitorId: string) => {
    if (!confirm("Mark this visitor as exited?")) return;
    setExitLoading(visitorId);
    try {
      await markVisitorExit({ preApprovalId: visitorId });
      fetchVisitors();
    } catch (err: any) {
      alert(
        "Failed to mark exit: " + (err.response?.data?.message || err.message),
      );
    } finally {
      setExitLoading(null);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "Entered":
        return "bg-blue-100 text-blue-700 border-blue-200";
      case "Exited":
        return "bg-slate-100 text-slate-600 border-slate-200";
      case "Pending":
        return "bg-yellow-100 text-yellow-700 border-yellow-200";
      default:
        return "bg-red-100 text-red-700 border-red-200";
    }
  };

  const formatExpiry = (expiresAt: string) => {
    const diff = new Date(expiresAt).getTime() - Date.now();
    if (diff <= 0) return "Expired";
    return `${Math.floor(diff / 60000)} min remaining`;
  };

  return (
    <div className="p-8">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Visitor Management</h1>
        <div className="flex gap-2">
          <button
            onClick={() => setIsWalkInModalOpen(true)}
            className="flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md transition"
          >
            <UserPlus size={18} />
            Walk-in Entry
          </button>
          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md transition"
          >
            <Plus size={18} />
            Pre-Approve
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-lg border border-slate-200 flex items-center gap-3">
          <div className="p-2 bg-blue-50 rounded-full text-blue-600">
            <Users size={20} />
          </div>
          <div>
            <p className="text-xs text-slate-500">Today's Visitors</p>
            <p className="text-xl font-bold">{stats.total}</p>
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg border border-slate-200 flex items-center gap-3">
          <div className="p-2 bg-yellow-50 rounded-full text-yellow-600">
            <UserCheck size={20} />
          </div>
          <div>
            <p className="text-xs text-slate-500">Pending Entry</p>
            <p className="text-xl font-bold">{stats.pending}</p>
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg border border-slate-200 flex items-center gap-3">
          <div className="p-2 bg-green-50 rounded-full text-green-600">
            <LogIn size={20} />
          </div>
          <div>
            <p className="text-xs text-slate-500">Currently Inside</p>
            <p className="text-xl font-bold">{stats.inside}</p>
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg border border-slate-200 flex items-center gap-3">
          <div className="p-2 bg-slate-100 rounded-full text-slate-600">
            <LogOut size={20} />
          </div>
          <div>
            <p className="text-xs text-slate-500">Exited</p>
            <p className="text-xl font-bold">{stats.exited}</p>
          </div>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="flex items-center gap-2 mb-4">
        <span className="text-sm text-slate-500">Filter:</span>
        {["All", "Pending", "Entered", "Exited"].map((s) => (
          <button
            key={s}
            onClick={() => setStatusFilter(s)}
            className={`px-3 py-1 rounded-full text-sm font-medium transition ${statusFilter === s ? "bg-blue-600 text-white" : "bg-slate-100 text-slate-600 hover:bg-slate-200"}`}
          >
            {s}
          </button>
        ))}
      </div>

      {error && (
        <div className="bg-red-50 text-red-700 p-4 rounded-md mb-6 border border-red-200">
          {error}
        </div>
      )}

      {/* Visitor Table */}
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
                  <th className="px-6 py-4 font-medium">Visitor ID</th>
                  <th className="px-6 py-4 font-medium">Visitor</th>
                  <th className="px-6 py-4 font-medium">Contact</th>
                  <th className="px-6 py-4 font-medium">Purpose</th>
                  <th className="px-6 py-4 font-medium">Expected</th>
                  <th className="px-6 py-4 font-medium">Status</th>
                  <th className="px-6 py-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredVisitors.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-8 text-center text-slate-500">
                      No visitors found.
                    </td>
                  </tr>
                ) : (
                  filteredVisitors.map((visitor) => {
                    const currentStatus = normalizeStatus(visitor.status);
                    const isOtpShowing = generatedOtp?.visitorId === visitor.id;
                    return (
                      <tr
                        key={visitor.id}
                        className="hover:bg-slate-50 transition-colors"
                      >
                        <td
                          className="px-6 py-4 text-xs font-mono text-slate-400 max-w-[120px] truncate"
                          title={visitor.id}
                        >
                          {visitor.id.substring(0, 8)}...
                        </td>
                        <td className="px-6 py-4 font-medium text-slate-800">
                          {visitor.visitorName || "-"}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-600">
                          {visitor.visitorMobile || "-"}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-600">
                          {visitor.purpose || "-"}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-600">
                          {visitor.expectedDate
                            ? format(
                                parseISO(visitor.expectedDate),
                                "dd MMM yyyy",
                              )
                            : "-"}
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className={`px-3 py-1 rounded-full text-xs font-semibold border ${getStatusBadge(currentStatus)}`}
                          >
                            {currentStatus}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right space-x-2">
                          {currentStatus === "Pending" && (
                            <>
                              <button
                                onClick={() => handleGetOtp(visitor.id)}
                                disabled={otpLoading === visitor.id}
                                className="inline-flex items-center gap-1 px-2 py-1 bg-amber-50 text-amber-700 border border-amber-200 rounded text-xs hover:bg-amber-100 transition disabled:opacity-50"
                              >
                                <Key size={12} />
                                {otpLoading === visitor.id
                                  ? "..."
                                  : isOtpShowing
                                    ? "New OTP"
                                    : "Get OTP"}
                              </button>
                              <button
                                onClick={() =>
                                  handleOpenManualEntry(
                                    visitor.id,
                                    visitor.visitorName,
                                  )
                                }
                                className="inline-flex items-center gap-1 px-2 py-1 bg-green-50 text-green-700 border border-green-200 rounded text-xs hover:bg-green-100 transition"
                              >
                                <ShieldCheck size={12} /> Manual Entry
                              </button>
                            </>
                          )}
                          {currentStatus === "Entered" && (
                            <button
                              onClick={() => handleMarkExit(visitor.id)}
                              disabled={exitLoading === visitor.id}
                              className="inline-flex items-center gap-1 px-2 py-1 bg-red-50 text-red-600 rounded text-xs hover:bg-red-100 transition disabled:opacity-50"
                            >
                              {exitLoading === visitor.id ? "..." : "Mark Exit"}
                            </button>
                          )}
                          {currentStatus === "Exited" && (
                            <span className="text-xs text-slate-400">
                              Complete
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* OTP Toast */}
      {generatedOtp && (
        <div className="fixed bottom-6 right-6 bg-amber-50 border-2 border-amber-300 rounded-lg p-4 shadow-lg z-40 max-w-xs">
          <div className="flex items-start justify-between mb-2">
            <p className="text-sm font-semibold text-amber-700">🔑 Gate OTP</p>
            <button
              onClick={() => setGeneratedOtp(null)}
              className="text-amber-400 hover:text-amber-600 text-lg leading-none"
            >
              ×
            </button>
          </div>
          <p className="text-2xl font-mono font-bold text-amber-600 tracking-widest mb-1">
            {generatedOtp.otp}
          </p>
          <p className="text-xs text-amber-500">
            Expires in {formatExpiry(generatedOtp.expiresAt)}
          </p>
          <p className="text-xs text-slate-400 mt-2">
            Share this OTP with the security guard
          </p>
        </div>
      )}

      {/* ============ PRE-APPROVE MODAL ============ */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-md shadow-xl">
            {preApproveResult ? (
              <>
                <div className="text-center mb-4">
                  <div className="mx-auto w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mb-3">
                    <span className="text-green-600 text-xl">✓</span>
                  </div>
                  <h2 className="text-xl font-bold text-green-700">
                    Visitor Pre-Approved!
                  </h2>
                </div>
                <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 mb-4">
                  <p className="text-sm text-amber-700 mb-2">
                    <strong>{preApproveResult.visitorName}</strong> has been
                    pre-approved. Share this OTP with the security guard:
                  </p>
                  <div className="flex items-center justify-center gap-2 bg-white border-2 border-amber-300 rounded-lg py-3 px-4">
                    <Key size={20} className="text-amber-600" />
                    <span className="text-3xl font-mono font-bold text-amber-700 tracking-widest">
                      {preApproveResult.otp}
                    </span>
                  </div>
                  <p className="text-xs text-amber-500 mt-2 text-center">
                    This OTP expires in 30 minutes.
                  </p>
                </div>
                <button
                  onClick={handleClosePreApproveModal}
                  className="w-full px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Close
                </button>
              </>
            ) : (
              <>
                <h2 className="text-xl font-bold mb-4">Pre-Approve Visitor</h2>
                <p className="text-sm text-slate-500 mb-4">
                  Visitor will receive an OTP for gate entry verification.
                </p>
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
                        setNewVisitor({
                          ...newVisitor,
                          visitorName: e.target.value,
                        })
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
                        setNewVisitor({
                          ...newVisitor,
                          purpose: e.target.value,
                        })
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
                      onClick={handleClosePreApproveModal}
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
              </>
            )}
          </div>
        </div>
      )}

      {/* ============ WALK-IN ENTRY MODAL ============ */}
      {isWalkInModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-md shadow-xl">
            <h2 className="text-xl font-bold mb-2">Walk-in Entry</h2>
            <p className="text-sm text-slate-500 mb-2">
              Register a visitor who arrived without pre-approval and mark them
              as entered immediately.
            </p>
            <div className="bg-orange-50 border border-orange-200 p-3 rounded-md mb-4 text-sm text-orange-700">
              ⚠️ No OTP will be generated. Visitor will be marked as Entered
              directly. Use only for unexpected visitors" Entered directly. Use
              only for unexpected visitors at the gate.
            </div>
            <form onSubmit={handleWalkInEntry} className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">
                  Visitor Name *
                </label>
                <input
                  required
                  type="text"
                  className="w-full border rounded p-2"
                  value={walkInVisitor.visitorName}
                  onChange={(e) =>
                    setWalkInVisitor({
                      ...walkInVisitor,
                      visitorName: e.target.value,
                    })
                  }
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">
                  Visitor Mobile *
                </label>
                <input
                  required
                  type="text"
                  className="w-full border rounded p-2"
                  value={walkInVisitor.visitorMobile}
                  onChange={(e) =>
                    setWalkInVisitor({
                      ...walkInVisitor,
                      visitorMobile: e.target.value,
                    })
                  }
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">
                  Purpose *
                </label>
                <input
                  required
                  type="text"
                  className="w-full border rounded p-2"
                  placeholder="e.g., Delivery, Meeting, Repair"
                  value={walkInVisitor.purpose}
                  onChange={(e) =>
                    setWalkInVisitor({
                      ...walkInVisitor,
                      purpose: e.target.value,
                    })
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
                  value={walkInVisitor.vehicleNumber}
                  onChange={(e) =>
                    setWalkInVisitor({
                      ...walkInVisitor,
                      vehicleNumber: e.target.value,
                    })
                  }
                />
              </div>
              <div className="flex justify-end gap-2 mt-6">
                <button
                  type="button"
                  onClick={() => setIsWalkInModalOpen(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={walkInLoading}
                  className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50 flex items-center gap-2"
                >
                  <UserPlus size={16} />
                  {walkInLoading ? "Processing..." : "Allow Walk-in Entry"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ============ MANUAL ENTRY MODAL ============ */}
      {isManualEntryModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-full max-w-md shadow-xl">
            <h2 className="text-xl font-bold mb-2">Manual Entry Override</h2>
            <p className="text-sm text-slate-500 mb-4">
              Mark <strong>{manualEntryVisitorName}</strong> as entered without
              OTP verification.
            </p>
            <div className="bg-amber-50 border border-amber-200 p-3 rounded-md mb-4 text-sm text-amber-700">
              ⚠️ This bypasses OTP verification. Use only when the guard has
              confirmed the visitor's identity by calling the resident.
            </div>
            <form onSubmit={handleManualEntry} className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">
                  Reason for manual entry *
                </label>
                <textarea
                  required
                  rows={3}
                  className="w-full border rounded p-2 text-sm"
                  placeholder="e.g., Visitor's phone is dead, confirmed with resident by phone"
                  value={manualEntryReason}
                  onChange={(e) => setManualEntryReason(e.target.value)}
                  autoFocus
                />
              </div>
              <div className="flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsManualEntryModalOpen(false)}
                  className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!!manualEntryLoading}
                  className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
                >
                  {manualEntryLoading
                    ? "Processing..."
                    : "Confirm Manual Entry"}
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
