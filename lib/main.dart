import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> lancamentos = [];

  String filtroCategoria = 'Todas';
  final categorias = ['Todas', 'Comida', 'Transporte', 'Lazer', 'Saúde', 'Outros'];

  String tipoGrafico = 'Pizza';
  final tiposGraficos = ['Pizza', 'Barra', 'Linha'];

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = filtroCategoria == 'Todas'
        ? lancamentos
        : lancamentos.where((l) => l['categoria'] == filtroCategoria).toList();

    // -------------------- CÁLCULOS --------------------
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
            setState(() => lancamentos.add(novo));
          }
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // ---------------- SALDO E TOTAL ----------------
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

          // ---------- FILTROS E TIPO DE GRÁFICO ----------
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
                    onChanged: (v) => setState(() => filtroCategoria = v ?? 'Todas'),
                    decoration: const InputDecoration(labelText: 'Filtrar por categoria'),
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
                    onChanged: (v) => setState(() => tipoGrafico = v ?? 'Pizza'),
                    decoration: const InputDecoration(labelText: 'Tipo de Gráfico'),
                  ),
                ),
              ],
            ),
          ),

          // ---------------- GRÁFICO ----------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildGrafico(),
            ),
          ),
          const Divider(height: 1),

          // ---------------- LISTA ----------------
          Expanded(
            child: listaFiltrada.isEmpty
                ? const Center(child: Text('Nenhum lançamento encontrado.'))
                : ListView.builder(
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      final l = listaFiltrada[index];
                      return ListTile(
                        title: Text(l['descricao'] ?? ''),
                        subtitle: Text('Categoria: ${l['categoria'] ?? ''}  |  ${l['tipo']}'),
                        trailing: Text(
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

  // ---------------------------------------------------
  //                      GRÁFICOS
  // ---------------------------------------------------
  Widget _buildGrafico() {
    final Map<String, double> dados = {};

    for (var l in lancamentos) {
      final cat = (l['categoria'] ?? 'Outros') as String;
      final val = (l['valor'] ?? 0.0) as double;
      dados[cat] = (dados[cat] ?? 0) + val.abs();
    }

    if (dados.isEmpty) {
      return const Center(child: Text('Sem dados para o gráfico'));
    }

    final categoriasList = dados.keys.toList();
    final valores = dados.values.toList();

    switch (tipoGrafico) {
      // ------------ PIZZA ------------
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

      // ------------ BARRA ------------
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
                      child: Text(categoriasList[idx], style: const TextStyle(fontSize: 10)),
                      axisSide: meta.axisSide,
                    );
                  },
                ),
              ),
            ),
          ),
        );

      // ------------ LINHA ------------
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
                      child: Text(categoriasList[idx], style: const TextStyle(fontSize: 10)),
                      axisSide: meta.axisSide,
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
  const AddLancamentoPage({super.key});

  @override
  State<AddLancamentoPage> createState() => _AddLancamentoPageState();
}

class _AddLancamentoPageState extends State<AddLancamentoPage> {
  final TextEditingController descricaoCtrl = TextEditingController();
  final TextEditingController valorCtrl = TextEditingController();

  String categoriaSelecionada = 'Comida';
  String tipoSelecionado = 'Despesa';

  final categorias = ['Comida', 'Transporte', 'Lazer', 'Saúde', 'Outros'];
  final tipos = ['Despesa', 'Receita'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Lançamento')),
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
              value: tipoSelecionado,
              items: tipos
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => tipoSelecionado = v ?? 'Despesa'),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: categoriaSelecionada,
              items: categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => categoriaSelecionada = v ?? 'Comida'),
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                double valor =
                    double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0;

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
