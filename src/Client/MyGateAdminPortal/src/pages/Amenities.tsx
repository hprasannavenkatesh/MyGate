// src/pages/Amenities.tsx
import { useState, useEffect } from 'react';
import { getAmenities, type AmenityDto } from '../api/amenity';
import { useAuth } from '../context/AuthContext';
import { MapPin, Clock } from 'lucide-react';

const Amenities = () => {
  const { currentUser } = useAuth();
  const [amenities, setAmenities] = useState<AmenityDto[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAmenities = async () => {
    if (!currentUser?.societyId) return;
    setLoading(true);
    try {
      const data = await getAmenities(currentUser.societyId);
      setAmenities(data);
    } catch (err) {
      console.error("Failed to fetch amenities", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchAmenities(); }, [currentUser?.societyId]);

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Society Amenities</h1>

      {loading ? <div className="text-center py-10 text-slate-500">Loading...</div> : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {amenities.length === 0 ? <div className="text-slate-500 col-span-3">No amenities configured.</div> : 
            amenities.map(a => (
              <div key={a.id} className="bg-white p-6 rounded-lg shadow-sm border border-slate-200 flex flex-col">
                <div className="flex justify-between items-start mb-4">
                  <h3 className="text-lg font-semibold text-slate-800">{a.name}</h3>
                  <span className={`text-xs px-2 py-1 rounded ${a.isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                    {a.isActive ? 'Active' : 'Inactive'}
                  </span>
                </div>
                
                <p className="text-sm text-slate-500 mb-4 flex-1">{a.description || 'No description'}</p>
                
                <div className="border-t pt-4 mt-auto space-y-2 text-sm text-slate-600">
                  {a.location && <div className="flex items-center gap-2"><MapPin size={14} /> {a.location}</div>}
                  <div className="flex items-center gap-2"><Clock size={14} /> {a.operatingHoursStart} - {a.operatingHoursEnd}</div>
                  <div>Slot: {a.slotDurationMinutes} min | Max/Day: {a.maxBookingsPerDayPerUser}</div>
                </div>
              </div>
            ))
          }
        </div>
      )}
    </div>
  );
};

export default Amenities;