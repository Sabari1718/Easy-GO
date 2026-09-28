import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository();
});

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: 'n1',
      title: 'Bus Delay',
      message: 'BUS 102 on Route 12 is delayed by 5 minutes due to traffic.',
      category: NotificationCategory.busUpdate,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    NotificationModel(
      id: 'n2',
      title: 'Route Diversion',
      message: 'Route 5 is diverted due to road construction at Railway Station.',
      category: NotificationCategory.routeUpdate,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'n3',
      title: 'Service Resumed',
      message: 'BUS 103 breakdown resolved. Service resumed.',
      category: NotificationCategory.serviceAlert,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockNotifications;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(isRead: true);
    }
  }
}
