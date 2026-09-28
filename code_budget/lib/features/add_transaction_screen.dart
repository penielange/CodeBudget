import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../data/app_repository.dart';
import '../data/models/models.dart';
import '../providers.dart';
import '../shared/money_background.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'income';
  CategoryModel? _parent;
  SubcategoryModel? _sub;
  DateTime _date = DateTime.now();
  bool _loading = false;
  bool _resolvedExisting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _noteCtrl.text = e.note ?? '';
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<CategoryModel> _parents(WidgetRef ref) =>
      ref.read(repoProvider).getCategories(incomeOnly: _type == 'income');

  List<SubcategoryModel> _subs(WidgetRef ref) {
    if (_parent == null) return [];
    return ref.read(repoProvider).getSubcategories(_parent!.id);
  }

  void _resolveExisting(WidgetRef ref) {
    if (_resolvedExisting || !_isEdit) return;
    final e = widget.existing!;
    final parents = _parents(ref);
    for (final c in parents) {
      if (c.id == e.categoryId) {
        _parent = c;
        break;
      }
    }
    if (_parent != null) {
      for (final s in ref.read(repoProvider).getSubcategories(_parent!.id)) {
        if (s.id == e.subcategoryId) {
          _sub = s;
          break;
        }
      }
    }
    _resolvedExisting = true;
  }

  Future<void> _openCategoryPicker() async {
    final parents = _parents(ref);
    if (parents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == 'income'
              ? 'Aucune source de revenu. Ajoutez-en dans Catégories.'
              : 'Aucune catégorie de dépense. Ajoutez-en dans Catégories.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _type == 'income' ? 'Sources de revenus' : 'Catégories de dépenses',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: parents.length,
                  itemBuilder: (_, i) {
                    final c = parents[i];
                    final selected = _parent?.id == c.id;
                    return ListTile(
                      leading: Icon(c.icon, color: c.color),
                      title: Text(c.name, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _parent = selected;
        _sub = null;
      });
      // Ouvre directement le popup sous-catégories
      await _openSubcategoryPopup();
    }
  }

  Future<void> _openSubcategoryPopup() async {
    if (_parent == null) {
      await _openCategoryPicker();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final subs = ref.read(repoProvider).getSubcategories(_parent!.id);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        children: [
                          Icon(_parent!.icon, color: _parent!.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_parent!.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                Text(
                                  _type == 'income' ? 'Sous-catégories / types de revenu' : 'Sous-catégories',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (subs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Aucune sous-catégorie. Ajoutez-en ci-dessous.'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: subs.length,
                          itemBuilder: (_, i) {
                            final s = subs[i];
                            final selected = _sub?.id == s.id;
                            return ListTile(
                              title: Text(s.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected) const Icon(Icons.check, color: AppColors.primary, size: 20),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                                    tooltip: 'Modifier',
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
                                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Annuler')),
                                            FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('OK')),
                                          ],
                                        ),
                                      );
                                      if (ok == true && ctrl.text.trim().isNotEmpty) {
                                        s.name = ctrl.text.trim();
                                        await ref.read(repoProvider).updateSubcategory(s);
                                        ref.invalidate(allCategoriesProvider);
                                        ref.invalidate(categoriesProvider);
                                        setModal(() {});
                                        if (_sub?.id == s.id) {
                                          setState(() => _sub = s);
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() => _sub = s);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      title: Text(_type == 'income' ? 'Ajouter un type de revenu' : 'Ajouter une sous-catégorie'),
                      onTap: () async {
                        final ctrl = TextEditingController();
                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (dCtx) => AlertDialog(
                            title: Text(_type == 'income' ? 'Nouveau type de revenu' : 'Nouvelle sous-catégorie'),
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
                            parentId: _parent!.id,
                            isIncome: _type == 'income',
                          );
                          await ref.read(repoProvider).addSubcategory(sub);
                          ref.invalidate(allCategoriesProvider);
                          ref.invalidate(categoriesProvider);
                          setState(() => _sub = sub);
                          setModal(() {});
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text('Aucune sous-catégorie'),
                      onTap: () {
                        setState(() => _sub = null);
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_parent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une catégorie / source de revenu'), backgroundColor: AppColors.expense),
      );
      return;
    }
    setState(() => _loading = true);
    final amount = double.parse(_amountCtrl.text.replaceAll(' ', '').replaceAll(',', '.'));
    final tx = TransactionModel(
      id: widget.existing?.id,
      amount: amount,
      type: _type,
      categoryId: _parent!.id,
      categoryName: _parent!.name,
      subcategoryId: _sub?.id,
      subcategoryName: _sub?.name,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: widget.existing?.createdAt,
    );
    try {
      if (_isEdit) {
        await ref.read(repoProvider).updateTransaction(tx);
      } else {
        await ref.read(repoProvider).addTransaction(tx);
      }
      ref.invalidate(balanceProvider);
      ref.invalidate(monthTxProvider);
      ref.invalidate(allTxProvider);
      ref.invalidate(monthIncomeProvider);
      ref.invalidate(monthExpenseProvider);
      ref.invalidate(expensesByCatProvider);
      ref.invalidate(alerts75Provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Transaction modifiée' : 'Transaction enregistrée'),
            backgroundColor: AppColors.income,
          ),
        );
        context.pop();
      }
    } on BudgetRuleException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFFFFF1F2),
            title: const Text('Alerte budget', style: TextStyle(color: AppColors.expense)),
            content: Text(e.message, style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: AppColors.expense))),
            ],
          ),
        );
      }
    } on InsufficientBalanceException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Solde insuffisant', style: TextStyle(color: AppColors.expense)),
            content: Text(e.toString(), style: const TextStyle(color: AppColors.expense)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _resolveExisting(ref);
    final currency = ref.watch(repoProvider).currency;

    return MoneyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_isEdit
              ? 'Modifier la transaction'
              : (_type == 'expense' ? 'Nouvelle dépense' : 'Nouveau revenu')),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'income', label: Text('Revenu'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment(value: 'expense', label: Text('Dépense'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _parent = null;
                  _sub = null;
                  _resolvedExisting = true;
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Montant', suffixText: currency),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Menu déroulant / sélecteur catégorie (dépenses OU revenus)
              InkWell(
                onTap: _openCategoryPicker,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: _type == 'income' ? 'Source de revenu *' : 'Catégorie *',
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _parent?.name ??
                        (_type == 'income' ? 'Choisir une source de revenu' : 'Choisir une catégorie'),
                    style: TextStyle(
                      color: _parent == null ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: _parent == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Popup sous-catégories
              InkWell(
                onTap: _openSubcategoryPopup,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: _type == 'income' ? 'Type de revenu (sous-catégorie)' : 'Sous-catégorie',
                    suffixIcon: const Icon(Icons.list_alt_rounded),
                    helperText: 'Toucher pour ouvrir la liste et modifier',
                  ),
                  child: Text(
                    _sub?.name ?? 'Choisir / gérer les sous-catégories',
                    style: TextStyle(
                      color: _sub == null ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: _sub == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optionnel)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Enregistrer les modifications' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
