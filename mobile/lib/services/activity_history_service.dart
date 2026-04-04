import '../models/activity_history.dart';
import 'api_service_base.dart';

class ActivityHistoryService extends ApiService {
  Future<ActivityHistory> getActivityHistory(String userId) async {
    final response = await getWithFallback('/user/$userId/activity-history');
    final data = handleResponse(response);
    return ActivityHistory.fromJson(data);
  }
}
