import 'package:cloud_firestore/cloud_firestore.dart';

class Filho {
  final String id;
  final String nome;
  final DateTime dataNascimento;
  final String genero;
  final String usuarioId;
  final String? fotoUrl;

  Filho({
    required this.id,
    required this.nome,
    required this.dataNascimento,
    required this.genero,
    required this.usuarioId,
    this.fotoUrl,
  });

  /// 🔒 SEMPRE usar Timestamp ao salvar
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'dataNascimento': Timestamp.fromDate(dataNascimento),
      'genero': genero,
      'usuarioId': usuarioId,
      'fotoUrl': fotoUrl,
    };
  }

  /// 🔥 SEMPRE usar este método ao LER do Firestore
  factory Filho.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    final dataNasc = map['dataNascimento'];
    DateTime dataNascimento;
    
    if (dataNasc is Timestamp) {
      dataNascimento = dataNasc.toDate();
    } else if (dataNasc is String) {
      dataNascimento = DateTime.parse(dataNasc);
    } else {
      dataNascimento = DateTime.now(); // fallback
    }
    
    return Filho(
      id: docId,
      nome: map['nome'] ?? '',
      dataNascimento: dataNascimento,
      genero: map['genero'] ?? '',
      usuarioId: map['usuarioId'] ?? '',
      fotoUrl: map['fotoUrl'],
    );
  }

  Filho copyWith({
    String? id,
    String? nome,
    DateTime? dataNascimento,
    String? genero,
    String? usuarioId,
    String? fotoUrl,
  }) {
    return Filho(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      genero: genero ?? this.genero,
      usuarioId: usuarioId ?? this.usuarioId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}
