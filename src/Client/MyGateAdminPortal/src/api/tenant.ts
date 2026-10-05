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
  const response = await apiClient.get<SocietyListDto[]>(
     `${API_URLS.TENANT}/api/superadmin/societies`, // Hits IdentityService proxy
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  );
  return response.data;
};
