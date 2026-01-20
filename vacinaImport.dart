import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // Para debugPrint
import 'package:tcc_3/models/vacina_model.dart';

class VaccineImporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> importVaccinesFromExcel() async {
    try {
      debugPrint("📂 Iniciando leitura do arquivo Excel...");

      // 1. Carregar o arquivo Excel
      final ByteData data = await rootBundle.load('assets/vacinas.xlsx');
      final bytes = data.buffer.asUint8List();
      final excel = Excel.decodeBytes(bytes);

      // 2. Acessar a primeira planilha
      if (excel.tables.isEmpty) return;
      final Sheet sheet = excel.tables[excel.tables.keys.first]!;

      // 3. Verificar se a coleção já existe
      final snapshot = await _firestore.collection('vaccines').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ Coleção de vacinas já existe, importação cancelada.');
        return;
      }

      // 4. Processar cada linha
      final batch = _firestore.batch();
      final vaccinesRef = _firestore.collection('vaccines');
      int count = 0;

      for (var row in sheet.rows.skip(1)) { // Pular cabeçalho
        if (row.length < 5) continue; // Verifica se tem pelo menos 5 colunas

        // --- SUAS VARIÁVEIS ORIGINAIS ---
        final idCell = row[0];       // Coluna A (ID)
        final monthsCell = row[1];   // Coluna B (meses)
        final nameCell = row[2];     // Coluna C (nome)
        final diseasesCell = row[3]; // Coluna D (doenças evitadas)
        final descCell = row[4];     // Coluna E (descrição)

        // --- PROCESSAMENTO DIRETO (SEM BLINDAGEM) ---

        // ID: Usa o valor da célula ou gera um ID novo se for nulo
        final id = idCell?.value?.toString().trim() ?? vaccinesRef.doc().id;

        // Meses: Converte direto para String e depois para int (Cuidado: o Excel não pode ter ponto flutuante aqui)
        final months = int.parse(monthsCell!.value.toString());

        // Nome
        final name = nameCell?.value?.toString().trim() ?? '';
        if (name.isEmpty) continue;

        // Doenças
        final diseasesText = diseasesCell?.value?.toString() ?? '';
        final preventedDiseases = diseasesText
            .split(RegExp(r'[,;]'))
            .map((d) => d.trim())
            .where((d) => d.isNotEmpty)
            .toList();

        // Descrição
        final description = descCell?.value?.toString().trim() ?? '';

        // Criar documento
        final vaccine = Vacina(
          id: id,
          nome: name,
          meses: months,
          doencasEvitadas: preventedDiseases,
          descricao: description,
          tomada: false,
        );
        
        batch.set(vaccinesRef.doc(id), vaccine.toMap());
        count++;
      }

      // 5. Commit do batch
      if (count > 0) {
        await batch.commit();
        debugPrint('🏁 Importação concluída! ($count vacinas)');
      }

    } catch (e) {
      debugPrint('Erro ao importar vacinas: $e');
      // rethrow; 
    }
  }
}