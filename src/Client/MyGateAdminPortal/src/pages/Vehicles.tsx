// src/pages/Vehicles.tsx
import React from 'react';
import { vehiclesData, parkingSlotsData, type Vehicle } from '../api/mockData';
import { Car, MapPin } from 'lucide-react';

const Vehicles = () => {
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Vehicles & Parking</h1>
      
      {/* SECTION 1: The 2D Parking Visualizer */}
      <div className="mb-10">
        <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <MapPin className="text-blue-600" size={20} />
          Basement Level 1 (Live View)
        </h2>
        
        {/* THE GRID */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {parkingSlotsData.map((slot) => (
            <div
              key={slot.id}
              className={`
                relative border-2 rounded-lg flex flex-col items-center justify-center p-4 transition-all
                ${slot.isOccupied 
                  ? 'bg-green-50 border-green-200 hover:border-green-400' 
                  : 'bg-slate-50 border-dashed border-slate-300 hover:border-blue-400 hover:bg-blue-50'
                }
              `}
            >
              {/* Slot ID */}
              <span className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                {slot.id}
              </span>

              {/* Car Icon or Placeholder */}
              {slot.isOccupied && slot.vehicle ? (
                <div className="text-center">
                  <Car className="mx-auto text-green-600 mb-2" size={32} />
                  <div className="font-bold text-slate-800 text-sm">{slot.vehicle.plate}</div>
                  <div className="text-xs text-slate-500">{slot.vehicle.model}</div>
                </div>
              ) : (
                <div className="text-slate-300">
                  <Car size={32} />
                  <div className="text-xs mt-1 font-medium">Empty</div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* SECTION 2: Registered Vehicles List */}
      <div>
        <h2 className="text-lg font-semibold mb-4">Registered Vehicles</h2>
        <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b border-slate-200">
                <tr>
                  <th className="px-6 py-3 font-medium">Flat</th>
                  <th className="px-6 py-3 font-medium">Model</th>
                  <th className="px-6 py-3 font-medium">Plate Number</th>
                  <th className="px-6 py-3 font-medium">Type</th>
                  <th className="px-6 py-3 font-medium">Current Slot</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {vehiclesData.map((vehicle) => (
                  <tr key={vehicle.id} className="hover:bg-slate-50">
                    <td className="px-6 py-4 font-medium text-slate-700">{vehicle.flat}</td>
                    <td className="px-6 py-4 text-slate-600">{vehicle.model}</td>
                    <td className="px-6 py-4 text-slate-800 font-mono">{vehicle.plate}</td>
                    <td className="px-6 py-4 text-sm text-slate-500">{vehicle.type}</td>
                    <td className="px-6 py-4">
                      {vehicle.slotId ? (
                        <span className="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800">
                          {vehicle.slotId}
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