// src/pages/Visitors.tsx
import React, { useState } from 'react';
import { initialVisitors, type Visitor } from '../api/mockData';
import { Check, X, Plus } from 'lucide-react';

const Visitors = () => {
  // 1. Initialize state with the mock data
  const [visitors, setVisitors] = useState<Visitor[]>(initialVisitors);

  // 2. Function to handle Approval
  const handleApprove = (id: number) => {
    // We create a NEW array (don't modify the old one directly!)
    const updatedVisitors = visitors.map(visitor => {
      if (visitor.id === id) {
        return { ...visitor, status: 'Approved' as const };
      }
      return visitor;
    });
    setVisitors(updatedVisitors);
  };

  // 3. Function to handle Rejection
  const handleReject = (id: number) => {
    const updatedVisitors = visitors.map(visitor => {
      if (visitor.id === id) {
        return { ...visitor, status: 'Rejected' as const };
      }
      return visitor;
    });
    setVisitors(updatedVisitors);
  };

  // Helper to pick badge colors
  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'Approved': return 'bg-green-100 text-green-700';
      case 'Rejected': return 'bg-red-100 text-red-700';
      default: return 'bg-orange-100 text-orange-700'; // Pending
    }
  };

  return (
    <div className="p-8">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Visitor Management</h1>
        <button className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md transition">
          <Plus size={18} />
          Pre-approve Visitor
        </button>
      </div>

      {/* Table Card */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b border-slate-200">
              <tr>
                <th className="px-6 py-4 font-medium">Time</th>
                <th className="px-6 py-4 font-medium">Visitor Name</th>
                <th className="px-6 py-4 font-medium">Type</th>
                <th className="px-6 py-4 font-medium">Purpose</th>
                <th className="px-6 py-4 font-medium">Status</th>
                <th className="px-6 py-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {visitors.map((visitor) => (
                <tr key={visitor.id} className="hover:bg-slate-50 transition-colors">
                  <td className="px-6 py-4 text-sm text-slate-600">{visitor.time}</td>
                  
                  <td className="px-6 py-4">
                    <div className="font-medium text-slate-800">{visitor.name}</div>
                  </td>
                  
                  <td className="px-6 py-4 text-sm text-slate-600">{visitor.type}</td>
                  
                  <td className="px-6 py-4 text-sm text-slate-600">{visitor.purpose}</td>
                  
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getStatusBadge(visitor.status)}`}>
                      {visitor.status}
                    </span>
                  </td>
                  
                  <td className="px-6 py-4 text-right">
                    {/* Show buttons only if Pending */}
                    {visitor.status === 'Pending' ? (
                      <div className="flex justify-end gap-2">
                        <button 
                          onClick={() => handleApprove(visitor.id)}
                          className="p-2 bg-green-50 text-green-600 rounded-md hover:bg-green-100 transition"
                          title="Approve"
                        >
                          <Check size={18} />
                        </button>
                        <button 
                          onClick={() => handleReject(visitor.id)}
                          className="p-2 bg-red-50 text-red-600 rounded-md hover:bg-red-100 transition"
                          title="Reject"
                        >
                          <X size={18} />
                        </button>
                      </div>
                    ) : (
                      <span className="text-xs text-slate-400">Processed</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {visitors.length === 0 && (
          <div className="p-8 text-center text-slate-500">No visitors found.</div>
        )}
      </div>
    </div>
  );
};

export default Visitors;