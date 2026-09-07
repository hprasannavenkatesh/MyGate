// src/pages/Dashboard.tsx
import { useState, useEffect } from 'react';
import { Users, DollarSign, Car, Activity as ActivityIcon } from 'lucide-react';
// NEW (Correct)
import { getDashboardData, type DashboardStats, type Activity } from '../api/mockData';

const Dashboard = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [activities, setActivities] = useState<Activity[]>([]);
  const [loading, setLoading] = useState(true);

  // Simulate fetching data from an API
  useEffect(() => {
    setTimeout(() => {
      const data = getDashboardData();
      setStats(data.stats);
      setActivities(data.activities);
      setLoading(false);
    }, 1000); // Fake 1-second delay to show a loading state
  }, []);

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center h-full">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-slate-500">Loading Dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Dashboard Overview</h1>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {/* Card 1 */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-500">Total Residents</p>
              <h3 className="text-2xl font-bold mt-1">{stats?.totalResidents}</h3>
            </div>
            <div className="p-3 bg-blue-50 rounded-full text-blue-600">
              <Users size={24} />
            </div>
          </div>
        </div>

        {/* Card 2 */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-500">Pending Dues (₹)</p>
              <h3 className="text-2xl font-bold mt-1">{stats?.pendingDues.toLocaleString()}</h3>
            </div>
            <div className="p-3 bg-red-50 rounded-full text-red-600">
              <DollarSign size={24} />
            </div>
          </div>
        </div>

        {/* Card 3 */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-500">Parking Occupancy</p>
              <h3 className="text-2xl font-bold mt-1">{stats?.parkingOccupancy}%</h3>
            </div>
            <div className="p-3 bg-green-50 rounded-full text-green-600">
              <Car size={24} />
            </div>
          </div>
        </div>

        {/* Card 4 */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-slate-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-500">Active Notices</p>
              <h3 className="text-2xl font-bold mt-1">{stats?.activeNotices}</h3>
            </div>
            <div className="p-3 bg-purple-50 rounded-full text-purple-600">
              <ActivityIcon size={24} />
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity Table */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200">
        <div className="p-6 border-b border-slate-200">
          <h2 className="text-lg font-semibold">Recent Activity (Audit Log)</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-slate-50 text-slate-500 text-sm uppercase">
              <tr>
                <th className="px-6 py-3 font-medium">Time</th>
                <th className="px-6 py-3 font-medium">Service</th>
                <th className="px-6 py-3 font-medium">Event</th>
                <th className="px-6 py-3 font-medium">User</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {activities.map((activity) => (
                <tr key={activity.id} className="hover:bg-slate-50 transition-colors">
                  <td className="px-6 py-4 text-sm text-slate-600">{activity.time}</td>
                  <td className="px-6 py-4 text-sm font-medium text-slate-700">{activity.service}</td>
                  <td className="px-6 py-4 text-sm text-slate-600">{activity.event}</td>
                  <td className="px-6 py-4 text-sm text-slate-600">{activity.user}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;