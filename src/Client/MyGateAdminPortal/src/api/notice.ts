// src/api/notice.ts
import apiClient from './client';
import {API_URLS} from "./apiConfig";

export interface NoticeDto {
  id: string;
  societyId: string;
  title: string;
  description: string;
  category: number;
  isPinned: boolean;
  createdByUserId: string;
  createdAt: string;
}

// GET notices for a society
export const getNotices = async (societyId: string): Promise<NoticeDto[]> => {
  const response = await apiClient.get<NoticeDto[]>(
    `${API_URLS.NOTICE}/society/${societyId}`
  );
  return response.data;
};

// POST create a new notice (Admin only)
export const createNotice = async (notice: { societyId: string; title: string; description: string; category: number; isPinned: boolean }): Promise<string> => {
  const response = await apiClient.post<string>(`${API_URLS.NOTICE}`, notice);
  return response.data;
};