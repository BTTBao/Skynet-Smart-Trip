import '../models/activity_history.dart';
import 'api_service_base.dart';

class ActivityHistoryService extends ApiService {
  Future<ActivityHistory> getActivityHistory() async {
    final response = await getWithFallback(
      '/user/me/activity-history',
      requireAuth: true,
    );
    final data = handleResponse(response);
    return ActivityHistory.fromJson(data);
  }
}
