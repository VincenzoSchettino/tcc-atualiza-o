import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vacina_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Adiciona um usuário ao Firestore
  Future<void> addUserToFirestore(String userId, Map<String, dynamic> userData) async {
    try {
      await _db.collection('usuarios').doc(userId).set(userData);
    } catch (e) {
      print("Erro ao adicionar usuário: $e");
    }
  }

  // Busca dados do usuário
  Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      return await _db.collection('usuarios').doc(userId).get();
    } catch (e) {
      print("Erro ao buscar dados do usuário: $e");
      rethrow;
    }
  }

  // Adiciona vacinas ao banco (Importação do Excel) na coleção "vaccines"
  Future<void> addVaccineToFirestore(Vacina vacina) async {
    try {
      await _db.collection('vaccines').doc(vacina.id).set(vacina.toMap());
    } catch (e) {
      print("Erro ao adicionar vacina: $e");
    }
  }

  // Vincula vacinas a um filho específico na subcoleção "vaccines"
  Future<void> assignVaccineToChild(String userId, String filhoId, Vacina vacina) async {
    try {
      await _db
          .collection('usuarios')
          .doc(userId)
          .collection('filhos')
          .doc(filhoId)
          .collection('vaccines') // Subcoleção correta
          .doc(vacina.id)
          .set(vacina.toMap());
    } catch (e) {
      print("Erro ao vincular vacina ao filho: $e");
    }
  }

  // Atualiza o status da vacina (marcar como tomada ou não)
  Future<void> updateVaccineStatus(String userId, String filhoId, String vacinaId, bool tomada) async {
    try {
      await _db
          .collection('usuarios')
          .doc(userId)
          .collection('filhos')
          .doc(filhoId)
          .collection('vaccines') // Mantendo coerência com a estrutura
          .doc(vacinaId)
          .update({'tomada': tomada});
    } catch (e) {
      print("Erro ao atualizar status da vacina: $e");
    }
  }

  // Obtém todas as vacinas de um filho
  Future<List<Vacina>> getChildVaccines(String userId, String filhoId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('usuarios')
          .doc(userId)
          .collection('filhos')
          .doc(filhoId)
          .collection('vaccines') // Certificando-se de usar "vaccines"
          .get();

      return snapshot.docs.map((doc) => Vacina.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print("Erro ao buscar vacinas do filho: $e");
      return [];
    }
  }
}
