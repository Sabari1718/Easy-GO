import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/domain/models/notification_model.dart';
import '../../features/notifications/data/repositories/mock_notification_repository.dart';
import 'auth_providers.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final repository = ref.watch(notificationRepositoryProvider);
  return await repository.getNotifications(user.id);
});

final markNotificationReadProvider = FutureProvider.family<void, String>((ref, notificationId) async {
  final repository = ref.watch(notificationRepositoryProvider);
  await repository.markAsRead(notificationId);
  ref.invalidate(notificationsProvider);
});
