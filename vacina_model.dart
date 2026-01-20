class Vacina {
  final String? id;
  final String nome;           // Coluna C
  final int meses;             // Coluna B
  final List<String> doencasEvitadas; // Coluna D
  final String descricao;      // Coluna E
  final bool tomada;

  Vacina({
    this.id,
    required this.nome,
    required this.meses,
    required this.doencasEvitadas,
    required this.descricao,
    this.tomada = false,
  });

  // Fábrica para converter do Firestore para o Objeto
  factory Vacina.fromMap(Map<String, dynamic> map) {
    return Vacina(
      id: map['id'],
      nome: map['nome'] ?? '',
      meses: map['meses'] ?? 0,
      descricao: map['descricao'] ?? '',
      doencasEvitadas: List<String>.from(map['doencasEvitadas'] ?? []),
      tomada: map['tomada'] ?? false,
    );
  }

  // Converter do Objeto para o Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'meses': meses,
      'doencasEvitadas': doencasEvitadas,
      'descricao': descricao,
      'tomada': tomada,
    };
  }
}