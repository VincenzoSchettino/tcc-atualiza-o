import 'dart:io';

// TIMEZONE
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// PLUGINS
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

class AppNotification {
  // Singleton
  AppNotification._();
  static final AppNotification instance = AppNotification._();

  final fln.FlutterLocalNotificationsPlugin _local =
      fln.FlutterLocalNotificationsPlugin();

  static const String channelId = 'vacinas_channel';
  static const String channelName = 'Lembretes de Vacinação';
  static const String channelDesc =
      'Alertas de vacinas e lembretes do ImunizaKids';

  // ===============================
  // 🔔 INICIALIZAÇÃO (FINAL)
  // ===============================
  Future<void> initialize({
    required void Function(fln.NotificationResponse) onTap,
    required void Function(fln.NotificationResponse) onTapBackground,
  }) async {
    // 1️⃣ Timezone
    tz.initializeTimeZones();
    try {
      // Adicione .identifier no final e envolva o await em parênteses
      final String timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    // 2️⃣ Init settings
    const androidInit =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = fln.InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // 3️⃣ Inicializa COM callbacks
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onTapBackground,
    );

    // 4️⃣ Canal Android
    const channel = fln.AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: fln.Importance.max,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5️⃣ Permissão Android 13+
    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // ===============================
  // 🔔 DETALHES
  // ===============================
  fln.NotificationDetails _details() {
    const androidDetails = fln.AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = fln.DarwinNotificationDetails();

    return const fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // ===============================
  // 🔔 EXIBIR IMEDIATO
  // ===============================
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      id,
      title,
      body,
      _details(),
      payload: payload,
    );
  }

  // ===============================
  // 🔔 AGENDAR
  // ===============================
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (when.isBefore(DateTime.now())) return;

    await _local.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _details(),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  // ===============================
  // 🔔 CANCELAR
  // ===============================
  Future<void> cancel(int id) async {
    await _local.cancel(id);
  }

  Future<void> cancelAll() async {
    await _local.cancelAll();
  }
}
