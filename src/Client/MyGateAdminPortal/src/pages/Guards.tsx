// src/pages/Guards.tsx
import { useState } from 'react';
import { createGuard } from '../api/memberAdmin';
//import { useAuth } from '../context/AuthContext';
import { ShieldCheck, Plus, Loader2, Phone } from 'lucide-react';

const Guards = () => {
  //const { currentUser } = useAuth();
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  // Form State
  const [mobileNumber, setMobileNumber] = useState('');
  const [fullName, setFullName] = useState('');
  
  // UI State
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleCreateGuard = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!mobileNumber.trim() || !fullName.trim()) return;

    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const result = await createGuard({ mobileNumber: mobileNumber.trim(), fullName: fullName.trim() });
      setSuccess(`Guard registered successfully! ID: ${result.id.substring(0, 8)}...`);
      setMobileNumber('');
      setFullName('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to register guard. Check if mobile number already exists.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <ShieldCheck className="text-blue-600" size={24} /> Guard Management
        </h1>
        <button 
          onClick={() => { setIsModalOpen(true); setError(null); setSuccess(null); }}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md transition"
        >
          <Plus size={18} /> Register Guard
        </button>
      </div>

      {/* Feedback Messages */}
      {error && <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-md mb-4">{error}</div>}
      {success && <div className="bg-green-50 border border-green-200 text-green-700 p-4 rounded-md mb-4">{success}</div>}

      <div className="bg-white p-12 rounded-lg shadow-sm border border-slate-200 text-center">
        <ShieldCheck className="mx-auto text-slate-300 mb-4" size={48} />
        <h3 className="text-lg font-medium text-slate-700">Society Security Guards</h3>
        <p className="text-sm text-slate-500 mt-1">
          Register guards to allow them access to the Gate App for visitor entry and exit management.
        </p>
        {/* TODO: Add a table here later to fetch and display existing guards from the society */}
      </div>

      {/* --- Create Guard Modal --- */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-[400px] shadow-xl">
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <ShieldCheck size={20} className="text-blue-600" /> Register New Guard
            </h2>
            <form onSubmit={handleCreateGuard} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Full Name *</label>
                <input 
                  type="text" 
                  value={fullName} 
                  onChange={(e) => setFullName(e.target.value)} 
                  className="w-full border p-2 rounded" 
                  placeholder="e.g., Ramesh Kumar" 
                  required 
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Mobile Number *</label>
                <div className="flex gap-2">
                  <div className="flex items-center px-3 border border-slate-300 rounded-l-md bg-slate-50 text-slate-500 text-sm">
                    <Phone size={16} />
                  </div>
                  <input 
                    type="tel" 
                    value={mobileNumber} 
                    onChange={(e) => setMobileNumber(e.target.value)} 
                    className="flex-1 border border-slate-300 rounded-r-md px-3 py-2 text-sm focus:outline-none focus:border-blue-500" 
                    placeholder="9876543210" 
                    maxLength={15}
                    required 
                  />
                </div>
              </div>
              
              <p className="text-xs text-slate-400">
                Default password will be set to <span className="font-mono bg-slate-100 px-1 py-0.5 rounded">Guard@123</span>. 
                The guard must log in with this mobile number via OTP.
              </p>

              <div className="flex gap-2 justify-end pt-2">
                <button 
                  type="button" 
                  onClick={() => setIsModalOpen(false)} 
                  className="px-4 py-2 border rounded text-slate-600 hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  disabled={loading}
                  className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-slate-400 flex items-center gap-2"
                >
                  {loading && <Loader2 size={16} className="animate-spin" />} Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Guards;