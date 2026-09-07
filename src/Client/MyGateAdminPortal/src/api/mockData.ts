// src/api/mockData.ts
import { Users, DollarSign, Car, Activity } from 'lucide-react';

export interface DashboardStats {
  totalResidents: number;
  pendingDues: number;
  parkingOccupancy: number;
  activeNotices: number;
}

export interface Activity {
  id: number;
  time: string;
  service: string;
  event: string;
  user: string;
}

// Fake data to mimic a backend API response
export const getDashboardData = (): { stats: DashboardStats; activities: Activity[] } => {
  return {
    stats: {
      totalResidents: 124,
      pendingDues: 45000,
      parkingOccupancy: 65,
      activeNotices: 3
    },
    activities: [
      { id: 1, time: '10:42 AM', service: 'VisitorService', event: 'Created Pre-approval', user: 'Res-101' },
      { id: 2, time: '10:30 AM', service: 'VehicleService', event: 'Entry Gate Opened', user: 'Guard-02' },
      { id: 3, time: '09:15 AM', service: 'BillingService', event: 'Invoice Generated', user: 'System' },
      { id: 4, time: '08:00 AM', service: 'AmenityService', event: 'Pool Booking', user: 'Res-204' },
    ]
  };
};

// src/api/mockData.ts

// ... existing code (DashboardStats, Activity, getDashboardData) ...

// ADD THIS NEW CODE:

export interface Visitor {
  id: number;
  name: string;
  type: string; // Guest, Delivery, Cab
  purpose: string;
  status: 'Pending' | 'Approved' | 'Rejected';
  time: string;
}

export const initialVisitors: Visitor[] = [
  { id: 1, name: "John Doe", type: "Guest", purpose: "Meeting", status: "Pending", time: "10:30 AM" },
  { id: 2, name: "Alice Smith", type: "Delivery", purpose: "Amazon Package", status: "Approved", time: "09:15 AM" },
  { id: 3, name: "Bob Wilson", type: "Cab", purpose: "Uber Drop", status: "Pending", time: "10:45 AM" },
  { id: 4, name: "Charlie Brown", type: "Service", purpose: "Plumber", status: "Rejected", time: "Yesterday" },
];

// src/api/mockData.ts

// ... existing code ...

// ADD THIS NEW CODE:

export interface Vehicle {
  id: number;
  plate: string;
  model: string;
  type: string; // Sedan, SUV, Bike
  flat: string;
  slotId: string | null; // If null, the car is parked nowhere
}

export interface ParkingSlot {
  id: string;
  isOccupied: boolean;
  vehicle: Vehicle | null;
}

// Mock Vehicles
export const vehiclesData: Vehicle[] = [
  { id: 1, plate: "KA-01-AB-1234", model: "Honda City", type: "Sedan", flat: "B-204", slotId: "A-1" },
  { id: 2, plate: "MH-02-XY-5678", model: "Swift", type: "Hatchback", flat: "A-101", slotId: "A-2" },
  { id: 3, plate: "TN-07-ZZ-9999", model: "Innova", type: "SUV", flat: "C-305", slotId: null }, // No slot!
  { id: 4, plate: "KA-05-QQ-1111", model: "Baleno", type: "Hatchback", flat: "D-102", slotId: "B-1" },
];

// Mock Parking Slots (The 2D Map)
export const parkingSlotsData: ParkingSlot[] = [
  { id: "A-1", isOccupied: true, vehicle: vehiclesData[0] },
  { id: "A-2", isOccupied: true, vehicle: vehiclesData[1] },
  { id: "A-3", isOccupied: false, vehicle: null },
  { id: "A-4", isOccupied: false, vehicle: null },
  { id: "B-1", isOccupied: true, vehicle: vehiclesData[3] },
  { id: "B-2", isOccupied: false, vehicle: null },
  { id: "B-3", isOccupied: false, vehicle: null },
  { id: "B-4", isOccupied: false, vehicle: null },
];

// src/api/mockData.ts

// ... existing code ...

// ADD THIS NEW CODE:

export interface Bill {
  id: number;
  invoiceId: string;
  flat: string;
  month: string;
  amount: number;
  status: 'Paid' | 'Unpaid';
  dueDate: string;
}

export const billsData: Bill[] = [
  { id: 1, invoiceId: "INV-001", flat: "B-204", month: "October 2023", amount: 2500, status: "Unpaid", dueDate: "2023-10-10" },
  { id: 2, invoiceId: "INV-002", flat: "A-101", month: "October 2023", amount: 3200, status: "Paid", dueDate: "2023-10-10" },
  { id: 3, invoiceId: "INV-003", flat: "C-305", month: "September 2023", amount: 1500, status: "Unpaid", dueDate: "2023-09-10" },
  { id: 4, invoiceId: "INV-004", flat: "D-102", month: "October 2023", amount: 2800, status: "Unpaid", dueDate: "2023-10-10" },
];