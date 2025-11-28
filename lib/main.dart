import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const DinDinApp());
}

class DinDinApp extends StatelessWidget {
  const DinDinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DinDin',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Image.asset('assets/logo.png', width: 150, height: 150),
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> lancamentos = [];

  String filtroCategoria = 'Todas';
  final categorias = [
    'Todas',
    'Comida',
    'Transporte',
    'Lazer',
    'Saúde',
    'Outros',
  ];

  String tipoGrafico = 'Pizza';
  final tiposGraficos = ['Pizza', 'Barra', 'Linha'];

  @override
  void initState() {
    super.initState();
    _carregarLancamentos();
  }

  Future<void> _carregarLancamentos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('lancamentos');
    if (jsonString != null) {
      final List loaded = jsonDecode(jsonString);
      setState(() {
        lancamentos.addAll(List<Map<String, dynamic>>.from(loaded));
      });
    }
  }

  Future<void> _salvarLancamentos() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(lancamentos);
    await prefs.setString('lancamentos', jsonString);
  }

  void _adicionarLancamento(Map<String, dynamic> lancamento) {
    setState(() {
      lancamentos.add(lancamento);
    });
    _salvarLancamentos();
  }

  void _editarLancamento(int index, Map<String, dynamic> lancamento) {
    setState(() {
      lancamentos[index] = lancamento;
    });
    _salvarLancamentos();
  }

  void _excluirLancamento(int index) {
    setState(() {
      lancamentos.removeAt(index);
    });
    _salvarLancamentos();
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = filtroCategoria == 'Todas'
        ? lancamentos
        : lancamentos.where((l) => l['categoria'] == filtroCategoria).toList();

    double total = 0;
    double totalReceitas = 0;
    double totalDespesas = 0;

    for (var l in lancamentos) {
      final valor = (l['valor'] ?? 0.0) as double;
      total += valor;

      if (valor >= 0) {
        totalReceitas += valor;
      } else {
        totalDespesas += valor.abs();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DinDin - Lançamentos'),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final novo = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLancamentoPage()),
          );

          if (novo != null) {
            _adicionarLancamento(novo);
          }
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // SALDO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Saldo Total"),
                    Text(
                      "R\$ ${total.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: total >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "Receitas: R\$ ${totalReceitas.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.green),
                    ),
                    Text(
                      "Despesas: R\$ ${totalDespesas.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FILTROS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filtroCategoria,
                    items: categorias
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => filtroCategoria = v!),
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por categoria',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: tipoGrafico,
                    items: tiposGraficos
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => tipoGrafico = v!),
                    decoration: const InputDecoration(labelText: 'Gráfico'),
                  ),
                ),
              ],
            ),
          ),

          // GRAFICO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildGrafico(),
            ),
          ),

          const Divider(height: 1),

          // LISTA
          Expanded(
            child: listaFiltrada.isEmpty
                ? const Center(child: Text('Nenhum lançamento encontrado.'))
                : ListView.builder(
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      final l = listaFiltrada[index];
                      final originalIndex = lancamentos.indexOf(l);

                      return ListTile(
                        title: Text(l['descricao']),
                        subtitle: Text(
                          'Categoria: ${l['categoria']}  |  ${l['tipo']} | ${l['data']}',
                        ),
                        leading: Text(
                          'R\$ ${(l['valor']).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: (l['valor']) >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final edit = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddLancamentoPage(lancamento: l),
                                  ),
                                );
                                if (edit != null) {
                                  _editarLancamento(originalIndex, edit);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _excluirLancamento(originalIndex),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRÁFICOS
  // ============================================================

  Widget _buildGrafico() {
    final Map<String, double> dados = {};

    for (var l in lancamentos) {
      final cat = l['categoria'];
      final val = (l['valor']).abs();
      dados[cat] = (dados[cat] ?? 0) + val;
    }

    if (dados.isEmpty) {
      return const Center(child: Text('Sem dados para o gráfico'));
    }

    final categoriasList = dados.keys.toList();
    final valores = dados.values.toList();

    // PALETA DEFINIDA
    const entradaColor = Color(0xFF2ECC71); // Verde Esmeralda
    const saidaColor = Color(0xFFE74C3C); // Vermelho Coral

    // Outras categorias fixas e bonitas
    const Map<String, Color> palette = {
      "Entrada": entradaColor,
      "Saída": saidaColor,
      "Comida": Color(0xFF3498DB), // Azul
      "Transporte": Color(0xFFF1C40F), // Amarelo
      "Lazer": Color(0xFF9B59B6), // Roxo
      "Saúde": Color(0xFF1ABC9C), // Verde água
      "Outros": Color(0xFF95A5A6), // Cinza
    };

    Color getColor(String categoria) {
      return palette[categoria] ?? Colors.grey;
    }

    // ================================
    // GRÁFICO DE PIZZA
    // ================================
    if (tipoGrafico == 'Pizza') {
      return PieChart(
        PieChartData(
          sections: List.generate(dados.length, (i) {
            final cat = categoriasList[i];
            return PieChartSectionData(
              value: valores[i],
              title: cat,
              color: getColor(cat), // <- cor definida bonitona
              radius: 60,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          }),
          centerSpaceRadius: 30,
        ),
      );
    }

    // ================================
    // GRÁFICO DE BARRA
    // ================================
    if (tipoGrafico == 'Barra') {
      return BarChart(
        BarChartData(
          barGroups: List.generate(dados.length, (i) {
            final cat = categoriasList[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valores[i],
                  color: getColor(cat),
                  width: 18,
                ),
              ],
            );
          }),
        ),
      );
    }

    // ================================
    // GRÁFICO DE LINHA
    // ================================
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              dados.length,
              (i) => FlSpot(i.toDouble(), valores[i]),
            ),
            isCurved: true,
            barWidth: 4,
            color: const Color(0xFF2D3436), // cinza escuro moderno
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2D3436).withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TELA DE ADICIONAR / EDITAR LANÇAMENTO
// ============================================================

class AddLancamentoPage extends StatefulWidget {
  final Map<String, dynamic>? lancamento;
  const AddLancamentoPage({super.key, this.lancamento});

  @override
  State<AddLancamentoPage> createState() => _AddLancamentoPageState();
}

class _AddLancamentoPageState extends State<AddLancamentoPage> {
  late TextEditingController descricaoCtrl;
  late TextEditingController valorCtrl;

  String categoriaSelecionada = 'Comida';
  String tipoSelecionado = 'Entrada'; // default
  final categorias = ['Comida', 'Transporte', 'Lazer', 'Saúde', 'Outros'];

  @override
  void initState() {
    super.initState();
    descricaoCtrl = TextEditingController(
      text: widget.lancamento?['descricao'] ?? '',
    );
    valorCtrl = TextEditingController(
      text: widget.lancamento?['valor']?.abs().toString() ?? '',
    );

    categoriaSelecionada = widget.lancamento?['categoria'] ?? 'Comida';

    if (widget.lancamento != null) {
      tipoSelecionado = widget.lancamento!['valor'] >= 0 ? 'Entrada' : 'Saída';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lancamento == null
              ? 'Adicionar Lançamento'
              : 'Editar Lançamento',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: descricaoCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: valorCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),

            const SizedBox(height: 20),

            // ============================
            // RADIO TIPO
            // ============================
            const Text("Tipo", style: TextStyle(fontSize: 16)),
            Row(
              children: [
                Radio<String>(
                  value: 'Entrada',
                  groupValue: tipoSelecionado,
                  onChanged: (v) => setState(() => tipoSelecionado = v!),
                ),
                const Text("Entrada"),
                const SizedBox(width: 20),

                Radio<String>(
                  value: 'Saída',
                  groupValue: tipoSelecionado,
                  onChanged: (v) => setState(() => tipoSelecionado = v!),
                ),
                const Text("Saída"),
              ],
            ),

            const SizedBox(height: 12),

            // Só mostra categoria se for SAÍDA
            if (tipoSelecionado == "Saída")
              DropdownButtonFormField<String>(
                value: categoriaSelecionada,
                items: categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => categoriaSelecionada = v!),
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                double valor =
                    double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0;

                // Entrada fica positiva | Saída fica negativa
                if (tipoSelecionado == 'Saída') {
                  valor = -valor;
                }

                final dataFormatada =
                    "${DateTime.now().day.toString().padLeft(2, '0')}/"
                    "${DateTime.now().month.toString().padLeft(2, '0')}/"
                    "${DateTime.now().year}";

                Navigator.pop(context, {
                  'descricao': descricaoCtrl.text,
                  'valor': valor,
                  'categoria': tipoSelecionado == "Entrada"
                      ? "Entrada" // <-- Categoria automática!
                      : categoriaSelecionada,
                  'tipo': tipoSelecionado,
                  'data': dataFormatada,
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
