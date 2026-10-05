import apiClient from './client';
import {API_URLS} from "./apiConfig";

export interface InvoiceDto {
  id: string;
  societyId: string;
  flatId: string;
  amount: number;
  penaltyAmount: number;
  totalAmount: number;
  dueDate: string;
  invoiceNumber: string | null;
  description: string | null;
  status: number; // 0=Pending, 1=Paid, 2=Overdue, 3=Waived, 4=PartiallyPaid
  generatedAt: string;
}

export const getSocietyInvoices = async (societyId: string): Promise<InvoiceDto[]> => {
  const response = await apiClient.get<InvoiceDto[]>(
    `${API_URLS.BILLING}/Invoices/society/${societyId}`
  );
  return response.data;
};

export const generateInvoice = async (payload: {
  societyId: string;
  flatId: string;
  amount: number;
  dueDate: string;
  description?: string;
}): Promise<string> => {
  const response = await apiClient.post<string>(
    `${API_URLS.BILLING}/Invoices/generate`,
    payload
  );
  return response.data;
};