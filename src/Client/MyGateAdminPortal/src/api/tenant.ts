// src/api/tenant.ts
import apiClient from "./client";
import {API_URLS} from "./apiConfig";

// Matches the C# SocietyDto from TenantService
export interface SocietyDto {
  societyId: string;
  societyName: string;
  blockName: string;
  flatId: string;
  flatNumber: string;
  memberType: string; // "Owner", "Tenant", "CommitteeMember", etc.
}


export interface SocietyListDto {
  id: string;
  name: string;
  address?: string;
  city?: string;
}

// Fetch societies/contexts for a specific user
export const getMySocieties = async (userId: string): Promise<SocietyDto[]> => {
  // Explicitly grab the token to ensure the Authorization header is set
  const token = localStorage.getItem("auth_token");
  console.log("token in getMySocieties:", token);
  const response = await apiClient.get<SocietyDto[]>(
    `${API_URLS.TENANT}/Societies/my-societies`,
    {
      params: { userId },
      headers: {
        Authorization: `Bearer ${token}`, // Force the header!
      },
    },
  );
  return response.data;
};

// Fetch ALL societies for the SuperAdmin Society Picker
export const getAllSocietiesForSuperAdmin = async (): Promise<SocietyListDto[]> => {
  const token = localStorage.getItem("auth_token");
 // DEBUG: Log the exact URL and Token being used
  console.log('🪲 [DEBUG] Fetching SuperAdmin Societies');
  console.log('🪲 [DEBUG] Token:', token);

 /* const response = await apiClient.get<SocietyListDto[]>(
     `${API_URLS.IDENTITY}/superadmin/societies`, // Hits IdentityService proxy
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  );*/
  // EXPLICIT URL: Bypass client.ts baseURL to guarantee the path is correct
  const response = await apiClient.get<SocietyListDto[]>(
     `http://localhost:5103/api/superadmin/societies`, 
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  );
  
  // DEBUG: Log the response
  console.log('🪲 [DEBUG] SuperAdmin API Response:', response.data);
  return response.data;
};
