import 'package:finora/data/notification_service.dart';

/// Records what would have been shown in the phone's notification tray.
class FakeNotificationService extends NotificationService {
  final shown = <({int id, String title, String body})>[];
  int permissionRequests = 0;

  List<String> get titles => [for (final n in shown) n.title];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async => shown.add((id: id, title: title, body: body));
}
