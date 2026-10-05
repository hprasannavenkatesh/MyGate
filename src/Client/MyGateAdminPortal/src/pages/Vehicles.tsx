// src/pages/Vehicles.tsx
import { useState, useEffect } from 'react';
import { getSocietyVehicles, getSocietySlots, type VehicleDto, type ParkingSlotDto } from '../api/vehicle';
import { useAuth } from '../context/AuthContext';
import { Loader2, Car, MapPin } from 'lucide-react';

const vehicleTypeMap: Record<number, string> = {
  0: 'Two Wheeler',
  1: 'Four Wheeler',
  2: 'Visitor',
};

const Vehicles = () => {
  const { currentUser } = useAuth();
  const [vehicles, setVehicles] = useState<VehicleDto[]>([]);
  const [slots, setSlots] = useState<ParkingSlotDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchVehicleData = async () => {
      if (!currentUser?.societyId) {
        setLoading(false);
        return;
      }
      setLoading(true);
      setError(null);
      try {
        const [vehicleData, slotData] = await Promise.all([
          getSocietyVehicles(currentUser.societyId),
          getSocietySlots(currentUser.societyId)
        ]);
        setVehicles(vehicleData);
        setSlots(slotData);
      } catch (err) {
        console.error('Failed to fetch vehicle data:', err);
        setError('Failed to load vehicle data. Ensure VehicleService (5112) is running.');
      } finally {
        setLoading(false);
      }
    };
    fetchVehicleData();
  }, [currentUser?.societyId]);

  if (loading) {
    return (
      <div className="p-8 flex justify-center items-center min-h-[60vh]">
        <Loader2 className="animate-spin text-blue-500 w-8 h-8" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-md">
          {error}
        </div>
      </div>
    );
  }

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Vehicles & Parking</h1>
      
      {/* SECTION 1: The 2D Parking Visualizer */}
      <div className="mb-10">
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <MapPin className="text-blue-600" size={20} />
          Parking Slots (Live View)
        </h2>
        
        {slots.length === 0 ? (
          <p className="text-slate-500">No parking slots configured for this society.</p>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            {slots.map((slot) => (
              <div
                key={slot.id}
                className={`
                  relative border-2 rounded-lg flex flex-col items-center justify-center p-4 transition-all min-h-[120px]
                  ${slot.isOccupied 
                    ? 'bg-green-50 border-green-200 hover:border-green-400' 
                    : 'bg-slate-50 border-dashed border-slate-300 hover:border-blue-400 hover:bg-blue-50'
                  }
                `}
              >
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                  {slot.slotNumber}
                </span>

                {slot.isOccupied ? (
                  <div className="text-center">
                    <Car className="mx-auto text-green-600 mb-2" size={32} />
                    <div className="text-xs text-green-700 font-medium">Occupied</div>
                  </div>
                ) : (
                  <div className="text-slate-300 text-center">
                    <Car size={32} className="mx-auto mb-1" />
                    <div className="text-xs mt-1 font-medium">Empty</div>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/*5112 SECTION 2: Registered Vehicles List */}
      <div>
        <h2 className="text-lg font-semibold mb-4">Registered Vehicles ({vehicles.length})</h2>
        <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b border-slate-200">
                <tr>
                  <th className="px-6 py-3 font-medium">Vehicle Number</th>
                  <th className="px-6 py-3 font-medium">Type</th>
                  <th className="px-6 py-3 font-medium">Category</th>
                  <th className="px-6 py-3 font-medium">Status</th>
                  <th className="px-6 py-3 font-medium">Parking Slot</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {vehicles.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="p-8 text-center text-slate-500">
                      No vehicles registered in this society.
                    </td>
                  </tr>
                ) : vehicles.map((vehicle) => (
                  <tr key={vehicle.id} className="hover:bg-slate-50">
                    <td className="px-6 py-4 font-mono font-medium text-slate-800">{vehicle.vehicleNumber}</td>
                    <td className="px-6 py-4 text-slate-600">{vehicleTypeMap[vehicle.vehicleType] || 'Unknown'}</td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-xs font-medium ${vehicle.category === 0 ? 'bg-blue-100 text-blue-700' : 'bg-orange-100 text-orange-700'}`}>
                        {vehicle.category === 0 ? 'Resident' : 'Guest'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-xs font-medium ${vehicle.isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                        {vehicle.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {vehicle.parkingSlotId ? (
                        <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800">
                          {vehicle.parkingSlotId.substring(0, 8)}...
                        </span>
                      ) : (
                        <span className="text-red-500 text-xs font-medium">No Slot Allocated</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Vehicles;