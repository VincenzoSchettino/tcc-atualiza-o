import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importe seu modelo de Filho

class CardProgressoVacina extends StatelessWidget {
  final String filhoId;

  const CardProgressoVacina({super.key, required this.filhoId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox();

    // Escuta em tempo real a coleção de vacinas deste filho
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('filhos')
          .doc(filhoId)
          .collection('vacinas')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator(color: Colors.pink);
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;
        
        // Conta quantas têm o campo 'tomada' como true
        final tomadas = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['tomada'] == true;
        }).length;

        // Evita divisão por zero
        final double porcentagem = total == 0 ? 0 : (tomadas / total);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.vaccines, color: Colors.pink),
                  const SizedBox(width: 8),
                  Text(
                    "Progresso: $tomadas de $total vacinas tomadas",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: porcentagem, // Valor entre 0.0 e 1.0
                  backgroundColor: Colors.pink[100],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green), // Fica verde conforme enche
                  minHeight: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}