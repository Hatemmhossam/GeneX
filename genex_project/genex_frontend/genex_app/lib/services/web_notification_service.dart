import 'dart:html' as html;

class WebNotificationService {
  static Future<void> requestPermission() async {
    if (!html.Notification.supported) {
      print("❌ Notifications not supported");
      return;
    }

    final permission = await html.Notification.requestPermission();
    print("🔔 Notification permission: $permission");
  }

  static void showNotification({
    required String title,
    required String body,
  }) {
    if (!html.Notification.supported) return;

    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    } else {
      print("❌ Notification permission not granted");
    }
  }
}