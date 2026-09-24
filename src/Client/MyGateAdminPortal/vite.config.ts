import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
   server: {
    port: 3000, // Run React on port 3000 (Standard React port)
    proxy: {
      // Any request starting with /api will be forwarded to your services
      '/api': {
        target: 'http://localhost:5105', // Your IdentityService/Gateway
        changeOrigin: true//,
        //rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  }
})
