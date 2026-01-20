import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vacina_model.dart';

class VacinasController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Vacina>> fetchVacinas() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('vacinas').get();
      return querySnapshot.docs.map((doc) {
        return Vacina.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar vacinas: $e');
    }
  }
}
