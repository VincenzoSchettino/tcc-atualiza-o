import 'package:cloud_firestore/cloud_firestore.dart';

class VaccineStatusModel {
  final String vaccineId;
  final bool tomada;

  VaccineStatusModel({
    required this.vaccineId,
    required this.tomada,
  });

  factory VaccineStatusModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VaccineStatusModel(
      vaccineId: (data['vaccineId'] ?? doc.id) as String,
      tomada: (data['tomada'] ?? false) as bool,
    );
  }
}
