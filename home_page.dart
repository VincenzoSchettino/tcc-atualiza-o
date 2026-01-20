import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tcc_3/views/datasimportantes.dart';
import 'package:tcc_3/views/notification.dart';
import 'package:tcc_3/views/todasvacinasscreen.dart';
import 'package:tcc_3/services/notification_service.dart';
import 'meus_filhos_screen.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _buildSaudacaoComNome() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Text(
        'Olá! O que precisa?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final nome = (data?['name'] ?? user.displayName ?? '').toString();

        return Text(
          nome.isNotEmpty
              ? 'Olá, $nome! O que precisa?'
              : 'Olá! O que precisa?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  /// 🔔 BOTÃO QUE ENVIA NOTIFICAÇÃO ANDROID
  Future<void> _enviarNotificacao() async {
    await AppNotification.instance.showNow(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'ImunizaKids',
      body: 'Esta é uma notificação enviada pela HomePage 🚀',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificação enviada com sucesso')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Bem-vindo!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.pink),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSaudacaoComNome(),
            const SizedBox(height: 16),

            /// 🔔 BOTÃO DE NOTIFICAÇÃO (PRINCIPAL)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _enviarNotificacao,
                icon: const Icon(Icons.notifications_active),
                label: const Text(
                  'Enviar notificação de teste',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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
                    label: 'Todas as Vacinas',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        TodasVacinasScreen.routeName,
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.family_restroom,
                    label: 'Meus filhos',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        MeusFilhosPage.routeName,
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.calendar_today,
                    label: 'Datas Importantes',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DatasImportantesScreen.routeName,
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.notifications,
                    label: 'Notificações',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        NotificacoesScreen.routeName,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.pink),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
