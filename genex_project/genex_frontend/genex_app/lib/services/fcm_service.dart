import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
static Future<String?> getToken() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    return FirebaseMessaging.instance.getToken(
      vapidKey: "BHUQMmRFe_1JpnjaIKoB1-OV4ysghk5JPXQUZtjQcu1Qh_3jEZ1oJBzmFC-LY4vcbQt1zhntEyk9aNCkXJ8TdMo",
    );
  }

  return null;
}
}