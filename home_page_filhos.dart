import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcc_3/models/filho_model.dart';
import 'package:tcc_3/views/vacinasscreen.dart';
import 'package:tcc_3/views/cadastrar_vacinas_screenfilho.dart';

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.pink),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePagefilhos extends StatefulWidget {
  final Filho filho;
  final bool mostrarDialog;
  final int? meses;
  final List<String>? vacinas;

  const HomePagefilhos({
    super.key,
    required this.filho,
    this.mostrarDialog = false,
    this.meses,
    this.vacinas,
  });

  @override
  State<HomePagefilhos> createState() => _HomePagefilhosState();
}

class _HomePagefilhosState extends State<HomePagefilhos> {
  bool _mostrarNotificacaoInput = false;
  String? _notificacaoTitulo;
  String? _notificacaoMensagem;

  @override
  void initState() {
    super.initState();

    if (widget.mostrarDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _configurarNotificacaoInput();
      });
    }
  }

  void _configurarNotificacaoInput() {
    final String mesesTexto = widget.meses == null
        ? ''
        : widget.meses == 0
            ? 'Hoje'
            : '${widget.meses} meses';

    final String vacinasTexto =
        widget.vacinas != null && widget.vacinas!.isNotEmpty
            ? widget.vacinas!.join(', ')
            : '';

    setState(() {
      _notificacaoTitulo = '🔔 Dia de vacinação';
      _notificacaoMensagem = 'Dia de vacinação: $mesesTexto\n'
          'Vacinas: $vacinasTexto';
      _mostrarNotificacaoInput = true;
    });
  }

  void _fecharNotificacaoInput() {
    setState(() {
      _mostrarNotificacaoInput = false;
      _notificacaoTitulo = null;
      _notificacaoMensagem = null;
    });
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/homemeusfilhos',
        (route) => false,
      );
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
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
        title: Text(
          widget.filho.nome,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'imagens/img1.png',
              height: 30,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.child_care, color: Colors.pink),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.pink),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔔 INPUT DE NOTIFICAÇÃO (AUTOMÁTICO)
          if (_mostrarNotificacaoInput)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active,
                          color: Colors.blue[600], size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _notificacaoTitulo ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.blue[600]),
                        onPressed: _fecharNotificacaoInput,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Text(
                      _notificacaoMensagem ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // RESTO DO CONTEÚDO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Olá, o que precisa?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        MenuCard(
                          icon: Icons.local_hospital,
                          label: 'Vacinas',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VacinasScreen(filho: widget.filho),
                              ),
                            );
                          },
                        ),
                        MenuCard(
                          icon: Icons.check_box,
                          label: 'Vacinas Tomadas',
                          onTap: () {
                            final usuarioId =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (usuarioId == null) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VacinasTomadasScreen(
                                  usuarioId: usuarioId,
                                  filhoId: widget.filho.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
