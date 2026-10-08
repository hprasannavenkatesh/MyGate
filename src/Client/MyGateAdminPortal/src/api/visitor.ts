// src/api/visitor.ts
import apiClient from './client';
import {API_URLS} from "./apiConfig";

// --- Interfaces matching your C# Classes ---

// Matches: PreApproveVisitorCommand
export interface PreApproveVisitorCommand {
  visitorName: string;
  visitorMobile: string;
  vehicleNumber?: string;
  purpose: string;
  //inviterId: string; // Guid
  invitedByUserId: string;   // Match C# InvitedByUserId
  //expectedArrival: string; // DateTime
   expectedDate: string;      // Match C# ExpectedDate
  societyId: string; // <--- ADD THIS
  flatId: string; // <--- ADD THIS
}
// NEW: Pre-approve now returns OTP too
export interface PreApproveVisitorResult {
  id: string;
  otp: string;
}


// Updated to match PreApprovedVisitor entity fields
export interface VisitorDto {
  id: string;
  societyId: string;
  invitedByUserId: string;
  flatId: string;
  visitorName: string;
  visitorMobile: string;
  purpose?: string;
  expectedDate: string;
  expectedTime?: string;
  status: string;
  otpHash?: string;
  otpExpiresAt?: string;
}

// Matches: VerifyVisitorOtpCommand
export interface VerifyVisitorOtpCommand {
  //visitorId: string;
  preApprovalId:string;
  otp: string;
}

// Matches: MarkVisitorExitCommand
export interface MarkVisitorExitCommand {
 // visitorId: string;
  preApprovalId: string;
}

// NEW: Regenerate OTP response
export interface RegenerateOtpResult {
  otp: string;
  expiresAt: string;
}

export interface ManualEntryCommand {
  preApprovalId: string;
  reason: string;
}

// --- API Functions ---

// ADMIN: Get all visitors for a society
export const getSocietyVisitors = async (societyId: string): Promise<VisitorDto[]> => {
  const response = await apiClient.get<VisitorDto[]>(`${API_URLS.VISITOR}/Visitors/society/${societyId}`);
  return response.data;
};


// 1. RESIDENT: GET: api/Visitors/my-visitors?inviterId=...
export const getMyVisitors = async (inviterId: string): Promise<VisitorDto[]> => {
  const response = await apiClient.get<VisitorDto[]>(`${API_URLS.VISITOR}/Visitors/my-visitors`, {
    params: { inviterId }
  });
  return response.data;
};


// CHANGED: Now returns PreApproveVisitorResult (includes OTP)
export const preApproveVisitor = async (command: PreApproveVisitorCommand): Promise<PreApproveVisitorResult> => {
  const response = await apiClient.post<PreApproveVisitorResult>(`${API_URLS.VISITOR}/pre-approve`, command);
  return response.data;
};

// 3. POST: api/Visitors/verify-otp
export const verifyVisitorOtp = async (command: VerifyVisitorOtpCommand) => {
  const response = await apiClient.post<any>(`${API_URLS.VISITOR}/verify-otp`, command);
  return response.data;
};

// 4. POST: api/Visitors/mark-exit
export const markVisitorExit = async (command: MarkVisitorExitCommand) => {
  await apiClient.post(`${API_URLS.VISITOR}/mark-exit`, command);
};

// NEW: Regenerate OTP for an existing visitor
export const regenerateOtp = async (preApprovalId: string): Promise<RegenerateOtpResult> => {
  const response = await apiClient.post<RegenerateOtpResult>(`${API_URLS.VISITOR}/${preApprovalId}/regenerate-otp`);
  return response.data;
};

// ADMIN: Manual entry override
export const manualEntry = async (command: ManualEntryCommand) => {
  await apiClient.post(`${API_URLS.VISITOR}/${command.preApprovalId}/manual-entry`, command);
};

// Walk-in entry: creates visitor AND marks as entered in one step
export const walkInEntry = async (command: PreApproveVisitorCommand): Promise<PreApproveVisitorResult> => {
  // Step 1: Pre-approve (creates record + generates OTP)
  const result = await preApproveVisitor(command);
  // Step 2: Manual entry (marks as Entered without OTP)
  await manualEntry({ preApprovalId: result.id, reason: 'Walk-in entry at gate' });
  return result;
};