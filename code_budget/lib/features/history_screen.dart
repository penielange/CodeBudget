import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../data/models/models.dart';
import '../providers.dart';
import '../shared/money_background.dart';

const _monthNames = [
  '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late int _year;
  late int _month;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _year = n.year;
    _month = n.month;
  }

  Future<void> _deleteTx(TransactionModel tx, NumberFormat fmt, String currency) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la transaction ?'),
        content: Text(
          '${tx.categoryName}\n${fmt.format(tx.amount)} $currency\n\nCette action est définitive.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repoProvider).deleteTransaction(tx.id);
    ref.invalidate(allTxProvider);
    ref.invalidate(monthTxProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(monthIncomeProvider);
    ref.invalidate(monthExpenseProvider);
    ref.invalidate(expensesByCatProvider);
    ref.invalidate(alerts75Provider);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction supprimée'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    final income = repo.getTotalIncome(_year, _month);
    final expense = repo.getTotalExpense(_year, _month);
    final diff = income - expense; // différence revenus - dépenses
    final all = repo.getTransactionsByMonth(_year, _month);
    final txs = all.where((tx) {
      if (_filter == 'expense') return tx.isExpense;
      if (_filter == 'income') return tx.isIncome;
      return true;
    }).toList();
    final fmt = NumberFormat('#,###', 'fr_FR');
    final currency = repo.currency;
    final monthClosed = repo.isMonthClosed(_year, _month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          if (!monthClosed)
            IconButton(
              tooltip: 'Clôturer ce mois',
              icon: const Icon(Icons.lock_outline_rounded),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clôturer ce mois ?'),
                    content: Text(
                      'Les revenus et dépenses de ${_monthNames[_month]} $_year ne pourront plus être modifiés.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clôturer'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await repo.closeMonth(_year, _month);
                  setState(() {});
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _month--;
              if (_month < 1) {
                _month = 12;
                _year--;
              }
            }),
          ),
          Center(
            child: Text(
              '${_monthNames[_month]} $_year',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _month++;
              if (_month > 12) {
                _month = 1;
                _year++;
              }
            }),
          ),
        ],
      ),
      body: MoneyBackground(
        child: Column(
          children: [
            // Résumé du mois : revenus, dépenses, différence
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Text(
                      'Bilan — ${_monthNames[_month]} $_year',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Revenus',
                            value: fmt.format(income),
                            color: AppColors.income,
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Dépenses',
                            value: fmt.format(expense),
                            color: AppColors.expense,
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Différence',
                            value: fmt.format(diff),
                            color: diff >= 0 ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      diff >= 0
                          ? 'Vous avez épargné ${fmt.format(diff)} $currency ce mois-ci.'
                          : 'Déficit de ${fmt.format(diff.abs())} $currency ce mois-ci.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: diff >= 0 ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (monthClosed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Mois clôturé — aucune modification possible.',
                    style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _Chip(label: 'Tout', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Dépenses',
                    selected: _filter == 'expense',
                    color: AppColors.expense,
                    onTap: () => setState(() => _filter = 'expense'),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    label: 'Revenus',
                    selected: _filter == 'income',
                    color: AppColors.income,
                    onTap: () => setState(() => _filter = 'income'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: txs.isEmpty
                  ? const Center(child: Text('Aucune transaction ce mois-ci'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: txs.length,
                      itemBuilder: (_, i) {
                        final tx = txs[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (tx.isExpense ? AppColors.expense : AppColors.income).withOpacity(0.12),
                              child: Icon(
                                tx.isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: tx.isExpense ? AppColors.expense : AppColors.income,
                                size: 18,
                              ),
                            ),
                            title: Text(tx.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(tx.date) +
                                  (tx.note != null && tx.note!.isNotEmpty ? '\n${tx.note}' : ''),
                            ),
                            isThreeLine: tx.note != null && tx.note!.isNotEmpty,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${tx.isExpense ? '-' : '+'}${fmt.format(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: tx.isExpense ? AppColors.expense : AppColors.income,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                  tooltip: 'Modifier',
                                  onPressed: () async {
                                    await context.push('/add', extra: tx);
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                                  tooltip: 'Supprimer',
                                  onPressed: () => _deleteTx(tx, fmt, currency),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (color ?? AppColors.primary) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
