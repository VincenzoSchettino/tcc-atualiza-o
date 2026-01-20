import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'package:tcc_3/services/notification_service.dart';
import 'package:tcc_3/main.dart' show navigatorKey;


class FirebaseMessagingService {
  final AppNotification _notification;

  FirebaseMessagingService(this._notification);

  Future<void> initialize() async {
    // 1) Permissão (iOS e Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // (opcional) Token para backend
    // final token = await FirebaseMessaging.instance.getToken();
    // print('FCM Token: $token');

    // 2) Foreground: app aberto -> mostra notificação local
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification != null) {
        await _notification.showNow(
          id: notification.hashCode,
          title: notification.title ?? 'ImunizaKids',
          body: notification.body ?? '',
        );
      }
    });

    // 3) Background: app estava em background e usuário clicou
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handlePushNavigation(message);
    });

    // 4) App fechado (killed): abriu clicando na notificação
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePushNavigation(initialMessage);
      });
    }
  }

  void _handlePushNavigation(RemoteMessage message) {
    final data = message.data;
    final route = data['route']?.toString();

    if (route == null || route.isEmpty) return;

    // Exemplo esperado do backend (data):
    // {
    //   "route": "/vacinas-filho",
    //   "usuarioId": "xxx",
    //   "filhoId": "yyy"
    // }
    if (route == '/vacinas-filho') {
      final usuarioId = data['usuarioId']?.toString();
      final filhoId = data['filhoId']?.toString();

      if (usuarioId != null && filhoId != null) {
        navigatorKey.currentState?.pushNamed(
          '/vacinas-filho',
          arguments: {
            'usuarioId': usuarioId,
            'filhoId': filhoId,
          },
        );
      }
      return;
    }

    // fallback: navega para a rota recebida
    navigatorKey.currentState?.pushNamed(route);
  }
}
