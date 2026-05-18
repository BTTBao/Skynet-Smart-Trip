import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { AdminSearchProvider, AuthProvider, ToastProvider } from './context'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ToastProvider>
      <AuthProvider>
        <AdminSearchProvider>
          <App />
        </AdminSearchProvider>
      </AuthProvider>
    </ToastProvider>
  </StrictMode>,
)
