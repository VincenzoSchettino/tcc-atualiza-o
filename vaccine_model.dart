import 'package:cloud_firestore/cloud_firestore.dart';

class VaccineModel {
  final String id;
  final String nome;
  final int meses;
  final String? descricao;

  VaccineModel({
    required this.id,
    required this.nome,
    required this.meses,
    this.descricao,
  });

  factory VaccineModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VaccineModel(
      id: doc.id,
      nome: (data['nome'] ?? '') as String,
      meses: (data['meses'] ?? 0) as int,
      descricao: data['descricao'] as String?,
    );
  }
}
