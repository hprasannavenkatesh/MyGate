// src/pages/Notices.tsx
import { useState, useEffect } from 'react';
import { getNotices, createNotice, type NoticeDto } from '../api/notice';
import { useAuth } from '../context/AuthContext';
import { Megaphone, Plus } from 'lucide-react';

const Notices = () => {
  const { currentUser } = useAuth();
  const [notices, setNotices] = useState<NoticeDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newDesc, setNewDesc] = useState('');

  const fetchNotices = async () => {
    if (!currentUser?.societyId) return;
    setLoading(true);
    try {
      const data = await getNotices(currentUser.societyId);
      setNotices(data);
    } catch (err) {
      console.error("Failed to fetch notices", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchNotices(); }, [currentUser?.societyId]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser?.societyId) return;
    try {
      await createNotice({
        societyId: currentUser.societyId,
        title: newTitle,
        description: newDesc,
        category: 0,
        isPinned: false
      });
      setIsModalOpen(false);
      setNewTitle('');
      setNewDesc('');
      fetchNotices(); // Refresh list
    } catch (err) {
      alert('Failed to create notice');
    }
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Notice Board</h1>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md transition"
        >
          <Plus size={18} /> Post Notice
        </button>
      </div>

      {loading ? <div className="text-center py-10 text-slate-500">Loading...</div> : (
        <div className="grid gap-4">
          {notices.length === 0 ? <div className="text-slate-500">No notices found.</div> : 
            notices.map(n => (
              <div key={n.id} className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
                <div className="flex justify-between items-start">
                  <h3 className="text-lg font-semibold text-slate-800">{n.title}</h3>
                  {n.isPinned && <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-1 rounded">📌 Pinned</span>}
                </div>
                <p className="mt-2 text-slate-600">{n.description}</p>
                <p className="mt-4 text-xs text-slate-400">{new Date(n.createdAt).toLocaleString()}</p>
              </div>
            ))
          }
        </div>
      )}

      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-[400px]">
            <h2 className="text-xl font-bold mb-4">Post New Notice</h2>
            <form onSubmit={handleCreate}>
              <input type="text" placeholder="Title" value={newTitle} onChange={e => setNewTitle(e.target.value)} className="w-full border p-2 mb-3 rounded" required />
              <textarea placeholder="Description" value={newDesc} onChange={e => setNewDesc(e.target.value)} className="w-full border p-2 mb-4 rounded h-24" required />
              <div className="flex gap-2 justify-end">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 border rounded">Cancel</button>
                <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded">Post</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Notices;