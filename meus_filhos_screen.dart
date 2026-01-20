import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcc_3/models/filho_model.dart';
import 'package:tcc_3/services/filho_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcc_3/views/home_page_filhos.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MeusFilhosPage extends StatefulWidget {
  static const String routeName = '/lista_filhos';
  const MeusFilhosPage({super.key});

  @override
  State<MeusFilhosPage> createState() => _MeusFilhosPageState();
}

class _MeusFilhosPageState extends State<MeusFilhosPage> {
  final FilhoService _filhoService = FilhoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _abrirTelaCadastroFilho() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CadastroFilhoScreen()),
    );
    // Com StreamBuilder, não precisa recarregar manualmente.
  }

  Stream<List<Filho>> _getFilhosStream(String userId) {
    // Como o novo FilhoService não tem stream, vamos criar um stream manual
    // que busca os dados periodicamente
    return Stream.periodic(const Duration(seconds: 2), (_) => null)
        .asyncMap((_) async {
      try {
        return await _filhoService.buscarFilhos(userId);
      } catch (e) {
        debugPrint('Erro ao buscar filhos: $e');
        return <Filho>[];
      }
    });
  }

  String _calcularIdade(DateTime nascimento) {
    final now = DateTime.now();

    int years = now.year - nascimento.year;
    int months = now.month - nascimento.month;

    if (now.day < nascimento.day) {
      months -= 1;
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    final totalMonths = years * 12 + months;

    if (totalMonths < 12) {
      return '$totalMonths meses';
    } else {
      final anos = totalMonths ~/ 12;
      return '$anos ${anos == 1 ? 'ano' : 'anos'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Meus Filhos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.pink),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "addFilho",
            onPressed: _abrirTelaCadastroFilho,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "testNotificacoes",
            onPressed: () {
              Navigator.pushNamed(context, '/test-notificacoes');
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Usuário não autenticado'))
          : StreamBuilder<List<Filho>>(
              stream: _getFilhosStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar filhos: ${snapshot.error}'),
                  );
                }

                final filhos = snapshot.data ?? [];
                if (filhos.isEmpty) {
                  return const Center(child: Text('Nenhum filho cadastrado'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filhos.length,
                  itemBuilder: (context, index) {
                    final filho = filhos[index];
                    final idade = _calcularIdade(filho.dataNascimento);

                    final fotoUrl = (filho.fotoUrl ?? '').trim();
                    final hasPhoto = fotoUrl.isNotEmpty;

                    return GestureDetector(
                      onTap: () {
                        print(
                            '🔗 Card do filho clicado! Navegando para ${filho.nome}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePagefilhos(filho: filho),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header com informações do filho
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                        hasPhoto ? NetworkImage(fotoUrl) : null,
                                    child: !hasPhoto
                                        ? Text(
                                            filho.nome.isNotEmpty
                                                ? filho.nome[0].toUpperCase()
                                                : '?',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          filho.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          'Idade: $idade',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CadastroFilhoScreen(
                                                      filhoExistente: filho),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () async {
                                          try {
                                            await _filhoService.excluirFilho(
                                                user.uid,
                                                filho.id);
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Erro ao excluir: $e')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class CadastroFilhoScreen extends StatefulWidget {
  final Filho? filhoExistente;

  const CadastroFilhoScreen({super.key, this.filhoExistente});

  @override
  State<CadastroFilhoScreen> createState() => _CadastroFilhoScreenState();
}

class _CadastroFilhoScreenState extends State<CadastroFilhoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  DateTime _dataNascimento = DateTime.now();
  String _genero = 'Masculino';

  final FilhoService _filhoService = FilhoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Uuid _uuid = const Uuid();
  File? _imagemSelecionada;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.filhoExistente != null) {
      _nomeController.text = widget.filhoExistente!.nome;
      _dataNascimento = widget.filhoExistente!.dataNascimento;
      _genero = widget.filhoExistente!.genero;
      _fotoUrl = widget.filhoExistente!.fotoUrl;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Selecionar da Galeria'),
              onTap: () async {
                final picker = ImagePicker();
                final picked =
                    await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _imagemSelecionada = File(picked.path));
                }
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Selecionar do Google Drive'),
              onTap: () async {
                final result =
                    await FilePicker.platform.pickFiles(type: FileType.image);
                if (result != null && result.files.single.path != null) {
                  setState(() =>
                      _imagemSelecionada = File(result.files.single.path!));
                }
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImagem(String filhoId) async {
    if (_imagemSelecionada == null) return _fotoUrl;

    const apiKey = 'd26b5b58a9ec97488e7cbd8e554ba194'; // sua chave ImgBB
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    try {
      final bytes = await _imagemSelecionada!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(url, body: {
        'image': base64Image,
        'name': 'filho_$filhoId',
      });

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']['url'];
      } else {
        debugPrint('Erro no upload ImgBB: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exceção ao fazer upload ImgBB: $e');
      return null;
    }
  }

  Future<void> _salvarFilho() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final filhoId = widget.filhoExistente?.id ?? _uuid.v4();
      final fotoUrl = await _uploadImagem(filhoId);

      final filho = Filho(
        id: filhoId,
        nome: _nomeController.text.trim(),
        dataNascimento: _dataNascimento,
        genero: _genero,
        usuarioId: user.uid,
        fotoUrl: fotoUrl,
      );

      // --- CADASTRO NOVO ---
      if (widget.filhoExistente == null) {
        await _filhoService.adicionarFilho(user.uid, filho);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePagefilhos(filho: filho),
          ),
        );
        return;
      }

      // --- EDIÇÃO (CORRIGIDA) ---
      // 1. Apenas atualiza o filho específico
      await _filhoService.atualizarFilho(user.uid, filho);

      // 2. Verifica se a data de nascimento mudou para recalcular vacinas
      final dataNascimentoAntiga = widget.filhoExistente!.dataNascimento;
      final mudouNascimento =
          dataNascimentoAntiga.year != filho.dataNascimento.year ||
              dataNascimentoAntiga.month != filho.dataNascimento.month ||
              dataNascimentoAntiga.day != filho.dataNascimento.day;

      if (mudouNascimento) {
        await _filhoService.agendarNotificacoesDoFilho(
          usuarioId: user.uid,
          filhoId: filho.id,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final imagemWidget = _imagemSelecionada != null
        ? CircleAvatar(
            radius: 40, backgroundImage: FileImage(_imagemSelecionada!))
        : (_fotoUrl != null && _fotoUrl!.trim().isNotEmpty)
            ? CircleAvatar(radius: 40, backgroundImage: NetworkImage(_fotoUrl!))
            : const CircleAvatar(radius: 40, child: Icon(Icons.person));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            widget.filhoExistente == null ? 'Cadastrar Filho' : 'Editar Filho'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _selecionarImagem,
                  child: imagemWidget,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Digite o nome do filho'
                    : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Data de Nascimento'),
                subtitle: Text(
                  DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR')
                      .format(_dataNascimento),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dataNascimento,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (date != null) setState(() => _dataNascimento = date);
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _genero,
                decoration: const InputDecoration(
                  labelText: 'Gênero',
                  border: OutlineInputBorder(),
                ),
                items: const ['Masculino', 'Feminino']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _genero = value ?? 'Masculino'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvarFilho,
                  child: Text(widget.filhoExistente == null
                      ? 'Cadastrar'
                      : 'Salvar Alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
