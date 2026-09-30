// src/api/memberAdmin.ts
import apiClient from './client';

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
      `http://localhost:5103/api/Auth/lookup/${mobileNumber}`
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

export const addMember = async (payload: AddMemberPayload): Promise<any> => {
  const response = await apiClient.post(
    'http://localhost:5104/api/Societies/add-member',
    payload
  );
  return response.data;
};