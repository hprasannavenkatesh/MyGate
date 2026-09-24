// src/api/visitor.ts
import apiClient from './client';

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

// Matches: VisitorDto (The result of GetMyVisitors)
export interface VisitorDto {
  id: string; // Guid in C#
  visitorName: string;
  visitorMobile: string;
  vehicleNumber?: string;
  purpose: string;
  status: string; // e.g., "PreApproved", "Entered", "Exited"
  createdDate: string; // DateTime
}

// Matches: VerifyVisitorOtpCommand
export interface VerifyVisitorOtpCommand {
  visitorId: string;
  otp: string;
}

// Matches: MarkVisitorExitCommand
export interface MarkVisitorExitCommand {
  visitorId: string;
}

// --- API Functions ---

// 1. GET: api/Visitors/my-visitors?inviterId=...
export const getMyVisitors = async (inviterId: string): Promise<VisitorDto[]> => {
  const response = await apiClient.get<VisitorDto[]>('/Visitors/my-visitors', {
    params: { inviterId }
  });
  return response.data;
};

// 2. POST: api/Visitors/pre-approve
export const preApproveVisitor = async (command: PreApproveVisitorCommand) => {
  const response = await apiClient.post<any>('/Visitors/pre-approve', command);
  return response.data; // Returns { Id: "..." }
};

// 3. POST: api/Visitors/verify-otp
export const verifyVisitorOtp = async (command: VerifyVisitorOtpCommand) => {
  const response = await apiClient.post<any>('/Visitors/verify-otp', command);
  return response.data;
};

// 4. POST: api/Visitors/mark-exit
export const markVisitorExit = async (command: MarkVisitorExitCommand) => {
  await apiClient.post('/Visitors/mark-exit', command);
};