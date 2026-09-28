import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/app_repository.dart';
import 'data/models/models.dart';

final repoProvider = Provider<AppRepository>((ref) => throw UnimplementedError());

final balanceProvider = Provider<double>((ref) => ref.watch(repoProvider).getBalance());

final monthTxProvider = Provider<List<TransactionModel>>((ref) {
  final n = DateTime.now();
  return ref.watch(repoProvider).getTransactionsByMonth(n.year, n.month);
});

final allTxProvider = Provider<List<TransactionModel>>((ref) => ref.watch(repoProvider).getAllTransactions());

final monthIncomeProvider = Provider<double>((ref) {
  final n = DateTime.now();
  return ref.watch(repoProvider).getTotalIncome(n.year, n.month);
});

final monthExpenseProvider = Provider<double>((ref) {
  final n = DateTime.now();
  return ref.watch(repoProvider).getTotalExpense(n.year, n.month);
});

final expensesByCatProvider = Provider<Map<String, double>>((ref) {
  final n = DateTime.now();
  return ref.watch(repoProvider).getExpensesByCategory(n.year, n.month);
});

final categoriesProvider = Provider.family<List<CategoryModel>, bool>((ref, incomeOnly) {
  return ref.watch(repoProvider).getCategories(incomeOnly: incomeOnly);
});

final allCategoriesProvider = Provider<List<CategoryModel>>((ref) => ref.watch(repoProvider).getAllCategories());

final selectedYearMonthProvider = StateProvider<(int, int)>((ref) {
  final n = DateTime.now();
  return (n.year, n.month);
});

final budgetForSelectedProvider = Provider<BudgetModel?>((ref) {
  final (y, m) = ref.watch(selectedYearMonthProvider);
  return ref.watch(repoProvider).budgetFor(y, m);
});

final incomeForSelectedProvider = Provider<double>((ref) {
  final (y, m) = ref.watch(selectedYearMonthProvider);
  return ref.watch(repoProvider).getTotalIncome(y, m);
});

final expenseForSelectedProvider = Provider<double>((ref) {
  final (y, m) = ref.watch(selectedYearMonthProvider);
  return ref.watch(repoProvider).getTotalExpense(y, m);
});

final alerts75Provider = Provider<List<String>>((ref) {
  final (y, m) = ref.watch(selectedYearMonthProvider);
  return ref.watch(repoProvider).alerts75(y, m);
});
