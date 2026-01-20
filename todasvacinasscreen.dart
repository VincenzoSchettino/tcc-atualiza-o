import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tcc_3/models/vacina_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodasVacinasScreen extends StatefulWidget {
  static const routeName = '/todas-vacinas';

  const TodasVacinasScreen({super.key});

  @override
  _TodasVacinasScreenState createState() => _TodasVacinasScreenState();
}

class _TodasVacinasScreenState extends State<TodasVacinasScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';
  String selectedAge = 'Todas as idades';
  String? selectedFilhoId;
  List<Vacina> todasVacinas = [];
  List<Map<String, dynamic>> filhos = [];
  bool isLoading = true;
  List<String> _vacinasMarcadas = [];

  // --- FUNÇÃO QUE CRIA O POPUP IGUAL À IMAGEM ---
  void _showVacinaDetalhes(BuildContext context, Vacina vacina) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Bordas arredondadas do card
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Vacina ${vacina.nome}', // COLUNA C (Título)
            style: const TextStyle(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ocupa só o espaço necessário
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rótulo pequeno
              const Text(
                'Doenças evitadas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              // --- CAIXA VERDE (COLUNA D) ---
              Container(
                width: double.infinity, // Ocupa a largura toda
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), // Verde igual da imagem
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  vacina.doencasEvitadas.join(", "), // Lista de doenças
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- TEXTO EMBAIXO (COLUNA E) ---
              Text(
                vacina.descricao, // Descrição/Dose
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Fechar',
                style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- O RESTANTE DO CÓDIGO (LÓGICA DE CARREGAMENTO) ---

  bool _isVacinaMarcada(String vaccineId) {
    return _vacinasMarcadas.contains(vaccineId);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final filhosSnapshot = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('filhos')
          .get();

      final vacinasSnapshot = await _firestore.collection('vaccines').get();

      if (selectedFilhoId == null && filhosSnapshot.docs.isNotEmpty) {
        selectedFilhoId = filhosSnapshot.docs.first.id;
      }

      setState(() {
        filhos = filhosSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Conversão segura dos dados
        todasVacinas = vacinasSnapshot.docs.map((doc) {
          final data = doc.data();
          
          // Tratamento para meses (segurança básica)
          int mesesTratado = 0;
          if (data['meses'] is int) {
            mesesTratado = data['meses'];
          } else if (data['meses'] is String) mesesTratado = int.tryParse(data['meses']) ?? 0;

          // Tratamento para doenças
          List<String> doencasTratadas = [];
          if (data['doencasEvitadas'] is List) {
            doencasTratadas = List<String>.from(data['doencasEvitadas']);
          }

          return Vacina(
            id: doc.id,
            nome: data['nome'] ?? '',
            meses: mesesTratado,
            descricao: data['descricao'] ?? '',
            doencasEvitadas: doencasTratadas,
          );
        }).toList();
        
        isLoading = false;
      });

      if (selectedFilhoId != null) {
        await _loadVacinasStatus();
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      setState(() => isLoading = false);
    }
  }

  List<Vacina> _getFilteredVacinas() {
    if (isLoading) return [];

    List<Vacina> filtered = todasVacinas;

    if (selectedAge != 'Todas as idades') {
      final meses = _convertAgeToMonths(selectedAge);
      filtered = filtered.where((v) => v.meses == meses).toList();
    } else {
      filtered.sort((a, b) => a.meses.compareTo(b.meses));
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((v) => v.nome.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  int _convertAgeToMonths(String age) {
    switch (age) {
      case 'Ao nascer': return 0;
      case '2 meses': return 2;
      case '3 meses': return 3;
      case '4 meses': return 4;
      case '5 meses': return 5;
      case '6 meses': return 6;
      case '7 meses': return 7;
      case '9 meses': return 9;
      case '12 meses': return 12;
      case '15 meses': return 15;
      case '4 anos': return 48;
      case '5 anos': return 60;
      case '7 anos': return 84;
      case '9 e 10 anos': return 108;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredVacinas = _getFilteredVacinas();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Todas as Vacinas',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.pink),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (filhos.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedFilhoId,
                    decoration: InputDecoration(
                      labelText: 'Selecione o filho',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    items: filhos.map<DropdownMenuItem<String>>((filho) {
                      return DropdownMenuItem<String>(
                        value: filho['id'],
                        child: Text(filho['nome'] ?? 'Filho sem nome'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedFilhoId = newValue;
                      });
                      _loadVacinasStatus();
                    },
                  ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    labelText: 'Procurar vacina',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedAge,
              isExpanded: true,
              onChanged: (String? newValue) => setState(() => selectedAge = newValue!),
              items: <String>[
                'Todas as idades',
                'Ao nascer',
                '2 meses',
                '3 meses',
                '4 meses',
                '5 meses',
                '6 meses',
                '7 meses',
                '9 meses',
                '12 meses',
                '15 meses',
                '4 anos',
                '5 anos',
                '7 anos',
                '9 e 10 anos',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
            ),
          ),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 1.3,
                ),
                itemCount: filteredVacinas.length,
                itemBuilder: (context, index) {
                  final vacina = filteredVacinas[index];
                  final isMarcada = _isVacinaMarcada(vacina.id ?? '');

                  return GestureDetector(
                    onTap: () => _showVacinaDetalhes(context, vacina), // ABRE O POPUP
                    onLongPress: () => _toggleVacinaStatus(vacina), // MARCA COMO TOMADA
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(
                          color: isMarcada ? Colors.green : Colors.pink.shade100,
                          width: 2,
                        ),
                      ),
                      color: isMarcada ? Colors.green.shade50 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              vacina.nome,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: isMarcada ? Colors.green.shade800 : Colors.pink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${vacina.meses} meses',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (isMarcada)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleVacinaStatus(Vacina vacina) async {
    if (selectedFilhoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um filho primeiro!')));
      return;
    }

    try {
      final vacinaId = vacina.id ?? '';
      final isMarcada = _isVacinaMarcada(vacinaId);
      final novoStatus = !isMarcada;
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('filhos')
          .doc(selectedFilhoId!)
          .collection('status_vacinas')
          .doc(vacinaId)
          .set({'tomada': novoStatus}, SetOptions(merge: true));

      setState(() {
        if (novoStatus) {
          _vacinasMarcadas.add(vacinaId);
        } else {
          _vacinasMarcadas.remove(vacinaId);
        }
      });
    } catch (e) {
      debugPrint('Erro ao atualizar status: $e');
    }
  }

  Future<void> _loadVacinasStatus() async {
    if (selectedFilhoId == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final statusSnapshot = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('filhos')
          .doc(selectedFilhoId!)
          .collection('status_vacinas')
          .get();
      
      setState(() {
        _vacinasMarcadas = statusSnapshot.docs
            .where((doc) => doc['tomada'] == true)
            .map((doc) => doc.id)
            .toList();
      });
    } catch (e) {
      debugPrint('Erro ao carregar status: $e');
    }
  }
}