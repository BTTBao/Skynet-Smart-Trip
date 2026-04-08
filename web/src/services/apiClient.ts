import axios from 'axios';

// Lấy URL từ file .env (hoặc mặc định là 5110 theo launchSettings.json)
const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5110/api';

const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  // timeout: 10000,
});

// Có thể thêm interceptors sau này để xử lý Authorization token
apiClient.interceptors.request.use(
  (config) => {
    // const token = localStorage.getItem('token');
    // if (token) {
    //   config.headers.Authorization = `Bearer ${token}`;
    // }
    return config;
  },
  (error) => Promise.reject(error)
);

export default apiClient;
