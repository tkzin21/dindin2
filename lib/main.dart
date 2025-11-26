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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      // AGORA COMEÇA PELA SPLASH
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.monetization_on, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text("DinDin", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// =============================================
// TODO O RESTO DO SEU CÓDIGO ORIGINAL CONTINUA AQUI
// SEM ALTERAR NADA
// =============================================

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> lancamentos = [];

  String filtroCategoria = 'Todas';
  final categorias = ['Todas', 'Comida', 'Transporte', 'Lazer', 'Saúde', 'Outros'];

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

      if (l['tipo'] == 'Receita') {
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
          if (novo != null && novo is Map<String, dynamic>) {
            _adicionarLancamento(novo);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Saldo Total", style: TextStyle(fontSize: 14)),
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Receitas: R\$ ${totalReceitas.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.green)),
                    Text("Despesas: R\$ ${totalDespesas.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.red)),
                  ],
                )
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: filtroCategoria,
                    items: categorias
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => filtroCategoria = v ?? 'Todas'),
                    decoration: const InputDecoration(labelText: 'Filtrar por categoria'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: tipoGrafico,
                    items: tiposGraficos
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => tipoGrafico = v ?? 'Pizza'),
                    decoration: const InputDecoration(labelText: 'Tipo de Gráfico'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildGrafico(),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: listaFiltrada.isEmpty
                ? const Center(child: Text('Nenhum lançamento encontrado.'))
                : ListView.builder(
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      final l = listaFiltrada[index];
                      final originalIndex = lancamentos.indexOf(l);
                      return ListTile(
                        title: Text(l['descricao'] ?? ''),
                        subtitle: Text('Categoria: ${l['categoria'] ?? ''}  |  ${l['tipo']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final edit = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddLancamentoPage(
                                      lancamento: l,
                                    ),
                                  ),
                                );
                                if (edit != null && edit is Map<String, dynamic>) {
                                  _editarLancamento(originalIndex, edit);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _excluirLancamento(originalIndex);
                              },
                            ),
                          ],
                        ),
                        leading: Text(
                          'R\$ ${(l['valor'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: (l['valor'] as double) >= 0 ? Colors.green : Colors.red,
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

  Widget _buildGrafico() {
    final Map<String, double> dados = {};

    for (var l in lancamentos) {
      final cat = (l['categoria'] ?? 'Outros') as String;
      final val = (l['valor'] ?? 0.0) as double;
      dados[cat] = (dados[cat] ?? 0) + val.abs();
    }

    if (dados.isEmpty) return const Center(child: Text('Sem dados para o gráfico'));

    final categoriasList = dados.keys.toList();
    final valores = dados.values.toList();

    switch (tipoGrafico) {
      case 'Pizza':
        return PieChart(
          PieChartData(
            sections: List.generate(dados.length, (i) {
              return PieChartSectionData(
                value: valores[i],
                title: categoriasList[i],
                color: Colors.primaries[i % Colors.primaries.length],
                radius: 60,
                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              );
            }),
            sectionsSpace: 2,
            centerSpaceRadius: 30,
          ),
        );

      case 'Barra':
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barGroups: List.generate(dados.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: valores[i],
                    color: Colors.primaries[i % Colors.primaries.length],
                  ),
                ],
              );
            }),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= categoriasList.length) return const SizedBox.shrink();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(categoriasList[idx], style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
          ),
        );

      case 'Linha':
        return LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= categoriasList.length) return const SizedBox.shrink();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(categoriasList[idx], style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  dados.length,
                  (i) => FlSpot(i.toDouble(), valores[i]),
                ),
                isCurved: true,
                color: Colors.primaries[0],
                barWidth: 3,
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        );

      default:
        return const Center(child: Text('Tipo de gráfico inválido'));
    }
  }
}

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
  String tipoSelecionado = 'Despesa';

  final categorias = ['Comida', 'Transporte', 'Lazer', 'Saúde', 'Outros'];
  final tipos = ['Despesa', 'Receita'];

  @override
  void initState() {
    super.initState();
    descricaoCtrl = TextEditingController(text: widget.lancamento?['descricao'] ?? '');
    double valor = widget.lancamento?['valor'] ?? 0.0;
    valorCtrl = TextEditingController(text: valor.toString());
    categoriaSelecionada = widget.lancamento?['categoria'] ?? 'Comida';
    tipoSelecionado = widget.lancamento?['tipo'] ?? 'Despesa';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lancamento == null ? 'Adicionar Lançamento' : 'Editar Lançamento')),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: tipoSelecionado,
              items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => tipoSelecionado = v ?? 'Despesa'),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: categoriaSelecionada,
              items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => categoriaSelecionada = v ?? 'Comida'),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                double valor = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
                if (tipoSelecionado == 'Despesa') valor = -valor;
                Navigator.pop(context, {
                  'descricao': descricaoCtrl.text,
                  'valor': valor,
                  'categoria': categoriaSelecionada,
                  'tipo': tipoSelecionado,
                });
              },
              child: const Text('Salvar'),
            )
          ],
        ),
      ),
    );
  }
}
