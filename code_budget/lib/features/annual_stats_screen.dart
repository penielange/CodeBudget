import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../providers.dart';
import '../shared/money_background.dart';

const _months = [
  '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
  'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
];

class AnnualStatsScreen extends ConsumerStatefulWidget {
  const AnnualStatsScreen({super.key});

  @override
  ConsumerState<AnnualStatsScreen> createState() => _AnnualStatsScreenState();
}

class _AnnualStatsScreenState extends ConsumerState<AnnualStatsScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    final fmt = NumberFormat('#,###', 'fr_FR');
    final currency = repo.currency;

    final incomeByMonth = <double>[];
    final expenseByMonth = <double>[];
    double totalIncome = 0;
    double totalExpense = 0;
    for (var m = 1; m <= 12; m++) {
      final i = repo.getTotalIncome(_year, m);
      final e = repo.getTotalExpense(_year, m);
      incomeByMonth.add(i);
      expenseByMonth.add(e);
      totalIncome += i;
      totalExpense += e;
    }
    final balance = totalIncome - totalExpense;
    final maxVal = [...incomeByMonth, ...expenseByMonth].fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 100000.0 : maxVal * 1.2;

    final byCat = <String, double>{};
    for (var m = 1; m <= 12; m++) {
      final map = repo.getExpensesByCategory(_year, m);
      map.forEach((k, v) => byCat[k] = (byCat[k] ?? 0) + v);
    }
    final catEntries = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques annuelles'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _year--)),
          Center(child: Text('$_year', style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _year++)),
        ],
      ),
      body: MoneyBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Revenus $_year',
                    value: '${fmt.format(totalIncome)} $currency',
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Dépenses',
                    value: '${fmt.format(totalExpense)} $currency',
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StatCard(
              label: 'Solde annuel',
              value: '${fmt.format(balance)} $currency',
              color: balance >= 0 ? AppColors.income : AppColors.expense,
            ),
            const SizedBox(height: 24),
            Text('Courbe revenus / dépenses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(color: AppColors.income, label: 'Revenus'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.expense, label: 'Dépenses'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 260,
              padding: const EdgeInsets.only(right: 12, top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 11,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (v, _) {
                          if (v <= 0) return const SizedBox.shrink();
                          final label = v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString();
                          return Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i > 11) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_months[i + 1], style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(12, (i) => FlSpot(i.toDouble(), incomeByMonth[i])),
                      isCurved: true,
                      color: AppColors.income,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.income,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(show: true, color: AppColors.income.withOpacity(0.08)),
                    ),
                    LineChartBarData(
                      spots: List.generate(12, (i) => FlSpot(i.toDouble(), expenseByMonth[i])),
                      isCurved: true,
                      color: AppColors.expense,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.expense,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(show: true, color: AppColors.expense.withOpacity(0.08)),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final isIncome = s.barIndex == 0;
                        return LineTooltipItem(
                          '${isIncome ? 'Revenu' : 'Dépense'}\n${fmt.format(s.y)} $currency',
                          TextStyle(
                            color: isIncome ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Dépenses par catégorie ($_year)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (catEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune dépense enregistrée cette année.'),
              )
            else
              ...catEntries.map((e) {
                final pct = totalExpense > 0 ? e.value / totalExpense * 100 : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${fmt.format(e.value)} (${pct.toStringAsFixed(0)}%)'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text('Détail mensuel', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(12, (i) {
              final inc = incomeByMonth[i];
              final exp = expenseByMonth[i];
              final b = repo.budgetFor(_year, i + 1);
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  title: Text(_months[i + 1]),
                  subtitle: Text(
                    'R ${fmt.format(inc)} · D ${fmt.format(exp)}'
                    '${b != null ? ' · Budget ${fmt.format(b.totalAmount)}' : ' · Budget 0'}',
                  ),
                  trailing: Text(
                    fmt.format(inc - exp),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: (inc - exp) >= 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
