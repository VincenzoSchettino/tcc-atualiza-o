import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  // =====================
  // SINGLETON (para .instance)
  // =====================
  FcmTokenService._();
  static final FcmTokenService instance = FcmTokenService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<String>? _tokenRefreshSub;

  // Controle para não duplicar listener
  bool _listeningTokenRefresh = false;

  /// Recomendado: chamar quando você já tem o uid (via authStateChanges).
  /// Este método NÃO depende de currentUser (mas valida por segurança).
  Future<void> initAndSyncToken({required String uid}) async {
    try {
      // 1) Solicita permissão (iOS e Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Se negado, não prossegue (especialmente iOS)
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      // 2) iOS: permitir banner/som no foreground (seguro repetir)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3) Token atual
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await _save(uid: uid, token: token, isRefresh: false);
      }

      // 4) Listener de refresh (não duplica)
      if (!_listeningTokenRefresh) {
        _listeningTokenRefresh = true;

        await _tokenRefreshSub?.cancel();
        _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
          if (newToken.isEmpty) return;

          // Garante que ainda existe sessão válida
          final current = _auth.currentUser;
          if (current == null) return;

          // Opcional: evita salvar token em usuário diferente
          if (current.uid != uid) return;

          try {
            await _save(uid: uid, token: newToken, isRefresh: true);
          } catch (_) {
            // evita crash silencioso em refresh
          }
        });
      }
    } catch (_) {
      // evita crash em casos de permissão/SDK/device
      return;
    }
  }

  /// Compatibilidade: mantém seu método antigo.
  /// Pode continuar chamando em telas, mas o recomendado é initAndSyncToken(uid).
  Future<void> initAndSaveToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await initAndSyncToken(uid: user.uid);
  }

  /// Para usar no authStateChanges quando user == null, ou ao encerrar app.
  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _listeningTokenRefresh = false;
  }

  Future<void> _save({
    required String uid,
    required String token,
    required bool isRefresh,
  }) async {
    final ref = _db
        .collection('usuarios')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token);

    await ref.set({
      'token': token,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'enabled': true,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'tzOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
      'source': 'imunizakids',
      if (!isRefresh) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Opcional: quando o usuário fizer logout, desabilita o token atual
  Future<void> disableCurrentToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      await _db
          .collection('usuarios')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'enabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      return;
    }
  }
}
