import apiClient from './client';
import {API_URLS} from "./apiConfig";

export interface HelpTypeDto { id: string; name: string; }
export interface StaffDto { id: string; name: string; mobileNumber: string; helpTypeId: string; helpTypeName: string; agencyName: string | null; isActive: boolean; }
export interface AssignmentDto { id: string; staffId: string; staffName: string; staffMobile: string; helpTypeName: string; flatId: string; workingDays: string; inTime: string | null; outTime: string | null; isActive: boolean; }

export const getHelpTypes = async (societyId: string): Promise<HelpTypeDto[]> => {
  const response = await apiClient.get<HelpTypeDto[]>(`${API_URLS.DAILY_HELP}/HelpTypes/society/${societyId}`);
  return response.data;
};

export const getStaff = async (societyId: string): Promise<StaffDto[]> => {
  const response = await apiClient.get<StaffDto[]>(`${API_URLS.DAILY_HELP}/Staff/society/${societyId}`);
  return response.data;
};

export const getAssignments = async (flatId: string): Promise<AssignmentDto[]> => {
  const response = await apiClient.get<AssignmentDto[]>(`${API_URLS.DAILY_HELP}/Assignments/my-help?flatId=${flatId}`);
  return response.data;
};

export const createHelpType = async (societyId: string, name: string): Promise<string> => {
  const response = await apiClient.post<string>(`${API_URLS.DAILY_HELP}/HelpTypes`, { societyId, name });
  return response.data;
};

export const createStaff = async (payload: { societyId: string; name: string; mobileNumber: string; helpTypeId: string; agencyName?: string }): Promise<string> => {
  const response = await apiClient.post<string>(`${API_URLS.DAILY_HELP}/Staff`, payload);
  return response.data;
};

export const assignStaff = async (payload: { staffId: string; flatId: string; societyId: string; workingDays?: string }): Promise<string> => {
  const response = await apiClient.post<string>(`${API_URLS.DAILY_HELP}/Assignments`, payload);
  return response.data;
};