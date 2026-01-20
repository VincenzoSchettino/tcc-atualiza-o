import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tcc_3/models/filho_model.dart';
import 'package:tcc_3/services/filho_service.dart';
// IMPORTANTE: Importe o seu serviço de notificação aqui
import 'package:tcc_3/services/notification_service.dart'; 

class DatasImportantesScreen extends StatefulWidget {
  static const String routeName = '/datas_importantes';

  const DatasImportantesScreen({super.key});

  @override
  State<DatasImportantesScreen> createState() => _DatasImportantesScreenState();
}

class _DatasImportantesScreenState extends State<DatasImportantesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FilhoService _filhoService = FilhoService();

  bool _isLoading = true;
  List<Filho> _filhos = [];
  Map<int, String> _mesesParaDescricao = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Utiliza o método unificado buscarFilhos do novo FilhoService
      final filhos = await _filhoService.buscarFilhos(user.uid);
      
      if (mounted) {
        setState(() {
          _filhos = filhos;
        });
      }
      
      await _carregarDescricoesDosMeses();

      // 2. Após carregar dados e meses, agenda as notificações automaticamente
      await _agendarNotificacoesGerais();

    } catch (e) {
      _mostrarErro('Erro ao carregar dados: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Carrega todos os períodos únicos da coleção global vaccines
  Future<void> _carregarDescricoesDosMeses() async {
    final snapshot = await FirebaseFirestore.instance.collection('vaccines').get();
    final Map<int, String> mapa = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('meses')) {
        final int meses = data['meses'];
        mapa.putIfAbsent(meses, () => _formatarDescricaoPeriodo(meses));
      }
    }

    final sorted = mapa.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    if (mounted) {
      setState(() {
        _mesesParaDescricao = Map.fromEntries(sorted);
      });
    }
  }

  // --- LÓGICA DE NOTIFICAÇÃO ---
  Future<void> _agendarNotificacoesGerais() async {
    if (_filhos.isEmpty || _mesesParaDescricao.isEmpty) return;

    int totalAgendamentos = 0;

    for (var filho in _filhos) {
      // Gera um ID base único para o filho (hash do ID string)
      // Usamos .abs() para garantir positivo
      int idBaseFilho = filho.id.hashCode.abs(); 

      for (var entry in _mesesParaDescricao.entries) {
        final int meses = entry.key;
        final String periodoNome = entry.value;

        // Calcula a data da vacina (Nascimento + Meses)
        final DateTime dataVacina = DateTime(
          filho.dataNascimento.year,
          filho.dataNascimento.month + meses,
          filho.dataNascimento.day,
          8, 0, 0 // Define para as 08:00 da manhã
        );

        // Se a data já passou, não agenda
        if (dataVacina.isBefore(DateTime.now())) continue;

        // Cria um ID único para este agendamento específico:
        // ID do Filho + (Meses * 1000) para separar os períodos
        int idAgendamento = idBaseFilho + (meses * 1000);

        // Agenda os 3 avisos (7 dias, 1 dia, Hoje)
        await _agendarTrioDeNotificacoes(
          idBase: idAgendamento,
          titulo: periodoNome,
          dataVacina: dataVacina,
          nomeFilho: filho.nome,
        );
        totalAgendamentos++;
      }
    }

    print("Agendamentos atualizados para $totalAgendamentos períodos de vacinação.");
  }

  Future<void> _agendarTrioDeNotificacoes({
    required int idBase,
    required String titulo,
    required DateTime dataVacina,
    required String nomeFilho,
  }) async {
    final dataFormatada = DateFormat('dd/MM').format(dataVacina);

    // 1. Sete dias antes
    await AppNotification.instance.schedule(
      id: idBase + 1,
      title: 'Falta 1 semana! 📅',
      body: '$nomeFilho tem vacinas de "$titulo" dia $dataFormatada.',
      when: dataVacina.subtract(const Duration(days: 7)),
    );

    // 2. Um dia antes
    await AppNotification.instance.schedule(
      id: idBase + 2,
      title: 'É amanhã! 💉',
      body: 'Prepare a carteirinha! Vacinas de "$titulo" para $nomeFilho amanhã.',
      when: dataVacina.subtract(const Duration(days: 1)),
    );

    // 3. No dia
    await AppNotification.instance.schedule(
      id: idBase + 3,
      title: 'Hoje é dia de vacina! 🏥',
      body: 'Leve $nomeFilho para tomar as vacinas de "$titulo" hoje!',
      when: dataVacina,
    );
  }
  // -----------------------------

  String _formatarDescricaoPeriodo(int meses) {
    if (meses == 0) return 'Ao nascer';
    if (meses < 12) return '$meses meses';
    if (meses == 12) return '1 ano';
    if (meses == 15) return '15 meses';
    if (meses == 24) return '2 anos';
    if (meses == 48) return '4 anos';
    if (meses == 60) return '5 anos';
    if (meses == 84) return '7 anos';
    if (meses == 108) return '9 anos';
    if (meses == 120) return '10 anos';
    if (meses == 132) return '11 anos';
    return '${(meses / 12).floor()} anos';
  }

  Future<List<Map<String, dynamic>>> _buscarVacinasParaPeriodo(int meses) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vaccines')
        .where('meses', isEqualTo: meses)
        .orderBy('nome')
        .get();
    return snapshot.docs.map((e) => e.data()).toList();
  }

  void _mostrarDialogoVacinas(String titulo, List<Map<String, dynamic>> vacinas, DateTime dataPrevista) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(dataPrevista);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF3EAF4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Vacinas – $titulo',
          style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: vacinas.map((v) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '• ${v['nome']} ', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  Text('Data: $dataFormatada', style: TextStyle(color: Colors.pink[300], fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar', style: TextStyle(color: Colors.pink))),
        ],
      ),
    );
  }

  List<Widget> _construirListaPeriodos(Filho filho) {
    final now = DateTime.now();
    final List<Widget> widgets = [];

    for (var entry in _mesesParaDescricao.entries) {
      final int meses = entry.key;
      final String descricao = entry.value;

      final DateTime dataPrevista = DateTime(
        filho.dataNascimento.year,
        filho.dataNascimento.month + meses,
        filho.dataNascimento.day,
      );

      // Ícone muda de cor se a data já passou
      final bool jaPassou = dataPrevista.isBefore(now);

      widgets.add(
        ListTile(
          leading: Icon(
            Icons.calendar_today, 
            color: jaPassou ? Colors.grey : Colors.blue
          ),
          title: Text('$descricao – Data prevista: ${DateFormat('dd/MM/yyyy').format(dataPrevista)}'),
          subtitle: jaPassou ? const Text("Período concluído", style: TextStyle(fontSize: 12, color: Colors.grey)) : null,
          onTap: () async {
            final vacinas = await _buscarVacinasParaPeriodo(meses);
            if (vacinas.isEmpty) {
              _mostrarErro('Nenhuma vacina cadastrada para este período no banco de dados.');
              return;
            }
            _mostrarDialogoVacinas(descricao, vacinas, dataPrevista);
          },
        ),
      );
    }
    return widgets;
  }

  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.pink),
        title: const Text('Datas Importantes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
        actions: [
          // Botão para forçar re-agendamento manual (Mantido do seu código)
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Atualizar Notificações',
            onPressed: () async {
              setState(() => _isLoading = true);
              await _agendarNotificacoesGerais();
              setState(() => _isLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lembretes atualizados com sucesso!"), backgroundColor: Colors.green)
                );
              }
            },
          )
        ],
      ),
      
      // --- AQUI ESTÁ O BOTÃO DE TESTE QUE VOCÊ PEDIU ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.timer),
        label: const Text("Testar em 10s"),
        onPressed: () async {
          // 1. Agenda uma notificação fake para 10 segundos no futuro
          await AppNotification.instance.schedule(
            id: 99999, // ID único para o teste
            title: 'Teste de Vacina 💉',
            body: 'O sistema de notificações está funcionando perfeitamente!',
            when: DateTime.now().add(const Duration(seconds: 10)),
          );

          // 2. Avisa na tela
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Aguarde 10s (bloqueie a tela para testar)..."),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 5),
              ),
            );
          }
        },
      ),
      // ------------------------------------------------

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _filhos.isEmpty
              ? const Center(child: Text('Nenhum filho cadastrado', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filhos.length,
                  itemBuilder: (_, index) {
                    final filho = _filhos[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xFFFBF8FC), // Fundo levemente rosado/lilás
                      child: ExpansionTile(
                        initiallyExpanded: index == 0, // O primeiro já vem aberto
                        leading: const CircleAvatar(
                          backgroundColor: Colors.pink,
                          child: Icon(Icons.child_care, color: Colors.white),
                        ),
                        title: Text(filho.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        subtitle: Text('Nascimento: ${DateFormat('dd/MM/yyyy').format(filho.dataNascimento)}', style: TextStyle(color: Colors.grey[600])),
                        children: _construirListaPeriodos(filho),
                      ),
                    );
                  },
                ),
    );
  }}