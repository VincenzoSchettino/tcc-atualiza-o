import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tcc_3/models/vacina_model.dart';

class VacinaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<void> marcarVacinaComoTomada(String vacinaId, String usuarioId) async {
    await _db.collection('vacinas').doc(vacinaId).update({
      'tomada': true,
      'usuarioId': usuarioId,
    });
  }

  Future<List<Vacina>> getVacinasDoUsuario(String usuarioId) async {
    final snapshot = await _db
        .collection('vacinas')
        .where('usuarioId', isEqualTo: usuarioId)
        .get();
    
    return snapshot.docs.map((doc) => Vacina.fromMap(doc.data())).toList();
  }
  Future<void> criarColecaoVacinas() async {
    final Map<String, List<String>> vacinasPorIdade = {
      'Ao nascer': ['Vacina BCG (Dose única)', 'Vacina Hepatite B (Dose única)'],
      '2 meses': [
        'Vacina Pentavalente (1ª dose)',
        'Vacina Pólio inativada (1ª dose)',
        'Vacina Pneumocócica 10-valente (1ª dose)',
        'Vacina Rotavírus (1ª dose)'
      ],
      '3 meses': ['Vacina Meningocócica C (1ª dose)'],
      '4 meses': [
        'Vacina Pentavalente (2ª dose)',
        'Vacina Pólio inativada (2ª dose)',
        'Vacina Pneumocócica 10-valente (2ª dose)',
        'Vacina Rotavírus (2ª dose)'
      ],
      '5 meses': ['Vacina Meningocócica C (2ª dose)'],
      '6 meses': [
        'Vacina Pentavalente (3ª dose)',
        'Vacina Pólio inativada (3ª dose)',
        'Vacina Covid-19 (1ª dose)'
      ],
      '7 meses': ['Vacina Covid-19 (2ª dose)'],
      '9 meses': ['Vacina Febre Amarela (Dose única)'],
      '12 meses': [
        'Vacina Pneumocócica 10-valente (Reforço)',
        'Vacina Meningocócica C (Reforço)',
        'Vacina Tríplice viral (1ª dose)'
      ],
      '15 meses': [
        'Vacina DTP (1º reforço)',
        'Vacina Pólio inativada (Reforço)',
        'Vacina Hepatite A (Dose única)',
        'Vacina Tetra viral (Dose única)'
      ],
      '4 anos': [
        'Vacina DTP (2º reforço)',
        'Vacina Febre Amarela (Reforço)',
        'Vacina Varicela (Dose única)'
      ],
      '5 anos': [
        'Vacina Febre Amarela (Dose única, se necessário)',
        'Vacina Pneumocócica 23-valente (1ª dose)'
      ],
      '7 anos': ['Vacina dT (Reforço)'],
      '9 e 10 anos': ['Vacina HPV (Dose única)'],
    };

    for (var entry in vacinasPorIdade.entries) {
      String idade = entry.key;
      List<String> vacinas = entry.value;

      DocumentReference docRef = _db.collection('listavacinas').doc(idade);
      DocumentSnapshot docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({'vacinas': vacinas});
      }
    }
  }

}