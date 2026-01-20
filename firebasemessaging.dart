import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseMsg {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initFCM() async {
    try {
      // Permissões iOS (seguro tanto para Android quanto iOS)
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Obtém e loga o token (salve quando precisar)
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');

      // Listeners básicos (opcional)
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('onMessage: ${message.messageId}');
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('onMessageOpenedApp: ${message.messageId}');
      });
    } catch (e) {
      debugPrint('Erro initFCM: $e');
    }
  }
}