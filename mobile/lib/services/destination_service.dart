import '../models/destination.dart';
import 'api_service_base.dart';

class DestinationService extends ApiService {
  Future<List<Destination>> getDestinations() async {
    try {
      final response = await getWithFallback('/destination', requireAuth: false);
      final List<dynamic> data = handleResponse(response);
      return data.map((e) => Destination.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
