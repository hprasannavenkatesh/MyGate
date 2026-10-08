import apiClient from './client';
import {API_URLS} from "./apiConfig";

export interface DirectoryEntryDto {
  id: string;
  societyId: string;
  category: string;
  name: string;
  contactNumber: string;
  email: string | null;
  address: string | null;
  notes: string | null;
  isActive: boolean;
  createdAt: string;
}

export const getDirectory = async (societyId: string): Promise<DirectoryEntryDto[]> => {
  const response = await apiClient.get<DirectoryEntryDto[]>(
    `${API_URLS.DIRECTORY}/Directory/society/${societyId}`
  );
  return response.data;
};

export const getCategories = async (societyId: string): Promise<string[]> => {
  const response = await apiClient.get<string[]>(
    `${API_URLS.DIRECTORY}/Directory/categories/${societyId}`
  );
  return response.data;
};