import { useParams } from 'react-router-dom';
import HotelsAdminPage from './HotelsAdminPage';
import HotelDetailPage from './HotelDetailPage';

export default function HotelsPage() {
  const { hotelId } = useParams();

  if (hotelId) {
    return <HotelDetailPage hotelId={Number(hotelId)} />;
  }

  return <HotelsAdminPage />;
}
