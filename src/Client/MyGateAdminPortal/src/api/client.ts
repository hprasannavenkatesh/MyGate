import axios from 'axios';

// Create an instance
const apiClient = axios.create({
  baseURL: '/api', // Uses the Vite proxy defined earlier
  headers: {
    'Content-Type': 'application/json',
  },
});

// 1. Request Interceptor: Add JWT Token automatically
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token'); // Save JWT here after login
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 2. Response Interceptor: Handle 401/500 errors globally
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Redirect to login or refresh token logic
      console.error("Unauthorized access");
    }
    return Promise.reject(error);
  }
);

export default apiClient;