// src/pages/Dashboard.tsx
import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { getAllSocietiesForSuperAdmin, type SocietyListDto } from '../api/tenant';
import { getDashboardData } from '../api/mockData';
import { Building, Users, Loader2, Activity as ActivityIcon, DollarSign, Car } from 'lucide-react';


// --- SUPERADMIN GLOBAL DASHBOARD ---
const SuperAdminDashboard = () => {
  const [societies, setSocieties] = useState<SocietyListDto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchGlobalData = async () => {
      try {
        const data = await getAllSocietiesForSuperAdmin();
        setSocieties(data);
      } catch (err) {
        console.error('Failed to fetch global data', err);
      } finally {
        setLoading(false);
      }
    };
    fetchGlobalData();
  }, []);

  if (loading) return <div className="p-8 flex justify-center"><Loader2 className="animate-spin text-blue-500 w-8 h-8" /></div>;

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6 flex items-center gap-2">
        <Building className="text-blue-600" size={24} /> Global Dashboard
      </h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-blue-50 rounded-md"><Building className="text-blue-600" size={24} /></div>
            <div>
              <p className="text-sm text-slate-500">Total Societies</p>
              <p className="text-2xl font-bold text-slate-800">{societies.length}</p>
            </div>
          </div>
        </div>
        {/* Placeholders for future cross-service aggregation */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-green-50 rounded-md"><Users className="text-green-600" size={24} /></div>
            <div>
              <p className="text-sm text-slate-500">Total Residents</p>
              <p className="text-2xl font-bold text-slate-800">—</p> 
            </div>
          </div>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-red-50 rounded-md"><DollarSign className="text-red-600" size={24} /></div>
            <div>
              <p className="text-sm text-slate-500">Pending Dues</p>
              <p className="text-2xl font-bold text-slate-800">—</p>
            </div>
          </div>
        </div>
      </div>

      <h2 className="text-lg font-semibold mb-4">Recent Societies</h2>
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
        <table className="w-full text-left">
          <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b">
            <tr>
              <th className="px-6 py-3 font-medium">Society Name</th>
              <th className="px-6 py-3 font-medium">City</th>
              <th className="px-6 py-3 font-medium">Address</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {societies.length === 0 ? (
              <tr><td colSpan={3} className="p-8 text-center text-slate-500">No societies found.</td></tr>
            ) : (
              societies.map(s => (
                <tr key={s.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 font-medium text-slate-800">{s.name}</td>
                  <td className="px-6 py-4 text-slate-600">{s.city || '—'}</td>
                  <td className="px-6 py-4 text-slate-600">{s.address || '—'}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

// --- NORMAL ADMIN DASHBOARD ---
const AdminDashboard = () => {
  const { stats, activities } = getDashboardData(); // Still using mock data until Reporting Service (5119) is built

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-blue-50 rounded-md"><Users className="text-blue-600" size={24} /></div>
            <div>
              <p className="text-sm text-slate-500">Total Residents</p>
              <p className="text-2xl font-bold text-slate-800">{stats.totalResidents}</p>
            </div>
          </div>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-red-50 rounded-md"><DollarSign className="text-red-600" size={24} /></div>
            <div>
              <p className="text-sm text-slate-500">Pending Dues</p>
              <p className="text-2xl font-bold text-slate-800">₹{stats.pendingDues.toLocaleString()}</p>
            </div>
          </div>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-green-50 rounded-md"><Car className="text-green-600" size={24} /></div>
            <div>
              <p className="text-sm text-slate-500">Parking Occupancy</p>
              <p className="text-2xl font-bold text-slate-800">{stats.parkingOccupancy}%</p>
            </div>
          </div>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-yellow-50 rounded-md"><ActivityIcon className="text-yellow-600" size={24} /></div>
            <div>
              <p className="text-sm text-slate-500">Active Notices</p>
              <p className="text-2xl font-bold text-slate-800">{stats.activeNotices}</p>
            </div>
          </div>
        </div>
      </div>

      <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-6">
        <ul className="divide-y divide-slate-100">
          {activities.map(act => (
            <li key={act.id} className="py-3 flex justify-between items-center">
              <div>
                <span className="text-sm font-medium text-slate-700">{act.event}</span>
                <span className="text-xs text-slate-400 ml-2">by {act.user}</span>
              </div>
              <span className="text-xs text-slate-500">{act.time}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

// --- MAIN ROUTER ---
const Dashboard = () => {
  const { currentUser } = useAuth();

  if (currentUser?.isSuperAdmin) {
    return <SuperAdminDashboard />;
  }

  return <AdminDashboard />;
};

export default Dashboard;