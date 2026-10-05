// src/api/apiConfig.ts

// Centralized API Base URLs for all Microservices
// Change these here when deploying to different environments (e.g., Docker, Staging, Prod)
export const API_URLS = {
  IDENTITY: 'http://localhost:5103/api',
  TENANT: 'http://localhost:5104/api',
  VISITOR: 'http://localhost:5105/api',
  BILLING: 'http://localhost:5107/api',
  HELPDESK: 'http://localhost:5108/api',
  NOTICE: 'http://localhost:5109/api',
  AMENITY: 'http://localhost:5110/api',
  DAILY_HELP: 'http://localhost:5111/api',
  VEHICLE: 'http://localhost:5112/api',
 // COMMUNICATION: 'http://localhost:5113/api',
  EMERGENCY: 'http://localhost:5114/api',
  DIRECTORY: 'http://localhost:5113/api',
};