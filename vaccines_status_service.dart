import 'package:cloud_firestore/cloud_firestore.dart';

class VaccineStatusService {
  final FirebaseFirestore _db;

  VaccineStatusService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _statusRef({
    required String uid,
    required String filhoId,
    required String vaccineId,
  }) {
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('filhos')
        .doc(filhoId)
        .collection('vacinas')
        .doc(vaccineId);
  }

  Future<void> setTomada({
    required String uid,
    required String filhoId,
    required String vaccineId,
    required bool tomada,
  }) async {
    final ref = _statusRef(uid: uid, filhoId: filhoId, vaccineId: vaccineId);

    await ref.set({
      'vaccineId': vaccineId,
      'tomada': tomada,
      'atualizadoEm': FieldValue.serverTimestamp(),
      if (tomada) 'tomadaEm': FieldValue.serverTimestamp(),
      if (!tomada) 'tomadaEm': null,
    }, SetOptions(merge: true));
  }
}
