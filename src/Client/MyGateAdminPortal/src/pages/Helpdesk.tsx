import { useState, useEffect } from 'react';
import { getSocietyTickets, updateTicketStatus, type TicketDto } from '../api/helpdesk';
import { useAuth } from '../context/AuthContext';
//import { Loader2, Ticket, CheckCircle, Clock } from 'lucide-react';
import { Loader2 } from 'lucide-react';

const statusMap: Record<number, { label: string; color: string }> = {
  0: { label: 'Open', color: 'bg-yellow-100 text-yellow-700' },
  1: { label: 'In Progress', color: 'bg-blue-100 text-blue-700' },
  2: { label: 'Resolved', color: 'bg-green-100 text-green-700' },
  3: { label: 'Closed', color: 'bg-slate-100 text-slate-600' },
};

const Helpdesk = () => {
  const { currentUser } = useAuth();
  const [tickets, setTickets] = useState<TicketDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  useEffect(() => {
    const fetch = async () => {
      if (!currentUser?.societyId) return;
      setLoading(true);
      try {
        const data = await getSocietyTickets(currentUser.societyId);
        setTickets(data);
      } catch (err) {
        console.error('Failed to fetch tickets', err);
      } finally {
        setLoading(false);
      }
    };
    fetch();
  }, [currentUser?.societyId]);

  const handleStatusUpdate = async (ticketId: string, newStatus: number) => {
    setUpdatingId(ticketId);
    try {
      await updateTicketStatus(ticketId, newStatus);
      setTickets(prev => prev.map(t => t.id === ticketId ? { ...t, status: newStatus } : t));
    } catch (err) {
      alert('Failed to update status');
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Helpdesk Tickets</h1>

      {loading ? (
        <div className="flex justify-center py-10"><Loader2 className="animate-spin" size={24} /></div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
          <table className="w-full text-left">
            <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b">
              <tr>
                <th className="px-6 py-3 font-medium">Title</th>
                <th className="px-6 py-3 font-medium">Status</th>
                <th className="px-6 py-3 font-medium">Created</th>
                <th className="px-6 py-3 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {tickets.length === 0 ? (
                <tr><td colSpan={4} className="p-8 text-center text-slate-500">No tickets found.</td></tr>
              ) : tickets.map(t => {
                const s = statusMap[t.status] || statusMap[0];
                return (
                  <tr key={t.id} className="hover:bg-slate-50">
                    <td className="px-6 py-4 font-medium">{t.title}</td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-xs font-medium ${s.color}`}>{s.label}</span>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500">{new Date(t.createdAt).toLocaleDateString()}</td>
                    <td className="px-6 py-4 text-right space-x-2">
                      {t.status === 0 && (
                        <button onClick={() => handleStatusUpdate(t.id, 1)} disabled={updatingId === t.id}
                          className="px-2 py-1 bg-blue-50 text-blue-700 rounded text-xs hover:bg-blue-100">Start</button>
                      )}
                      {t.status === 1 && (
                        <button onClick={() => handleStatusUpdate(t.id, 2)} disabled={updatingId === t.id}
                          className="px-2 py-1 bg-green-50 text-green-700 rounded text-xs hover:bg-green-100">Resolve</button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default Helpdesk;