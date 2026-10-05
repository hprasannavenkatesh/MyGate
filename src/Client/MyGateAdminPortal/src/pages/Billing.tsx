import { useState, useEffect } from 'react';
import { getSocietyInvoices, type InvoiceDto } from '../api/billing';
import { useAuth } from '../context/AuthContext';
import { Loader2, DollarSign } from 'lucide-react';

const Billing = () => {
  const { currentUser } = useAuth();
  const [invoices, setInvoices] = useState<InvoiceDto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchInvoices = async () => {
      if (!currentUser?.societyId) return;
      setLoading(true);
      try {
        const data = await getSocietyInvoices(currentUser.societyId);
        setInvoices(data);
      } catch (err) {
        console.error('Failed to fetch invoices', err);
      } finally {
        setLoading(false);
      }
    };
    fetchInvoices();
  }, [currentUser?.societyId]);

  const getStatusBadge = (status: number) => {
    switch (status) {
      case 0: return { label: 'Pending', class: 'bg-yellow-100 text-yellow-700' };
      case 1: return { label: 'Paid', class: 'bg-green-100 text-green-700' };
      case 2: return { label: 'Overdue', class: 'bg-red-100 text-red-700' };
      case 3: return { label: 'Waived', class: 'bg-slate-100 text-slate-600' };
      case 4: return { label: 'Partial', class: 'bg-blue-100 text-blue-700' };
      default: return { label: 'Unknown', class: 'bg-slate-100 text-slate-500' };
    }
  };

  // ADDED: The return statement that was missing
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6 flex items-center gap-2">
        <DollarSign className="text-green-600" size={24} /> Billing & Invoices
      </h1>

      {loading ? (
        <div className="flex justify-center py-10">
          <Loader2 className="animate-spin text-blue-500 w-8 h-8" />
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
          <table className="w-full text-left">
            <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b">
              <tr>
                <th className="px-6 py-3 font-medium">Invoice ID</th>
                <th className="px-6 py-3 font-medium">Flat ID</th>
                <th className="px-6 py-3 font-medium">Amount</th>
                <th className="px-6 py-3 font-medium">Due Date</th>
                <th className="px-6 py-3 font-medium">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {invoices.length === 0 ? (
                <tr>
                  <td colSpan={5} className="p-8 text-center text-slate-500">
                    No invoices found for this society.
                  </td>
                </tr>
              ) : (
                invoices.map(inv => {
                  const badge = getStatusBadge(inv.status);
                  return (
                    <tr key={inv.id} className="hover:bg-slate-50">
                      <td className="px-6 py-4 font-mono text-xs text-slate-400">{inv.id.substring(0, 8)}...</td>
                      <td className="px-6 py-4 font-medium">{inv.flatId.substring(0, 8)}...</td>
                      <td className="px-6 py-4">₹{inv.amount.toFixed(2)}</td>
                      <td className="px-6 py-4">{new Date(inv.dueDate).toLocaleDateString()}</td>
                      <td className="px-6 py-4">
                        <span className={`px-2 py-1 rounded text-xs font-medium ${badge.class}`}>{badge.label}</span>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default Billing;