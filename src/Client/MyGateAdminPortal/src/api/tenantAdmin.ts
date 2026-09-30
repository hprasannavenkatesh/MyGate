// src/api/tenantAdmin.ts
import apiClient from './client';

// --- Interfaces ---
export interface Society {
  id: string;
  name: string;
  address: string;
  city: string;
}

export interface Block {
  id: string;
  societyId: string;
  name: string;
}

export interface Flat {
  id: string;
  blockId: string;
  societyId: string;
  flatNumber: string;
  flatType: number; // 0 = Flat, 1 = Villa, etc.
}

// --- Society APIs ---
export const getAllSocieties = async (): Promise<Society[]> => {
  const res = await apiClient.get<Society[]>('http://localhost:5104/api/Societies');
  return res.data;
};

export const createSociety = async (data: { name: string; address: string; city: string }): Promise<any> => {
  const res = await apiClient.post('http://localhost:5104/api/Societies/create', data);
  return res.data;
};

// --- Block APIs ---
export const getBlocksBySociety = async (societyId: string): Promise<Block[]> => {
  const res = await apiClient.get<Block[]>(`http://localhost:5104/api/Societies/${societyId}/blocks`);
  return res.data;
};

export const createBlock = async (data: { societyId: string; name: string }): Promise<any> => {
  const res = await apiClient.post('http://localhost:5104/api/Societies/create-block', data);
  return res.data;
};

// --- Flat APIs ---
export const getFlatsByBlock = async (blockId: string): Promise<Flat[]> => {
  const res = await apiClient.get<Flat[]>(`http://localhost:5104/api/Societies/blocks/${blockId}/flats`);
  return res.data;
};

export const createFlat = async (data: { blockId: string; societyId: string; flatNumber: string; flatType: string }): Promise<any> => {
      const payload = {
    blockId: data.blockId,
    // societyId: data.societyId, // C# command doesn't use it currently
    flatNumber: data.flatNumber,
    type: data.flatType // RENAMED: React calls it flatType, but .NET expects "type"
  };
   const res = await apiClient.post('http://localhost:5104/api/Societies/create-flat', payload);
  //const res = await apiClient.post('http://localhost:5104/api/Societies/create-flat', data);

  return res.data;
};