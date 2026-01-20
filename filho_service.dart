import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para usar debugPrint
import 'package:tcc_3/models/filho_model.dart';
// Se você tiver uma lógica de vacinas, importe aqui:
// import 'package:tcc_3/services/vacina_service.dart'; 
// import 'package:tcc_3/services/notification_scheduler_service.dart';

class FilhoService {
  // ✅ 1. Declaração correta do Banco de Dados
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionName = 'usuarios'; // Usar 'usuarios' para compatibilidade

  // ==============================================================
  // 🔍 BUSCAR FILHOS (READ)
  // ==============================================================
  Future<List<Filho>> buscarFilhos(String userId) async {
    try {
      final snapshot = await _db
          .collection(collectionName)
          .doc(userId)
          .collection('filhos')
          .orderBy('dataNascimento', descending: true) // Ordena por idade
          .get();

      return snapshot.docs.map((doc) {
        // Converte o documento do Firebase para o Objeto Filho
        return Filho.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Erro ao buscar filhos: $e");
      return [];
    }
  }

  // ==============================================================
  // ADICIONAR FILHO (CREATE)
  // ==============================================================
  Future<void> adicionarFilho(String userId, Filho filho) async {
    try {
      // Cria uma referência de documento novo (gera ID automático se não tiver)
      final docRef = _db
          .collection(collectionName)
          .doc(userId)
          .collection('filhos')
          .doc(); // .doc() vazio gera um ID aleatório único

      // Cria um novo objeto Filho com o ID gerado
      final filhoComId = Filho(
        id: docRef.id,
        nome: filho.nome,
        dataNascimento: filho.dataNascimento,
        genero: filho.genero,
        usuarioId: userId,
        fotoUrl: filho.fotoUrl,
      );

      await docRef.set(filhoComId.toMap());
      debugPrint("Filho ${filhoComId.nome} adicionado com ID: ${filhoComId.id}");
    } catch (e) {
      debugPrint("Erro ao adicionar filho: $e");
      rethrow;
    }
  }

  // ==============================================================
  // ATUALIZAR FILHO (UPDATE) - CORRIGIDO
  // ==============================================================
  // Este método usa .update() para NÃO apagar os outros filhos
  Future<void> atualizarFilho(String userId, Filho filho) async {
    if (filho.id.isEmpty) {
      throw Exception('ERRO: Tentativa de atualizar filho sem ID.');
    }

    try {
      final docRef = _db
          .collection(collectionName)
          .doc(userId)
          .collection('filhos')
          .doc(filho.id); // Aponta EXATAMENTE para este filho

      // Verifica se existe antes de atualizar
      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Filho não encontrado no banco de dados.');
      }

      // ATUALIZAÇÃO SEGURA
      await docRef.update({
        'nome': filho.nome,
        'dataNascimento': Timestamp.fromDate(filho.dataNascimento),
        'genero': filho.genero, // Confirme se no seu model é 'genero' ou 'sexo'
        'fotoUrl': filho.fotoUrl ?? '',
        // Adicione aqui outros campos se houver
      });

      debugPrint("Filho ${filho.nome} atualizado com sucesso!");
    } catch (e) {
      debugPrint("Erro ao atualizar filho: $e");
      rethrow;
    }
  }

  // ==============================================================
  // 🗑️ EXCLUIR FILHO (DELETE)
  // ==============================================================
  Future<void> excluirFilho(String userId, String filhoId) async {
    try {
      await _db
          .collection(collectionName)
          .doc(userId)
          .collection('filhos')
          .doc(filhoId)
          .delete();
      
      debugPrint("Filho excluído com sucesso.");
    } catch (e) {
      debugPrint("Erro ao excluir filho: $e");
      rethrow;
    }
  }

  // ==============================================================
  // 💉 ATUALIZAR VACINA DO FILHO (UPDATE)
  // ==============================================================
  Future<void> atualizarVacinaFilho({
    required String usuarioId,
    required String filhoId,
    required String vacinaId,
    required bool tomada,
  }) async {
    try {
      final vRef = _db
          .collection(collectionName)
          .doc(usuarioId)
          .collection('filhos')
          .doc(filhoId)
          .collection('status_vacinas')
          .doc(vacinaId);

      await vRef.set({
        'tomada': tomada,
        'dataAplicacao': tomada ? Timestamp.fromDate(DateTime.now()) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Vacina $vacinaId atualizada: tomada=$tomada");
    } catch (e) {
      debugPrint("Erro ao atualizar vacina: $e");
      rethrow;
    }
  }

  // ==============================================================
  // 📅 AGENDAR NOTIFICAÇÕES (Método chamado pela Tela de Teste)
  // ==============================================================
  Future<void> agendarNotificacoesDoFilho({
    required String usuarioId,
    required String filhoId,
  }) async {
    try {
      // 1. Busca os dados atualizados do filho
      final docSnapshot = await _db
          .collection(collectionName)
          .doc(usuarioId)
          .collection('filhos')
          .doc(filhoId)
          .get();

      if (!docSnapshot.exists) return;

      final filho = Filho.fromFirestore(docSnapshot.data()!, docSnapshot.id);

      debugPrint("Iniciando agendamento para: ${filho.nome}");

      // AQUI ENTRA A LÓGICA DE CALCULAR VACINAS
      // Como não tenho seu arquivo 'VacinaService' aqui, vou deixar o placeholder.
      // Basicamente você deve:
      // 1. Pegar a data de nascimento
      // 2. Calcular quando são as vacinas de 2 meses, 4 meses, etc.
      // 3. Chamar o NotificationSchedulerService para cada data.

      /* EXEMPLO DE LÓGICA:
      final scheduler = NotificationSchedulerService.instance;
      
      // Exemplo: Vacina de 2 meses
      final data2Meses = filho.dataNascimento.add(const Duration(days: 60));
      if (data2Meses.isAfter(DateTime.now())) {
         await scheduler.agendarNotificacao(
            id: filho.id.hashCode + 2, 
            titulo: "Vacina de 2 Meses", 
            body: "Hora da Pentavalente!", 
            scheduledDate: data2Meses
         );
      }
      */
      
      // Para o teste funcionar sem erro, apenas imprimimos sucesso:
      debugPrint("Simulação: Agendamento recalculado com sucesso.");

    } catch (e) {
      debugPrint("Erro ao agendar notificações: $e");
      rethrow;
    }
  }
}