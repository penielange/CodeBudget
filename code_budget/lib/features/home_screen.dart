import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../data/models/models.dart';
import '../providers.dart';
import '../shared/money_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(balanceProvider);
    final monthClosed = ref.watch(repoProvider).isCurrentMonthClosed();
    final income = ref.watch(monthIncomeProvider);
    final expense = ref.watch(monthExpenseProvider);
    final txs = ref.watch(monthTxProvider);
    final alerts = ref.watch(alerts75Provider);
    final currency = ref.watch(repoProvider).currency;
    final fmt = NumberFormat('#,###', 'fr_FR');

    return MoneyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(balanceProvider);
              ref.invalidate(monthIncomeProvider);
              ref.invalidate(monthExpenseProvider);
              ref.invalidate(monthTxProvider);
              ref.invalidate(alerts75Provider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 42,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 40),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CodeBudget', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => context.push('/annual'),
                      icon: const Icon(Icons.bar_chart_rounded),
                      tooltip: 'Stats annuelles',
                    ),
                    IconButton.filledTonal(
                      onPressed: () => context.push('/help'),
                      icon: const Icon(Icons.help_outline_rounded),
                      tooltip: 'Guide',
                    ),
                    IconButton.filledTonal(
                      onPressed: () => context.push('/about'),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  ],
                ).animate().fadeIn(),
                if (alerts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...alerts.map(
                    (a) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.expense.withOpacity(0.55)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppColors.expense, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(a, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.expense))),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (monthClosed)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.expense.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'Mois clôturé — consultation seule (plus de modification).',
                      style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                _BalanceCard(balance: balance, currency: currency, fmt: fmt),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Mini(
                        title: 'Revenus',
                        amount: income,
                        color: AppColors.income,
                        icon: Icons.arrow_downward_rounded,
                        fmt: fmt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Mini(
                        title: 'Dépenses',
                        amount: expense,
                        color: AppColors.expense,
                        icon: Icons.arrow_upward_rounded,
                        fmt: fmt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BudgetHomeCard(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('Transactions du mois', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (!monthClosed)
                      TextButton.icon(
                        onPressed: () async {
                          final n = DateTime.now();
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clôturer le mois ?'),
                              content: const Text(
                                'Après clôture, les revenus et dépenses de ce mois ne pourront plus être modifiés.',
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
                            await ref.read(repoProvider).closeMonth(n.year, n.month);
                            ref.invalidate(monthTxProvider);
                            ref.invalidate(balanceProvider);
                            ref.invalidate(alerts75Provider);
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.lock_outline_rounded, size: 18),
                        label: const Text('Clôturer'),
                      )
                    else
                      const Text('Mois clôturé', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                if (txs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Commencez par un revenu', textAlign: TextAlign.center),
                        Text(
                          'Budget et prévisions basés uniquement sur le revenu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ...txs.take(15).map((tx) => _TxTile(
                      tx: tx,
                      fmt: fmt,
                      currency: currency,
                      onEdit: monthClosed
                          ? null
                          : () async {
                        await context.push('/add', extra: tx);
                        ref.invalidate(monthTxProvider);
                        ref.invalidate(allTxProvider);
                        ref.invalidate(balanceProvider);
                        ref.invalidate(monthIncomeProvider);
                        ref.invalidate(monthExpenseProvider);
                        ref.invalidate(alerts75Provider);
                      },
                      onDelete: monthClosed
                          ? null
                          : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Supprimer ?'),
                            content: Text('${tx.categoryName} — ${fmt.format(tx.amount)} $currency'),
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
                        if (ok == true) {
                          await ref.read(repoProvider).deleteTransaction(tx.id);
                          ref.invalidate(monthTxProvider);
                          ref.invalidate(allTxProvider);
                          ref.invalidate(balanceProvider);
                          ref.invalidate(monthIncomeProvider);
                          ref.invalidate(monthExpenseProvider);
                          ref.invalidate(alerts75Provider);
                        }
                      },
                    )),
              ],
            ),
          ),
        ),
        floatingActionButton: monthClosed
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push('/add'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Transaction'),
              ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final String currency;
  final NumberFormat fmt;
  const _BalanceCard({required this.balance, required this.currency, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final ok = balance >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ok ? [AppColors.primary, const Color(0xFF1D4ED8)] : [const Color(0xFFB91C1C), AppColors.expense],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Solde du mois', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text('${fmt.format(balance)} $currency',
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat fmt;
  const _Mini({required this.title, required this.amount, required this.color, required this.icon, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Text(fmt.format(amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  final NumberFormat fmt;
  final String currency;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _TxTile({
    required this.tx,
    required this.fmt,
    required this.currency,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.isExpense;
    final title = tx.subcategoryName != null && tx.subcategoryName!.isNotEmpty
        ? '${tx.categoryName} · ${tx.subcategoryName}'
        : tx.categoryName;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: isExpense ? AppColors.expense : AppColors.income,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  DateFormat('dd MMM', 'fr_FR').format(tx.date),
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${fmt.format(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isExpense ? AppColors.expense : AppColors.income,
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
              tooltip: 'Modifier',
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
              tooltip: 'Supprimer',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _BudgetHomeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repoProvider);
    final now = DateTime.now();
    final b = repo.getCurrentBudget();
    final income = ref.watch(monthIncomeProvider);
    final expense = ref.watch(monthExpenseProvider);
    final currency = repo.currency;
    final fmt = NumberFormat('#,###', 'fr_FR');
    final budget = b?.totalAmount ?? 0.0;
    final progress = budget > 0 ? (expense / budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Budget du mois', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              TextButton(
                onPressed: () => context.push('/forecasts'),
                child: Text(budget <= 0 ? 'Définir' : 'Modifier'),
              ),
            ],
          ),
          Text(
            budget <= 0 ? '0 $currency (non défini)' : '${fmt.format(budget)} $currency',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: budget <= 0 ? AppColors.textSecondary : AppColors.primary,
            ),
          ),
          if (budget > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                color: progress >= 0.75 ? AppColors.expense : AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Dépensé ${fmt.format(expense)} / ${fmt.format(budget)} · Revenus ${fmt.format(income)}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ] else
            Text(
              'Définissez un budget ≤ à vos revenus (${fmt.format(income)} $currency).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
