import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tcc_3/models/vacina_model.dart';
import 'package:tcc_3/services/filho_service.dart';
import 'package:tcc_3/services/notification_service.dart';


// ===============================
// UTIL
// ===============================
bool isHoje(DateTime data) {
  final now = DateTime.now();
  return data.year == now.year &&
      data.month == now.month &&
      data.day == now.day;
}

// ===============================
// SCREEN
// ===============================
class VacinasTomadasScreen extends StatefulWidget {
  const VacinasTomadasScreen({super.key});

  @override
  State<VacinasTomadasScreen> createState() => _VacinasTomadasScreenState();
}

class _VacinasTomadasScreenState extends State<VacinasTomadasScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FilhoService _filhoService = FilhoService();

  List<Vacina> _listaVacinas = [];
  final Set<String> _idsMarcados = {};

  String? usuarioId;
  String? filhoId;
  DateTime? dataNascimentoFilho;
  bool isLoading = true;
  bool isInitialized = false;

  // ===============================
  // INIT
  // ===============================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        usuarioId = args['usuarioId'];
        filhoId = args['filhoId'];
        _loadData();
      }
      isInitialized = true;
    }
  }

  // ===============================
  // LOAD DATA
  // ===============================
  Future<void> _loadData() async {
    if (usuarioId == null || filhoId == null) return;

    setState(() => isLoading = true);

    try {
      // FILHO
      final filhoDoc = await _firestore
          .collection('usuarios')
          .doc(usuarioId)
          .collection('filhos')
          .doc(filhoId)
          .get();

      if (filhoDoc.exists) {
        final dn = filhoDoc['dataNascimento'];
        dataNascimentoFilho =
            dn is Timestamp ? dn.toDate() : DateTime.parse(dn);
      }

      // CATÁLOGO
      final catalogo = await _firestore.collection('vaccines').get();

      // STATUS VACINAS
      final statusSnapshot = await _firestore
          .collection('usuarios')
          .doc(usuarioId)
          .collection('filhos')
          .doc(filhoId)
          .collection('status_vacinas')
          .get();

      _idsMarcados.clear();
      for (var doc in statusSnapshot.docs) {
        if (doc.data()['tomada'] == true) {
          _idsMarcados.add(doc.id);
        }
      }

      final List<Vacina> listaTemp = [];

      for (var doc in catalogo.docs) {
        final data = doc.data();
        final meses = int.tryParse(data['meses'].toString()) ?? 0;

        listaTemp.add(
          Vacina(
            id: doc.id,
            nome: data['nome'] ?? '',
            meses: meses,
            descricao: data['descricao'] ?? '',
            doencasEvitadas:
                List<String>.from(data['doencasEvitadas'] ?? []),
            tomada: _idsMarcados.contains(doc.id),
          ),
        );
      }

      listaTemp.sort((a, b) => a.meses.compareTo(b.meses));

      setState(() {
        _listaVacinas = listaTemp;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar vacinas: $e');
      setState(() => isLoading = false);
    }
  }

  // ===============================
  // TOGGLE CHECKBOX (FINAL)
  // ===============================
  Future<void> _toggleCheckbox(String vacinaId, bool novoValor) async {
    if (usuarioId == null || filhoId == null) return;
    
    final index = _listaVacinas.indexWhere((v) => v.id == vacinaId);
    if (index == -1) return;

    final vacina = _listaVacinas[index];

    // UI PRIMEIRO
    setState(() {
      _listaVacinas[index] = Vacina(
        id: vacina.id,
        nome: vacina.nome,
        meses: vacina.meses,
        descricao: vacina.descricao,
        doencasEvitadas: vacina.doencasEvitadas,
        tomada: novoValor,
      );

      novoValor
          ? _idsMarcados.add(vacinaId)
          : _idsMarcados.remove(vacinaId);
    });

    // FIRESTORE
    await _filhoService.atualizarVacinaFilho(
      usuarioId: usuarioId!,
      filhoId: filhoId!,
      vacinaId: vacinaId,
      tomada: novoValor,
    );

    // NOTIFICAÇÕES
    if (!novoValor || dataNascimentoFilho == null) return;

    final dataPrevista = DateTime(
      dataNascimentoFilho!.year,
      dataNascimentoFilho!.month + vacina.meses,
      dataNascimentoFilho!.day,
    );

    if (isHoje(dataPrevista)) {
      await AppNotification.instance.showNow(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Dia de vacinação',
        body: 'Vacina ${vacina.nome} prevista para hoje.',
      );
    }
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controle de Vacinas',
          style: TextStyle(color: Colors.pink),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.pink),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: _listaVacinas.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final vacina = _listaVacinas[index];
                return CheckboxListTile(
                  value: vacina.tomada,
                  title: Text(vacina.nome),
                  subtitle: Text('${vacina.meses} meses'),
                  activeColor: Colors.green,
                  onChanged: (v) {
                    if (v != null) {
                      _toggleCheckbox(vacina.id!, v);
                    }
                  },
                );
              },
            ),
    );
  }
}
