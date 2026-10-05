import { useState, useEffect } from 'react';
import { getHelpTypes, getStaff, type HelpTypeDto, type StaffDto } from '../api/dailyHelp';
import { useAuth } from '../context/AuthContext';
//import { Loader2, Plus, Users } from 'lucide-react';
import { Loader2 } from 'lucide-react';

const DailyHelp = () => {
  const { currentUser } = useAuth();
  const [helpTypes, setHelpTypes] = useState<HelpTypeDto[]>([]);
  const [staff, setStaff] = useState<StaffDto[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetch = async () => {
      if (!currentUser?.societyId) return;
      setLoading(true);
      try {
        const [types, staffList] = await Promise.all([
          getHelpTypes(currentUser.societyId),
          getStaff(currentUser.societyId)
        ]);
        setHelpTypes(types);
        setStaff(staffList);
      } catch (err) {
        console.error('Failed to fetch daily help data', err);
      } finally {
        setLoading(false);
      }
    };
    fetch();
  }, [currentUser?.societyId]);

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Daily Help Management</h1>

      {loading ? (
        <div className="flex justify-center py-10"><Loader2 className="animate-spin" size={24} /></div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Help Types */}
          <div>
            <h2 className="text-lg font-semibold mb-4">Help Types ({helpTypes.length})</h2>
            <div className="bg-white rounded-lg border p-4 space-y-2">
              {helpTypes.map(ht => (
                <div key={ht.id} className="flex justify-between items-center py-2 border-b last:border-0">
                  <span className="font-medium">{ht.name}</span>
                </div>
              ))}
              {helpTypes.length === 0 && <p className="text-slate-500">No help types configured.</p>}
            </div>
          </div>

          {/* Staff */}
          <div>
            <h2 className="text-lg font-semibold mb-4">Staff ({staff.length})</h2>
            <div className="bg-white rounded-lg border p-4 space-y-3">
              {staff.map(s => (
                <div key={s.id} className="border-b pb-3 last:border-0">
                  <div className="font-medium">{s.name}</div>
                  <div className="text-sm text-slate-500">{s.mobileNumber} · {s.helpTypeName}</div>
                  {s.agencyName && <div className="text-xs text-slate-400">Agency: {s.agencyName}</div>}
                </div>
              ))}
              {staff.length === 0 && <p className="text-slate-500">No staff registered.</p>}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DailyHelp;