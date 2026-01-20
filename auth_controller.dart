import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AuthController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> cadastrarFilho(
      String usuarioId, String nomeFilho, DateTime dataNascimento) async {
    try {
      // Referência para a subcoleção de filhos do usuário
      final filhosRef =
          _db.collection('usuarios').doc(usuarioId).collection('filhos');

      // Verifica se o filho já existe
      final query = await filhosRef.where('nome', isEqualTo: nomeFilho).get();
      if (query.docs.isNotEmpty) {
        throw Exception('Filho já cadastrado.');
      }

      // Adiciona o filho ao Firestore
      final filhoRef = await filhosRef.add({
        'nome': nomeFilho,
        'dataNascimento': DateFormat('dd/MM/yyyy').format(dataNascimento),
      });

      // Cria a lista de vacinas para o filho
      await _criarListaVacinas(usuarioId, filhoRef.id, dataNascimento);
    } catch (e) {
      throw Exception('Erro ao cadastrar filho: $e');
    }
  }

  // Método para criar a lista de vacinas do filho
  Future<void> _criarListaVacinas(
      String usuarioId, String filhoId, DateTime dataNascimento) async {
    try {
      // Referência para a subcoleção de vacinas do filho
      final vacinasRef = _db
          .collection('usuarios')
          .doc(usuarioId)
          .collection('filhos')
          .doc(filhoId)
          .collection('vacinas_do_filho');

      // Lista de vacinas padrão
      final List<Map<String, dynamic>> calendarioVacinas = [
        {
          'idade': 'Ao nascer',
          'vacinas': [
            {'nome': 'BCG', 'doses': 1, 'descricao': 'Protege contra tuberculose.'},
            {'nome': 'Hepatite B', 'doses': 1, 'descricao': 'Protege contra hepatite B.'},
          ],
        },
        {
          'idade': '2 meses',
          'vacinas': [
            {'nome': 'Pentavalente', 'doses': 1, 'descricao': 'Protege contra difteria, tétano, coqueluche, hepatite B e meningite por Haemophilus influenzae tipo B.'},
            {'nome': 'Poliomielite (VIP)', 'doses': 1, 'descricao': 'Protege contra a poliomielite (paralisia infantil).'},
            {'nome': 'Rotavírus', 'doses': 1, 'descricao': 'Protege contra diarreia grave causada por rotavírus.'},
            {'nome': 'Pneumocócica 10-valente', 'doses': 1, 'descricao': 'Protege contra doenças causadas pelo pneumococo, como pneumonia e meningite.'},
          ],
        },
        {
          'idade': '4 meses',
          'vacinas': [
            {'nome': 'Pentavalente', 'doses': 2, 'descricao': 'Segunda dose da vacina.'},
            {'nome': 'Poliomielite (VIP)', 'doses': 2, 'descricao': 'Segunda dose da vacina.'},
            {'nome': 'Rotavírus', 'doses': 2, 'descricao': 'Segunda dose da vacina.'},
            {'nome': 'Pneumocócica 10-valente', 'doses': 2, 'descricao': 'Segunda dose da vacina.'},
          ],
        },
        {
          'idade': '6 meses',
          'vacinas': [
            {'nome': 'Pentavalente', 'doses': 3, 'descricao': 'Terceira dose da vacina.'},
            {'nome': 'Poliomielite (VIP)', 'doses': 3, 'descricao': 'Terceira dose da vacina.'},
            {'nome': 'Influenza (Gripe)', 'doses': 1, 'descricao': 'Protege contra a gripe.'},
          ],
        },
        {
          'idade': '12 meses',
          'vacinas': [
            {'nome': 'Tríplice Viral (SCR)', 'doses': 1, 'descricao': 'Protege contra sarampo, caxumba e rubéola.'},
            {'nome': 'Pneumocócica 10-valente', 'doses': 3, 'descricao': 'Terceira dose da vacina.'},
            {'nome': 'Meningocócica C', 'doses': 1, 'descricao': 'Reforço da vacina.'},
          ],
        },
        {
          'idade': '15 meses',
          'vacinas': [
            {'nome': 'Hepatite A', 'doses': 1, 'descricao': 'Protege contra a hepatite A.'},
            {'nome': 'Tetra Viral (SCR-V)', 'doses': 1, 'descricao': 'Protege contra sarampo, caxumba, rubéola e varicela.'},
            {'nome': 'DTP (Reforço)', 'doses': 1, 'descricao': 'Reforço para proteção contra difteria, tétano e coqueluche.'},
            {'nome': 'Poliomielite (VOP)', 'doses': 1, 'descricao': 'Reforço para proteção contra a poliomielite.'},
          ],
        },
        {
          'idade': '4 anos',
          'vacinas': [
            {'nome': 'DTP (Reforço)', 'doses': 1, 'descricao': 'Segundo reforço para proteção contra difteria, tétano e coqueluche.'},
            {'nome': 'Poliomielite (VOP)', 'doses': 1, 'descricao': 'Segundo reforço para proteção contra a poliomielite.'},
          ],
        },
        {
          'idade': '5 anos',
          'vacinas': [
            {'nome': 'Febre Amarela (Atenuada)', 'doses': 1, 'descricao': 'Protege contra a febre amarela. Dose única, caso a criança não tenha recebido as duas doses recomendadas antes de completar 5 anos.'},
            {'nome': 'Pneumocócica 23-valente', 'doses': 2, 'descricao': 'Protege contra infecções invasivas pelo pneumococo na população indígena. A 2ª dose deve ser feita 5 anos após a 1ª dose.'},
          ],
        },
        {
          'idade': '7 anos',
          'vacinas': [
            {'nome': 'Difteria e Tétano (dT)', 'doses': 3, 'descricao': 'Iniciar ou completar três doses. Reforço a cada 10 anos, ou a cada 5 anos em caso de ferimentos graves e contatos de difteria.'},
          ],
        },
        {
          'idade': '9 e 10 anos',
          'vacinas': [
            {'nome': 'HPV Papilomavírus Humano 6, 11, 16 e 18 (HPV4)', 'doses': 1, 'descricao': 'Protege contra o Papilomavírus Humano 6, 11, 16 e 18. Dose única.'},
          ],
        },
      ];

      // Adiciona as vacinas à subcoleção
      for (var item in calendarioVacinas) {
        final idade = item['idade'];
        final vacinasList = item['vacinas'] as List<dynamic>;
        final dataVacina = _calculateVacinaDate(idade, dataNascimento);

        for (var vacina in vacinasList) {
          await vacinasRef.add({
            'nome': vacina['nome'],
            'doses': vacina['doses'],
            'descricao': vacina['descricao'],
            'idade': idade,
            'data': DateFormat('dd/MM/yyyy').format(dataVacina),
            'status': 'pendente', // Status inicial da vacina
          });
        }
      }
    } catch (e) {
      throw Exception('Erro ao criar lista de vacinas: $e');
    }
  }

  // Método para calcular a data da vacina com base na idade
  DateTime _calculateVacinaDate(String idade, DateTime dataNascimento) {
    if (idade == 'Ao nascer') {
      return dataNascimento;
    } else if (idade.contains('meses')) {
      final meses = int.parse(idade.split(' ')[0]);
      return DateTime(dataNascimento.year, dataNascimento.month + meses, dataNascimento.day);
    } else if (idade.contains('anos')) {
      final anos = int.parse(idade.split(' ')[0]);
      return DateTime(dataNascimento.year + anos, dataNascimento.month, dataNascimento.day);
    } else {
      return dataNascimento;
    }
  }
}