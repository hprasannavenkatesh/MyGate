// src/pages/SuperAdminSocietyPicker.tsx
import { useState, useEffect } from 'react';
import {useNavigate } from 'react-router-dom';
import { getAllSocietiesForSuperAdmin, type SocietyListDto } from '../api/tenant';
import { useAuth } from '../context/AuthContext';
import { Building, Loader2, Plus, Trash2, AlertCircle } from 'lucide-react';
import apiClient from '../api/client';
import {API_URLS} from "../api/apiConfig";

export default function SuperAdminSocietyPicker() {
  const { currentUser, switchContext } = useAuth();
  const navigate = useNavigate();

  const [societies, setSocieties] = useState<SocietyListDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [switchingId, setSwitchingId] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Create Society State
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [creating, setCreating] = useState(false);
  const [newSocietyName, setNewSocietyName] = useState('');
  const [newSocietyAddress, setNewSocietyAddress] = useState('');
  const [newSocietyCity, setNewSocietyCity] = useState('');

  const fetchSocieties = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getAllSocietiesForSuperAdmin();
      setSocieties(data);
    } catch (err) {
      console.error('Failed to load societies', err);
      setError('Failed to fetch societies. Check TenantService (5104) and network.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSocieties();
  }, []);

  const handleSelectSociety = async (society: SocietyListDto) => {
    setSwitchingId(society.id);
    setError(null);
    try {
      const mockUserForContext = {
         uniqueKey: `${currentUser?.id || ""}_${society.id}_sa`, // ADD THIS (Appends _sa to guarantee uniqueness)
        id: currentUser?.id || '',
        name: society.name,
        flat: 'SuperAdmin',
        societyId: society.id,
        flatId: '',
        role: 'SuperAdmin',
        memberType: 'SuperAdmin',
        isSuperAdmin: true
      };
      await switchContext(mockUserForContext);
      navigate('/');
    } catch (err) {
      console.error('Failed to switch context', err);
      setError('Context switch failed. Ensure IdentityService (5103) is running.');
      setSwitchingId(null);
    }
  };

  const handleDeleteSociety = async (societyId: string, societyName: string) => {
    if (!confirm(`⚠️ CRITICAL: Are you sure you want to delete "${societyName}"? This will remove all blocks, flats, and members permanently.`)) return;
    
    setDeletingId(societyId);
    setError(null);
    try {
      await apiClient.delete(`${API_URLS.TENANT}/superadmin/societies/${societyId}`);
      setSocieties(prev => prev.filter(s => s.id !== societyId)); // Optimistic UI update
    } catch (err) {
      console.error('Failed to delete society', err);
      setError('Failed to delete society. Check backend logs.');
    } finally {
      setDeletingId(null);
    }
  };

  const handleCreateSociety = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSocietyName.trim()) return;
    
    setCreating(true);
    setError(null);
    try {
      await apiClient.post(`${API_URLS.TENANT}/superadmin/societies`, {
        name: newSocietyName,
        code: newSocietyName.substring(0, 3).toUpperCase(), // Auto-generate code
        address: newSocietyAddress,
        city: newSocietyCity
      });
      setShowCreateModal(false);
      setNewSocietyName('');
      setNewSocietyAddress('');
      setNewSocietyCity('');
      fetchSocieties(); // Refresh list
    } catch (err) {
      console.error('Failed to create society', err);
      setError('Failed to create society.');
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-8">
      <div className="max-w-6xl w-full">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-slate-800 flex items-center justify-center gap-3">
            <Building className="w-8 h-8 text-blue-600" /> SuperAdmin Portal
          </h1>
          <p className="text-slate-500 mt-2">
            Select a society to manage, or create a new one. You will enter the society context with elevated permissions.
          </p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-md mb-6 flex items-center gap-2">
            <AlertCircle size={20} /> {error}
          </div>
        )}

        <div className="flex justify-end mb-6">
          <button 
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-md transition font-medium"
          >
            <Plus size={18} /> Create New Society
          </button>
        </div>

        {loading ? (
          <div className="flex justify-center py-20"><Loader2 className="animate-spin text-blue-500 w-10 h-10" /></div>
        ) : societies.length === 0 ? (
          <div className="text-center py-20 text-slate-500">No societies found. Create one to get started!</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {societies.map(s => (
              <div 
                key={s.id} 
                className="bg-white p-6 rounded-lg shadow-sm border border-slate-200 hover:border-blue-500 hover:shadow-md transition flex flex-col relative group"
              >
                {/* Delete Button - top right */}
                <button 
                  onClick={(e) => { e.stopPropagation(); handleDeleteSociety(s.id, s.name); }}
                  disabled={deletingId === s.id}
                  className="absolute top-3 right-3 p-1.5 text-slate-300 hover:text-red-500 hover:bg-red-50 rounded-md transition opacity-0 group-hover:opacity-100"
                  title="Delete Society"
                >
                  {deletingId === s.id ? <Loader2 size={16} className="animate-spin" /> : <Trash2 size={16} />}
                </button>

                {/* Society Info - clickable area */}
                <button 
                  onClick={() => handleSelectSociety(s)}
                  disabled={switchingId !== null}
                  className="text-left flex-1 focus:outline-none"
                >
                  <h3 className="text-lg font-semibold text-slate-800 mb-1">{s.name}</h3>
                  <p className="text-sm text-slate-500">{s.address || s.city || 'Click to manage'}</p>
                  <span className="mt-3 inline-block text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded w-fit">Society</span>
                </button>

                {/* Loading indicator for context switch */}
                {switchingId === s.id && (
                  <div className="mt-4 flex items-center gap-2 text-blue-600 text-sm">
                    <Loader2 size={16} className="animate-spin" /> Switching context...
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* CREATE SOCIETY MODAL */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-[450px] shadow-xl">
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Plus size={20} className="text-blue-600" /> Create New Society
            </h2>
            <form onSubmit={handleCreateSociety} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Society Name *</label>
                <input 
                  type="text" 
                  value={newSocietyName} 
                  onChange={(e) => setNewSocietyName(e.target.value)} 
                  className="w-full border p-2 rounded" 
                  placeholder="e.g., Sunrise Residency" 
                  required 
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Address</label>
                <input 
                  type="text" 
                  value={newSocietyAddress} 
                  onChange={(e) => setNewSocietyAddress(e.target.value)} 
                  className="w-full border p-2 rounded" 
                  placeholder="123 Main St" 
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">City</label>
                <input 
                  type="text" 
                  value={newSocietyCity} 
                  onChange={(e) => setNewSocietyCity(e.target.value)} 
                  className="w-full border p-2 rounded" 
                  placeholder="Bangalore" 
                />
              </div>
              <div className="flex gap-2 justify-end pt-2">
                <button 
                  type="button" 
                  onClick={() => setShowCreateModal(false)} 
                  className="px-4 py-2 border rounded text-slate-600 hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  disabled={creating}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-slate-400 flex items-center gap-2"
                >
                  {creating && <Loader2 size={16} className="animate-spin" />} Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}