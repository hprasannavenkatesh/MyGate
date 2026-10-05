import apiClient from './client';
import {API_URLS} from "./apiConfig";

export interface VehicleDto {
  id: string;
  societyId: string;
  flatId: string;
  ownerId: string;
  vehicleNumber: string;
  vehicleType: number;
  category: number;
  parkingSlotId: string | null;
  isActive: boolean;
}

export interface ParkingSlotDto {
  id: string;
  societyId: string;
  blockId: string;
  flatId: string | null;
  slotNumber: string;
  slotType: number;
  isOccupied: boolean;
}

export const getSocietyVehicles = async (societyId: string): Promise<VehicleDto[]> => {
  const response = await apiClient.get<VehicleDto[]>(
    `${API_URLS.VEHICLE}/society/${societyId}`
  );
  return response.data;
};

export const getSocietySlots = async (societyId: string): Promise<ParkingSlotDto[]> => {
  const response = await apiClient.get<ParkingSlotDto[]>(
    `${API_URLS.VEHICLE}/ParkingSlots/society/${societyId}`
  );
  return response.data;
};