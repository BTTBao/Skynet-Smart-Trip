import { RouterProvider } from 'react-router-dom';
import router from './routers/routers';

export default function App() {
  return <RouterProvider router={router} />;
}
