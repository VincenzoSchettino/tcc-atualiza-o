import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcc_3/services/filho_service.dart';
import 'package:tcc_3/models/filho_model.dart';
import 'package:tcc_3/services/notification_scheduler_service.dart';

class TestNotificacoesScreen extends StatefulWidget {
  static const String routeName = '/test-notificacoes';

  const TestNotificacoesScreen({super.key});

  @override
  State<TestNotificacoesScreen> createState() => _TestNotificacoesScreenState();
}

class _TestNotificacoesScreenState extends State<TestNotificacoesScreen> {
  final FilhoService _filhoService = FilhoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  List<Filho> _filhos = [];
  Filho? _filhoSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarFilhos();
  }

  // Carrega a lista de filhos do Firebase
  Future<void> _carregarFilhos() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final filhos = await _filhoService.buscarFilhos(user.uid);
      setState(() {
        _filhos = filhos;
        if (filhos.isNotEmpty) {
          _filhoSelecionado = filhos.first;
        }
      });
    } catch (e) {
      _mostrarMensagem("Erro ao carregar filhos: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // ÁREA DE MÉTODOS DE TESTE (Lógica solicitada)
  // ==========================================

  // 1️⃣ DISPARA 7 DIAS ANTES (Simulação visual)
  Future<void> _testarNotificacao7Dias() async {
    if (_filhoSelecionado == null) return _mostrarMensagem('Selecione um filho');

    await NotificationSchedulerService.instance.enviarNotificacaoImediata(
      id: 777,
      titulo: 'Lembrete de Vacina',
      corpo: "FALTAM 7 DIAS PARA A VACINA 'Pentavalente'", 
      payload: 'filho_${_filhoSelecionado!.id}',
    );
    _mostrarMensagem('✅ Push de 7 dias enviado!');
  }

  // 2️⃣ DISPARA 1 DIA ANTES (Simulação visual)
  Future<void> _testarNotificacao1Dia() async {
    if (_filhoSelecionado == null) return _mostrarMensagem('Selecione um filho');

    await NotificationSchedulerService.instance.enviarNotificacaoImediata(
      id: 111,
      titulo: 'Lembrete de Vacina',
      corpo: "FALTAM 1 DIA PARA A VACINA 'Sabin'",
      payload: 'filho_${_filhoSelecionado!.id}',
    );
    _mostrarMensagem('✅ Push de 1 dia enviado!');
  }

  // 3️⃣ DISPARA NO DIA (Simulação visual)
  Future<void> _testarNotificacaoHoje() async {
    if (_filhoSelecionado == null) return _mostrarMensagem('Selecione um filho');

    await NotificationSchedulerService.instance.enviarNotificacaoImediata(
      id: 000,
      titulo: 'Dia de Vacina!',
      corpo: "DIA DE VACINAR SEU FILHO COM A VACINA 'Gripe'",
      payload: 'filho_${_filhoSelecionado!.id}',
    );
    _mostrarMensagem('✅ Push de Hoje enviado!');
  }
  
  // 4️⃣ AGENDAR TUDO (Realmente agenda no banco e manda aviso)
  Future<void> _testarTodasNotificacoes() async {
    if (_filhoSelecionado == null) return _mostrarMensagem('Selecione um filho');

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Agenda no sistema de notificações local baseado nas datas do Firebase
        await _filhoService.agendarNotificacoesDoFilho(
          usuarioId: user.uid,
          filhoId: _filhoSelecionado!.id,
        );
        
        // Push de confirmação
        await NotificationSchedulerService.instance.enviarNotificacaoImediata(
          id: 999,
          titulo: 'ImunizaKids',
          corpo: 'Todas as vacinas de ${_filhoSelecionado!.nome} foram agendadas!',
        );
        _mostrarMensagem('✅ Sincronização e Push realizados!');
      }
    } catch (e) {
      _mostrarMensagem('❌ Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper para SnackBars
  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==========================================
  // INTERFACE VISUAL (O Build que faltava)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Área de Testes (Notificações)"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Selecione a criança para o teste:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // DROPDOWN - Seletor de Filho
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.pink),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Filho>(
                        value: _filhoSelecionado,
                        isExpanded: true,
                        hint: const Text("Nenhum filho encontrado"),
                        items: _filhos.map((Filho filho) {
                          return DropdownMenuItem<Filho>(
                            value: filho,
                            child: Text(
                              filho.nome,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (Filho? novoValor) {
                          setState(() {
                            _filhoSelecionado = novoValor;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const Center(
                    child: Text(
                      "Botões de Simulação",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BOTÃO 1 - 7 DIAS
                  ElevatedButton.icon(
                    onPressed: _testarNotificacao7Dias,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.access_alarm),
                    label: const Text("Testar: Faltam 7 Dias"),
                  ),
                  
                  const SizedBox(height: 12),

                  // BOTÃO 2 - 1 DIA
                  ElevatedButton.icon(
                    onPressed: _testarNotificacao1Dia,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.timer_3),
                    label: const Text("Testar: Falta 1 Dia"),
                  ),

                  const SizedBox(height: 12),

                  // BOTÃO 3 - HOJE
                  ElevatedButton.icon(
                    onPressed: _testarNotificacaoHoje,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.notification_important),
                    label: const Text("Testar: É HOJE!"),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  
                  // BOTÃO 4 - SINCRONIZAR TUDO
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _testarTodasNotificacoes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_sync, size: 28),
                    label: const Text(
                      "Agendar TUDO (Real)",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Isso lê as vacinas do banco e agenda notificações reais no celular.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}