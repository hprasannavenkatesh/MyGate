// src/api/memberAdmin.ts
import apiClient from './client';
import {API_URLS} from "./apiConfig";

// ─── User Lookup (IdentityService 5103) ───
export interface UserLookupDto {
  userId: string;
  fullName: string;
  mobileNumber: string;
  email: string | null;
  isMobileVerified: boolean;
}

export const lookupUser = async (mobileNumber: string): Promise<UserLookupDto | null> => {
  try {
    const response = await apiClient.get<UserLookupDto>(
      `${API_URLS.IDENTITY}/api/Auth/lookup/${mobileNumber}`
    );
    return response.data;
  } catch (err: any) {
    if (err.response?.status === 404) return null;
    throw err;
  }
};

// ─── Add Member (TenantService 5104) ───
// Matches C# AddMemberCommand EXACTLY:
//   public Guid SocietyId { get; set; }
//   public Guid UserId { get; set; }
//   public Guid FlatId { get; set; }
//   public string MemberType { get; set; }
//   public bool IsPrimary { get; set; }
// .NET System.Text.Json serializes to camelCase by default.

export interface AddMemberPayload {
  societyId: string;
  userId: string;
  flatId: string;
  memberType: string;  // "Owner" | "Tenant" | "CommitteeMember"
  isPrimary: boolean;
}

// --- Create Guard (IdentityService 5103) ---
export interface CreateGuardPayload {
  mobileNumber: string;
  fullName: string;
}

export const createGuard = async (payload: CreateGuardPayload): Promise<{ id: string }> => {
  const response = await apiClient.post(
    `${API_URLS.IDENTITY}/auth/create-guard`,
    payload
  );
  return response.data;
};

export const addMember = async (payload: AddMemberPayload): Promise<any> => {
  const response = await apiClient.post(
    `${API_URLS.TENANT}/api/Societies/add-member`,
    payload
  );
  return response.data;
};

// ─── Register User (IdentityService 5103) ───
export interface RegisterUserPayload {
  mobileNumber: string;
  fullName: string;
  email?: string;
  password: string; // The backend requires this now
}

export const registerUser = async (payload: RegisterUserPayload): Promise<{ id: string }> => {
  const response = await apiClient.post(
    `${API_URLS.IDENTITY}/api/auth/register`,
    payload
  );
  return response.data;
};