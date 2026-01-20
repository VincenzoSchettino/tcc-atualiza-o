import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tcc_3/services/notification_service.dart';
// Import do seu AppNotification

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // 🔔 1. MÉTODO MESTRE: AGENDA TUDO COM BASE NA LISTA DE VACINAS
  // ===========================================================================
  Future<void> agendarNotificacoesParaTodosFilhos(String userId) async {
    try {
      print("🔄 Atualizando agendamentos para todas as vacinas...");

      // ❌ NUNCA inicialize notificação aqui
      // await AppNotification.instance.initialize(); ❌ REMOVIDO

      List<Map<String, dynamic>> birthDates = await getBirthDates(userId);

      for (var child in birthDates) {
        DateTime birthDate = (child['data_nascimento'] as Timestamp).toDate();
        String filhoId = child['id'];

        List<Map<String, dynamic>> listaVacinas =
            _calculateVaccineDates(birthDate);

        for (var vacinaItem in listaVacinas) {
          String nomeVacina = vacinaItem['vacina'];
          DateTime dataVacina = vacinaItem['data'];

          // ===============================
          bool _isHoje(DateTime data) {
            final now = DateTime.now();
            return data.year == now.year &&
                data.month == now.month &&
                data.day == now.day;
          }

          int _mesesEntreDatas(DateTime inicio, DateTime fim) {
            return (fim.year - inicio.year) * 12 + (fim.month - inicio.month);
          }

          String payloadToJson(Map<String, dynamic> data) {
            return jsonEncode(data);
          }

          // 🔔 CASO 1 — HOJE → IMEDIATA
          // ===============================
          if (_isHoje(dataVacina)) {
            final payload = {
              'filhoId': filhoId,
              'meses': _mesesEntreDatas(birthDate, dataVacina),
              'vacinas': [nomeVacina],
            };

            await AppNotification.instance.showNow(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: '🍼 Hoje é dia de vacinação',
              body: 'Leve a criança para tomar $nomeVacina hoje.',
              payload: payloadToJson(payload),
            );

            continue; // não agenda D-7 / D-3
          }

          // ===============================
          // 🔔 CASO 2 — FUTURO → AGENDA
          // ===============================
          for (int dias in [7, 3]) {
            DateTime dataAviso = dataVacina.subtract(Duration(days: dias));
            DateTime dataNotificacao = DateTime(
              dataAviso.year,
              dataAviso.month,
              dataAviso.day,
              8,
              0,
            );

            if (dataNotificacao.isBefore(DateTime.now())) continue;

            int idUnico = (nomeVacina.hashCode + dias + filhoId.hashCode).abs();

            await AppNotification.instance.schedule(
              id: idUnico,
              title: '📅 Vacinação próxima',
              body: 'Faltam $dias dias para a vacina $nomeVacina.',
              when: dataNotificacao,
            );
          }
        }
      }

      print("✅ Notificações configuradas com sucesso!");
    } catch (e) {
      print("❌ Erro ao agendar notificações: $e");
    }
  }

  // ===========================================================================
  // 📅 2. FONTE DA VERDADE: LISTA DE VACINAS (CALENDÁRIO COMPLETO)
  // ===========================================================================
  List<Map<String, dynamic>> _calculateVaccineDates(DateTime birthDate) {
    // Mapa completo: Nome da Vacina -> Dias após nascimento
    Map<String, int> vaccineSchedule = {
      'BCG': 0, // Ao nascer
      'Hepatite B': 0,
      'Pentavalente (1ª dose)': 60, // 2 meses
      'VIP (1ª dose)': 60,
      'Rotavírus (1ª dose)': 60,
      'Pneumocócica 10V (1ª dose)': 60,
      'Meningocócica C (1ª dose)': 90, // 3 meses
      'Pentavalente (2ª dose)': 120, // 4 meses
      'VIP (2ª dose)': 120,
      'Pneumocócica 10V (2ª dose)': 120,
      'Rotavírus (2ª dose)': 120,
      'Meningocócica C (2ª dose)': 150, // 5 meses
      'Pentavalente (3ª dose)': 180, // 6 meses
      'VIP (3ª dose)': 180,
      'Febre Amarela': 270, // 9 meses
      'Tríplice Viral': 365, // 12 meses
      'Pneumocócica 10V (Reforço)': 365,
      'Meningocócica C (Reforço)': 365,
      'Hepatite A': 450, // 15 meses
      'Tetra Viral': 450,
      'DTP (1º Reforço)': 450,
      'VOP (1º Reforço)': 450,
      'DTP (2º Reforço)': 1460, // 4 anos
      'VOP (2º Reforço)': 1460,
      'Varicela (2ª dose)': 1460,
      'HPV (1ª dose)': 3285, // 9 anos
      'Meningocócica ACWY': 3942, // 11 anos (aprox)
    };

    List<Map<String, dynamic>> vaccineDates = [];

    // Transforma o mapa em uma lista com datas reais baseadas no nascimento
    vaccineSchedule.forEach((vaccine, daysAfterBirth) {
      DateTime vaccineDate = birthDate.add(Duration(days: daysAfterBirth));

      // Gera ID string único para referência interna se precisar
      String stringId = "${vaccine}_${vaccineDate.millisecondsSinceEpoch}";

      vaccineDates.add({
        'id': stringId,
        'vacina': vaccine,
        'data': vaccineDate,
      });
    });

    return vaccineDates;
  }
  //===================================================
  // 🛠️ 3. MÉTODOS AUXILIARES DE BANCO DE DADOS (CRUD)
  // ===========================================================================

  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _db.collection('usuarios').doc(user.uid).set(userData);
      }
    } catch (e) {
      print("Erro ao criar usuário: $e");
      rethrow;
    }
  }

  Future<DocumentSnapshot> getUserData(String userId) async {
    return await _db.collection('usuarios').doc(userId).get();
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _db.collection('usuarios').doc(userId).update(data);
  }

  Future<void> deleteUser(String userId) async {
    await _db.collection('usuarios').doc(userId).delete();
  }

  // Adicionar Filho + Salvar Data de Nascimento para notificações
  Future<DocumentReference> addChild(
      String userId, Map<String, dynamic> childData) async {
    try {
      DocumentReference docRef = await _db
          .collection('usuarios')
          .doc(userId)
          .collection('filhos')
          .add(childData);

      // Salva em 'datanasc' para acesso rápido nas notificações
      await _db.collection('datanasc').doc(docRef.id).set({
        'userId': userId,
        'data_nascimento': childData['data_nascimento'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      return docRef;
    } catch (e) {
      print("Erro ao adicionar filho: $e");
      rethrow;
    }
  }

  Future<QuerySnapshot> getChildren(String userId) async {
    return await _db
        .collection('usuarios')
        .doc(userId)
        .collection('filhos')
        .get();
  }

  Future<List<Map<String, dynamic>>> getBirthDates(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('datanasc')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // IMPORTANTE: O ID do filho vem aqui
        return data;
      }).toList();
    } catch (e) {
      print("Erro ao buscar datas: $e");
      rethrow;
    }
  }

  Future<void> updateChild(
      String userId, String childId, Map<String, dynamic> data) async {
    await _db
        .collection('usuarios')
        .doc(userId)
        .collection('filhos')
        .doc(childId)
        .update(data);
  }

  Future<void> deleteChild(String userId, String childId) async {
    await _db
        .collection('usuarios')
        .doc(userId)
        .collection('filhos')
        .doc(childId)
        .delete();
    await _db.collection('datanasc').doc(childId).delete();
  }
}
