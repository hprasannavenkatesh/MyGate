import apiClient from './client';
import {API_URLS} from "./apiConfig";

export interface TicketDto {
  id: string;
  societyId: string;
  flatId: string;
  createdByUserId: string;
  title: string;
  description: string;
  status: number;
  createdAt: string;
}

export const getSocietyTickets = async (societyId: string): Promise<TicketDto[]> => {
  const response = await apiClient.get<TicketDto[]>(
    `${API_URLS.HELPDESK}/Tickets/society/${societyId}`
  );
  return response.data;
};

export const updateTicketStatus = async (ticketId: string, newStatus: number): Promise<void> => {
  await apiClient.put(`${API_URLS.HELPDESK}/Tickets/${ticketId}/status`, { newStatus });
};