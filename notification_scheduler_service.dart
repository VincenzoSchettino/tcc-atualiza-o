import 'dart:io';
import 'package:flutter/material.dart'; // Essencial para a cor azul
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationSchedulerService {
  NotificationSchedulerService._();
  static final NotificationSchedulerService instance = NotificationSchedulerService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const String channelId = 'imunizakids_channel';
  static const String channelName = 'Vacinas';
  static const String channelDesc = 'Lembretes de vacinação';

  bool _initialized = false;

  Future<void> init() => initialize();

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _local.initialize(initSettings);
    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    _initialized = true;
  }

  // ✅ Adicionado parâmetros meses, doencasEvitadas e descricao para resolver o erro
  Future<void> agendarNotificacoesDaVacina({
    required String uid,
    required String filhoId,
    required String vacinaId,
    required String nomeVacina,
    required DateTime dataPrevista,
    int? meses, // Parâmetro agora definido
    List<String>? doencasEvitadas, // Parâmetro agora definido
    String? descricao, // Parâmetro agora definido
    String? filhoNome,
    int hour = 10,
    int minute = 0,
  }) async {
    await initialize();
    final String payload = 'filho_$filhoId';

    // 1. Faltam 7 dias
    final data7d = dataPrevista.subtract(const Duration(days: 7));
    await _agendar(
      _id(uid, filhoId, vacinaId, 7),
      _atTime(data7d, hour, minute),
      'Lembrete de Vacina',
      "FALTAM 7 DIAS PARA A VACINA '$nomeVacina'",
      payload: payload,
    );

    // 2. Falta 1 dia
    final data1d = dataPrevista.subtract(const Duration(days: 1));
    await _agendar(
      _id(uid, filhoId, vacinaId, 1),
      _atTime(data1d, hour, minute),
      'Lembrete de Vacina',
      "FALTAM 1 DIA PARA A VACINA '$nomeVacina'",
      payload: payload,
    );

    // 3. Dia de Vacinar
    await _agendar(
      _id(uid, filhoId, vacinaId, 0),
      _atTime(dataPrevista, hour, minute),
      'Dia de Vacina!',
      "DIA DE VACINAR SEU FILHO COM A VACINA '$nomeVacina'",
      payload: payload,
    );
  }

  // ✅ Método solicitado para os testes imediatos
  // ✅ Método configurado para "pular" na tela como Push Notification
  Future<void> enviarNotificacaoImediata({
    required int id,
    required String titulo,
    required String corpo,
    String? payload,
  }) async {
    await initialize();

    // Configuração específica para Android (IMPORTÂNCIA MÁXIMA)
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'imunizakids_push_channel', // ID do canal
      'Lembretes Urgentes',        // Nome do canal
      channelDescription: 'Canal para notificações que saltam na tela',
      importance: Importance.max,   // Faz a notificação aparecer no topo (Heads-up)
      priority: Priority.high,      // Define prioridade alta
      ticker: 'ticker',
      color: Colors.blue,           // Cor azul que você solicitou
      playSound: true,              // Ativa o som
      // Se tiver um ícone específico, coloque aqui, senão usa o padrão
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,  // Exibe o alerta no iOS
        presentBadge: true,  // Exibe a bolinha no ícone
        presentSound: true,  // Toca o som no iOS
      ),
    );

    await _local.show(
      id,
      titulo,
      corpo,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> _agendar(int id, DateTime data, String titulo, String corpo, {String? payload}) async {
    if (data.isBefore(DateTime.now())) return;
    await _local.zonedSchedule(
      id,
      titulo,
      corpo,
      tz.TZDateTime.from(data, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.blue,
        ),
        iOS: const DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  DateTime _atTime(DateTime d, int hour, int minute) => DateTime(d.year, d.month, d.day, hour, minute);
  int _id(String uid, String filhoId, String vacinaId, int offset) => (uid + filhoId + vacinaId + offset.toString()).hashCode;

  Future<void> cancelarTodasNotificacoes() async {
    await initialize();
    await _local.cancelAll();
  }

  Future<void> cancelarNotificacoesDaVacina({required String uid, required String filhoId, required String vacinaId}) async {
    await _local.cancel(_id(uid, filhoId, vacinaId, 7));
    await _local.cancel(_id(uid, filhoId, vacinaId, 1));
    await _local.cancel(_id(uid, filhoId, vacinaId, 0));
  }
}