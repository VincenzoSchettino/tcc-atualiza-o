import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tcc_3/services/filho_service.dart';

class NotificacoesScreen extends StatefulWidget {
  static const String routeName = '/notificacoes';

  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FilhoService _filhoService = FilhoService();

  List<Map<String, dynamic>> _notificacoes = [];
  bool _isLoading = true;

  String _filtroTempoSelecionado = 'Hoje';
  bool _mostrarTodas = false;

  final List<String> _filtrosTempo = [
    'Hoje',
    '10 dias',
    '30 dias',
  ];

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  Future<void> _carregarNotificacoes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final filhos = await _filhoService.buscarFilhos(user.uid);
      final vacinasSnapshot = await FirebaseFirestore.instance.collection('vaccines').get();

      final List<Map<String, dynamic>> todasNotificacoes = [];

      
      
      for (final filho in filhos) {
        final vacinasFilhoSnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('filhos')
            .doc(filho.id)
            .collection('status_vacinas')
            .get();

        final vacinasTomadas = {
          for (var doc in vacinasFilhoSnapshot.docs) doc.id: doc['tomada'] ?? false,
        };

        for (final doc in vacinasSnapshot.docs) {
          final data = doc.data();
          final nome = data['nome'] ?? '';
          final meses = data['meses'];
          if (meses == null || nome.isEmpty) continue;

          final vacinaId = doc.id;
          final tomada = vacinasTomadas[vacinaId] ?? false;
          if (tomada) continue;

          final dataPrevista = filho.dataNascimento.add(Duration(days: meses * 30));
          final descricaoPeriodo = _descricaoDoPeriodo(meses);
          final formatada = DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'pt_BR').format(dataPrevista);


          Color corNotificacao;
          final hoje = DateTime.now();
          if (dataPrevista.isBefore(DateTime(hoje.year, hoje.month, hoje.day))) {
            corNotificacao = Colors.red;  // Vacinas anteriores em vermelho
          } else if (dataPrevista.year == hoje.year &&
              dataPrevista.month == hoje.month &&
              dataPrevista.day == hoje.day) {
            corNotificacao = Colors.green;  // Vacinas do dia atual em verde
          } else {
            corNotificacao = const Color.fromARGB(255, 181, 184, 0);  // Vacinas futuras não devem aparecer no "Hoje"
          }

          todasNotificacoes.add({
            'filho': filho.nome,
            'vacina': nome,
            'dataPrevista': formatada,
            'dataReal': dataPrevista,
            'descricao': descricaoPeriodo,
            'cor': corNotificacao,
            'fotoUrl': filho.fotoUrl,
          });
        }
      }

      todasNotificacoes.sort((a, b) => a['dataReal'].compareTo(b['dataReal']));

      setState(() {
        _notificacoes = todasNotificacoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar notificações: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _notificacoesFiltradas {
  final hoje = DateTime.now();

  if (_mostrarTodas) return _notificacoes;

  switch (_filtroTempoSelecionado) {
    case 'Hoje':
      return _notificacoes.where((n) {
        final data = n['dataReal'] as DateTime;
        return (data.year == hoje.year && data.month == hoje.month && data.day == hoje.day) ||
            data.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
      }).toList();
    case '10 dias':
      final limite = hoje.add(const Duration(days: 10));
      return _notificacoes.where((n) {
        final data = n['dataReal'] as DateTime;
        return data.isBefore(limite); // Inclui vermelhas, verdes e amarelas
      }).toList();
    case '30 dias':
      final limite = hoje.add(const Duration(days: 30));
      return _notificacoes.where((n) {
        final data = n['dataReal'] as DateTime;
        return data.isBefore(limite); // Inclui vermelhas, verdes e amarelas
      }).toList();
    default:
      return _notificacoes;
  }
}

  String _descricaoDoPeriodo(int meses) {
    if (meses == 0) return "Ao nascer";
    if (meses == 12) return "1 ano";
    if (meses == 18) return "15 meses";
    if (meses == 108) return "9 e 10 anos";
    if (meses > 15 && meses % 12 == 0) {
      return '${meses ~/ 12} anos';
    }
    return '$meses meses';
  }

  String _mensagemVaziaFiltro() {
    if (_mostrarTodas) return 'FILHO COM VACINAÇÃO EM DIA!';

    switch (_filtroTempoSelecionado) {
      case 'Hoje':
        return 'HOJE ESTÁ EM DIA! \n NÃO HÁ NOTIFICAÇÕES PARA A DATA DE HOJE!';
      case '10 dias':
        return 'VACINAÇÃO EM DIA! \n NÃO HÁ NOTIFICAÇÕES PARA DAQUI A 10 DIAS!';
      case '30 dias':
        return 'VACINAÇÃO EM DIA!\n NÃO HÁ NOTIFICAÇÕES PARA OS PRÓXIMOS\n 30 DIAS';
      default:
        return 'Nenhuma notificação encontrada.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notificações',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.pink),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.notifications_active, color: Colors.pink),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filtrosTempo.length,
              itemBuilder: (context, index) {
                final filtro = _filtrosTempo[index];
                final selecionado = !_mostrarTodas && _filtroTempoSelecionado == filtro;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(filtro),
                    selected: selecionado,
                    selectedColor: Colors.pink[100],
                    onSelected: (_) {
                      setState(() {
                        _filtroTempoSelecionado = filtro;
                        _mostrarTodas = false;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: const Alignment(-0.7, -1.0),
            child: ChoiceChip(
              label: const Text('Todas as Notificações'),
              selected: _mostrarTodas,
              selectedColor: Colors.pink[100],
              onSelected: (_) {
                setState(() {
                  _mostrarTodas = true;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notificacoesFiltradas.isEmpty
                    ? Center(
                        child: Text(
                          _mensagemVaziaFiltro(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notificacoesFiltradas.length,
                        itemBuilder: (context, index) {
                          final notif = _notificacoesFiltradas[index];
                          final Color cor = notif['cor'] ?? Colors.grey;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Card(
                              color: cor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  backgroundImage: notif['fotoUrl'] != null && notif['fotoUrl'].toString().isNotEmpty
                                      ? NetworkImage(notif['fotoUrl'])
                                      : null,
                                  child: notif['fotoUrl'] == null || notif['fotoUrl'].toString().isEmpty
                                      ? Text(
                                          (notif['filho'] as String).substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.pink,
                                          ),
                                        )
                                      : null,
                                ),
                                title: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.white),
                                    children: [
                                      TextSpan(
                                        text: '${notif['filho']} ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(
                                        text: 'precisa tomar a vacina ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: '${notif['vacina']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Text(
                                  'Data prevista: ${notif['dataPrevista']} (${notif['descricao']})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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
}
