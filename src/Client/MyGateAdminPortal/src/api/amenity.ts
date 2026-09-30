// src/api/amenity.ts
import apiClient from './client';

export interface AmenityDto {
  id: string;
  societyId: string;
  name: string;
  description: string | null;
  location: string | null;
  isActive: boolean;
  isBookable: boolean;
  slotDurationMinutes: number;
  maxBookingsPerDayPerUser: number;
  advanceBookingDaysAllowed: number;
  operatingHoursStart: string;
  operatingHoursEnd: string;
  createdAt: string;
}

// GET amenities for a society
export const getAmenities = async (societyId: string): Promise<AmenityDto[]> => {
  const response = await apiClient.get<AmenityDto[]>(
    `http://localhost:5110/api/Amenities/society/${societyId}`
  );
  return response.data;
};

// POST create a new amenity (Admin only)
export const createAmenity = async (amenity: any): Promise<string> => {
  const response = await apiClient.post<string>('http://localhost:5110/api/Amenities', amenity);
  return response.data;
};