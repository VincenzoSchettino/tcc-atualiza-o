import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcc_3/models/vacina_model.dart';
import 'package:tcc_3/models/filho_model.dart'; // Certifique-se que o caminho está correto

class VacinasScreen extends StatefulWidget {
  final Filho filho;

  const VacinasScreen({super.key, required this.filho});

  @override
  State<VacinasScreen> createState() => _VacinasScreenState();
}

class _VacinasScreenState extends State<VacinasScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Vacina> _listaVacinas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Busca Catálogo Global (vaccines)
      final catalogoSnapshot = await _firestore.collection('vaccines').get();
      
      // 2. Busca Status do Filho (status_vacinas)
      final statusSnapshot = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('filhos')
          .doc(widget.filho.id)
          .collection('status_vacinas')
          .where('tomada', isEqualTo: true)
          .get();

      // Cria conjunto de IDs tomados para verificação rápida
      final Set<String> idsTomados = statusSnapshot.docs.map((d) => d.id).toList().toSet();

      // 3. Mescla os dados
      final List<Vacina> listaTemp = [];
      for (var doc in catalogoSnapshot.docs) {
        final data = doc.data();
        
        // Tratamento de tipos seguro
        int meses = 0;
        if (data['meses'] is int) {
          meses = data['meses'];
        } else if (data['meses'] is String) meses = int.tryParse(data['meses']) ?? 0;

        List<String> doencas = [];
        if (data['doencasEvitadas'] is List) doencas = List<String>.from(data['doencasEvitadas']);

        listaTemp.add(Vacina(
          id: doc.id,
          nome: data['nome'] ?? '',
          meses: meses,
          descricao: data['descricao'] ?? '',
          doencasEvitadas: doencas,
          tomada: idsTomados.contains(doc.id), // Define se está verde ou branca
        ));
      }

      // Ordena por idade
      listaTemp.sort((a, b) => a.meses.compareTo(b.meses));

      setState(() {
        _listaVacinas = listaTemp;
        isLoading = false;
      });

    } catch (e) {
      debugPrint("Erro ao carregar vacinas: $e");
      setState(() => isLoading = false);
    }
  }

  // --- POPUP COM DESIGN ROSA E VERDE ---
  void _showDetalhes(BuildContext context, Vacina vacina) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Vacina ${vacina.nome}',
            style: const TextStyle(
              color: Colors.pink, 
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Doenças evitadas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Caixa Verde Arredondada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), 
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  vacina.doencasEvitadas.join(", "),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              // Descrição abaixo
              Text(vacina.descricao),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar', style: TextStyle(color: Colors.pink)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Carteira de ${widget.filho.nome}', style: const TextStyle(color: Colors.pink)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.pink),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemCount: _listaVacinas.length,
              itemBuilder: (context, index) {
                final vacina = _listaVacinas[index];
                final isTomada = vacina.tomada;

                return GestureDetector(
                  onTap: () => _showDetalhes(context, vacina),
                  child: Card(
                    elevation: 3,
                    // Cor de Fundo: Verde se tomada, Branca se pendente
                    color: isTomada ? Colors.green.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isTomada ? Colors.green : Colors.pink.shade100,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vacina.nome,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isTomada ? Colors.green.shade800 : Colors.pink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${vacina.meses} meses',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (isTomada)
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}