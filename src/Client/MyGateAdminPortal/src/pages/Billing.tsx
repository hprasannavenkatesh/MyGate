// src/pages/Billing.tsx
import React, { useState } from 'react';
import { billsData, type Bill } from '../api/mockData';
import { FileText, CheckCircle, AlertCircle } from 'lucide-react';

const Billing = () => {
  const [bills, setBills] = useState<Bill[]>(billsData);

  // Function to mark a bill as paid
  const handleMarkPaid = (id: number) => {
    const updatedBills = bills.map(bill => {
      if (bill.id === id) {
        return { ...bill, status: 'Paid' as const };
      }
      return bill;
    });
    setBills(updatedBills);
  };

  // Helper for currency formatting
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0
    }).format(amount);
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Billing & Invoices</h1>
        <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md transition">
          + Generate Invoice
        </button>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b border-slate-200">
              <tr>
                <th className="px-6 py-4 font-medium">Invoice ID</th>
                <th className="px-6 py-4 font-medium">Flat</th>
                <th className="px-6 py-4 font-medium">Month</th>
                <th className="px-6 py-4 font-medium">Amount</th>
                <th className="px-6 py-4 font-medium">Status</th>
                <th className="px-6 py-4 font-medium">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {bills.map((bill) => (
                <tr key={bill.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 font-mono text-sm text-slate-600">
                    {bill.invoiceId}
                  </td>
                  
                  <td className="px-6 py-4 font-medium text-slate-800">
                    {bill.flat}
                  </td>
                  
                  <td className="px-6 py-4 text-slate-600">
                    {bill.month}
                  </td>
                  
                  <td className="px-6 py-4 font-semibold text-slate-700">
                    {formatCurrency(bill.amount)}
                  </td>
                  
                  <td className="px-6 py-4">
                    {bill.status === 'Paid' ? (
                      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                        <CheckCircle size={12} />
                        Paid
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
                        <AlertCircle size={12} />
                        Unpaid
                      </span>
                    )}
                  </td>
                  
                  <td className="px-6 py-4">
                    {bill.status === 'Unpaid' ? (
                      <button 
                        onClick={() => handleMarkPaid(bill.id)}
                        className="text-blue-600 hover:text-blue-800 text-sm font-medium hover:underline"
                      >
                        Mark as Paid
                      </button>
                    ) : (
                      <span className="text-slate-400 text-sm">Receipt Sent</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Billing;