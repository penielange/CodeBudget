import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../data/models/models.dart';
import '../providers.dart';
import '../shared/money_background.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expense = ref.watch(allCategoriesProvider).where((c) => !c.isIncomeCategory).toList();
    final income = ref.watch(allCategoriesProvider).where((c) => c.isIncomeCategory).toList();
    final repo = ref.watch(repoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories & sous-catégories')),
      body: MoneyBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Dépenses (catégories parentes)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Besoins essentiels, Loisirs, Épargne, Dons… — personnalisables',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...expense.map((c) => _ParentCard(cat: c, repo: repo)),
            OutlinedButton.icon(
              onPressed: () => _addParent(context, ref, income: false),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une catégorie de dépense'),
            ),
            const SizedBox(height: 28),
            Text('Revenus', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...income.map((c) => _ParentCard(cat: c, repo: repo)),
            OutlinedButton.icon(
              onPressed: () => _addParent(context, ref, income: true),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une source de revenu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addParent(BuildContext context, WidgetRef ref, {required bool income}) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(income ? 'Nouvelle catégorie de revenu' : 'Nouvelle catégorie de dépense'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      final id = const Uuid().v4();
      await ref.read(repoProvider).addCategory(CategoryModel(
            id: id,
            name: ctrl.text.trim(),
            iconName: 'category',
            colorValue: income ? 0xFF059669 : 0xFF2563EB,
            isIncomeCategory: income,
          ));
      ref.invalidate(allCategoriesProvider);
      ref.invalidate(categoriesProvider);
    }
  }
}

class _ParentCard extends ConsumerWidget {
  final CategoryModel cat;
  final dynamic repo;
  const _ParentCard({required this.cat, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(repoProvider).getSubcategories(cat.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(cat.icon, color: cat.color),
        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${subs.length} sous-catégorie(s)'),
        children: [
          ...subs.map((s) => ListTile(
                dense: true,
                title: Text(s.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.expense, size: 20),
                  onPressed: () async {
                    try {
                      await ref.read(repoProvider).deleteSubcategory(s.id);
                      ref.invalidate(allCategoriesProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e'), backgroundColor: AppColors.expense),
                        );
                      }
                    }
                  },
                ),
              )),
          ListTile(
            leading: const Icon(Icons.add, color: AppColors.primary),
            title: const Text('Ajouter une sous-catégorie'),
            onTap: () async {
              final ctrl = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Sous-catégorie — ${cat.name}'),
                  content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nom')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
                  ],
                ),
              );
              if (ok == true && ctrl.text.trim().isNotEmpty) {
                await ref.read(repoProvider).addSubcategory(SubcategoryModel(
                      id: const Uuid().v4(),
                      name: ctrl.text.trim(),
                      parentId: cat.id,
                      isIncome: cat.isIncomeCategory,
                    ));
                ref.invalidate(allCategoriesProvider);
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  final ctrl = TextEditingController(text: cat.name);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Renommer'),
                      content: TextField(controller: ctrl),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
                      ],
                    ),
                  );
                  if (ok == true && ctrl.text.trim().isNotEmpty) {
                    cat.name = ctrl.text.trim();
                    await ref.read(repoProvider).updateCategory(cat);
                    ref.invalidate(allCategoriesProvider);
                  }
                },
                child: const Text('Renommer'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(repoProvider).deleteCategory(cat.id);
                    ref.invalidate(allCategoriesProvider);
                    ref.invalidate(categoriesProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: AppColors.expense),
                      );
                    }
                  }
                },
                child: const Text('Supprimer', style: TextStyle(color: AppColors.expense)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
