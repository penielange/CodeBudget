import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../data/app_repository.dart';
import '../data/models/models.dart';
import '../providers.dart';
import '../shared/money_background.dart';

const _monthNames = [
  '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

class ForecastsScreen extends ConsumerStatefulWidget {
  const ForecastsScreen({super.key});

  @override
  ConsumerState<ForecastsScreen> createState() => _ForecastsScreenState();
}

class _ForecastsScreenState extends ConsumerState<ForecastsScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  Future<void> _editMonth(int month) async {
    final repo = ref.read(repoProvider);
    final existing = repo.budgetFor(_year, month);
    // Montants par sous-catégorie
    final amounts = <String, TextEditingController>{};
    for (final parent in repo.getCategories(incomeOnly: false)) {
      for (final s in repo.getSubcategories(parent.id)) {
        amounts[s.id] = TextEditingController(
          text: (existing?.allocMap[s.id] ?? 0).toStringAsFixed(0),
        );
      }
    }

    double sumAmounts() {
      double s = 0;
      for (final c in amounts.values) {
        s += double.tryParse(c.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
      }
      return s;
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final parents = ref.read(repoProvider).getCategories(incomeOnly: false);
            final total = sumAmounts();
            final fmt = NumberFormat('#,###', 'fr_FR');
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Prévision — ${_monthNames[month]} $_year',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Le budget du mois est calculé automatiquement\n'
                      '(somme de toutes les prévisions par sous-catégorie).',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    // Budget statique = somme auto
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Budget du mois (somme des prévisions)',
                        suffixText: repo.currency,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      child: Text(
                        total <= 0 ? '0' : fmt.format(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Catégories & sous-catégories', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...parents.map((parent) {
                      final subs = ref.read(repoProvider).getSubcategories(parent.id);
                      double sumSub = 0;
                      for (final s in subs) {
                        sumSub += double.tryParse(
                              (amounts[s.id]?.text ?? '0').replaceAll(',', '.'),
                            ) ??
                            0;
                      }
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(parent.icon, color: parent.color),
                          title: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            subs.isEmpty
                                ? 'Aucune sous-catégorie'
                                : '${subs.length} sous-catégorie(s) · prévu ${fmt.format(sumSub)}',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () async {
                            await _openSubcategoryPopup(
                              parent: parent,
                              amounts: amounts,
                              setParentModal: setModal,
                            );
                            setModal(() {}); // rafraîchit le total
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Enregistrer la prévision'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (ok == true) {
      try {
        final allocations = <String, double>{
          for (final e in amounts.entries)
            e.key: double.tryParse(e.value.text.replaceAll(' ', '').replaceAll(',', '.')) ?? 0,
        };
        final total = allocations.values.fold(0.0, (a, b) => a + b);
        await repo.saveMonthlyBudget(
          year: _year,
          month: month,
          totalAmount: total, // = somme auto des prévisions
          allocations: allocations,
        );
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prévision enregistrée ✓'), backgroundColor: AppColors.income),
          );
        }
      } on BudgetRuleException catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (dCtx) => AlertDialog(
              title: const Text('Erreur', style: TextStyle(color: AppColors.expense)),
              content: Text(e.message),
              actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('OK'))],
            ),
          );
        }
      }
    }
    for (final c in amounts.values) {
      c.dispose();
    }
  }

  /// Popup sous-catégories : liste, montant prévu, renommer, ajouter.
  Future<void> _openSubcategoryPopup({
    required CategoryModel parent,
    required Map<String, TextEditingController> amounts,
    required void Function(void Function()) setParentModal,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final repo = ref.read(repoProvider);
            final subs = repo.getSubcategories(parent.id);
            // Assure un controller pour chaque sous-cat
            for (final s in subs) {
              amounts.putIfAbsent(
                s.id,
                () => TextEditingController(text: '0'),
              );
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(parent.icon, color: parent.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          parent.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text(
                    'Sous-catégories — montant prévu et modification',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(),
                  if (subs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aucune sous-catégorie. Ajoutez-en ci-dessous.'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: subs.length,
                        itemBuilder: (_, i) {
                          final s = subs[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: amounts[s.id],
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) {
                                        setModal(() {});
                                        setParentModal(() {});
                                      },
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: 'Prévu',
                                        suffixText: repo.currency,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                                    tooltip: 'Renommer',
                                    onPressed: () async {
                                      final ctrl = TextEditingController(text: s.name);
                                      final ok = await showDialog<bool>(
                                        context: ctx,
                                        builder: (dCtx) => AlertDialog(
                                          title: const Text('Modifier la sous-catégorie'),
                                          content: TextField(
                                            controller: ctrl,
                                            autofocus: true,
                                            decoration: const InputDecoration(labelText: 'Nom'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dCtx, false),
                                              child: const Text('Annuler'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.pop(dCtx, true),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true && ctrl.text.trim().isNotEmpty) {
                                        s.name = ctrl.text.trim();
                                        await ref.read(repoProvider).updateSubcategory(s);
                                        ref.invalidate(allCategoriesProvider);
                                        ref.invalidate(categoriesProvider);
                                        setModal(() {});
                                        setParentModal(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    title: const Text('Ajouter une sous-catégorie'),
                    onTap: () async {
                      final ctrl = TextEditingController();
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: Text('Nouvelle sous-catégorie — ${parent.name}'),
                          content: TextField(
                            controller: ctrl,
                            autofocus: true,
                            decoration: const InputDecoration(labelText: 'Nom'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Annuler')),
                            FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Créer')),
                          ],
                        ),
                      );
                      if (ok == true && ctrl.text.trim().isNotEmpty) {
                        final sub = SubcategoryModel(
                          id: const Uuid().v4(),
                          name: ctrl.text.trim(),
                          parentId: parent.id,
                          isIncome: false,
                        );
                        await ref.read(repoProvider).addSubcategory(sub);
                        amounts[sub.id] = TextEditingController(text: '0');
                        ref.invalidate(allCategoriesProvider);
                        ref.invalidate(categoriesProvider);
                        setModal(() {});
                        setParentModal(() {});
                      }
                    },
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Valider'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repoProvider);
    final fmt = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prévisions'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _year--)),
          Center(child: Text('$_year', style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _year++)),
        ],
      ),
      body: MoneyBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 12,
          itemBuilder: (_, i) {
            final month = i + 1;
            final income = repo.getTotalIncome(_year, month);
            final expense = repo.getTotalExpense(_year, month);
            final b = repo.budgetFor(_year, month);
            final budget = b?.totalAmount ?? 0.0;
            final isCurrent = _year == DateTime.now().year && month == DateTime.now().month;
            final over = budget > 0 && expense > budget;
            // Somme des prévisions par sous-catégorie (si renseignées)
            double allocSum = 0;
            if (b != null) {
              for (final v in b.allocMap.values) {
                allocSum += v;
              }
            }
            final forecastTotal = allocSum > 0 ? allocSum : budget;
            final pct = forecastTotal > 0 ? (expense / forecastTotal * 100).clamp(0, 999) : 0.0;
            final pctColor = pct > 100
                ? AppColors.expense
                : (pct >= 75 ? const Color(0xFFD97706) : AppColors.income);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: over
                  ? AppColors.expense.withOpacity(0.08)
                  : (isCurrent ? AppColors.primary.withOpacity(0.06) : Colors.white),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _editMonth(month),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _monthNames[month],
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Revenus ${fmt.format(income)} · Dépenses ${fmt.format(expense)}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      // Total prévision + % exécution
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total prévision du mois',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    forecastTotal <= 0
                                        ? '0 (à définir)'
                                        : '${fmt.format(forecastTotal)} ${repo.currency}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Exécution',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  forecastTotal <= 0 ? '—' : '${pct.toStringAsFixed(0)} %',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: forecastTotal <= 0 ? AppColors.textSecondary : pctColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (forecastTotal > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (expense / forecastTotal).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: pctColor,
                          ),
                        ),
                      ],
                      if (over)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            '⚠ Dépenses au-delà de la prévision',
                            style: TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
