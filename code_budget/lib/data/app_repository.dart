import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models/models.dart';

class BudgetRuleException implements Exception {
  final String message;
  BudgetRuleException(this.message);
  @override
  String toString() => message;
}

class InsufficientBalanceException implements Exception {
  final double available;
  final double requested;
  InsufficientBalanceException({required this.available, required this.requested});
  @override
  String toString() =>
      'Solde insuffisant.\nDisponible : ${available.toStringAsFixed(0)}\nDemandé : ${requested.toStringAsFixed(0)}';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AppRepository {
  static const _tx = 'transactions';
  static const _cat = 'categories';
  static const _sub = 'subcategories';
  static const _bud = 'budgets';
  static const _set = 'settings';
  static const _users = 'users';

  Box<TransactionModel> get txBox => Hive.box<TransactionModel>(_tx);
  Box<CategoryModel> get catBox => Hive.box<CategoryModel>(_cat);
  Box<SubcategoryModel> get subBox => Hive.box<SubcategoryModel>(_sub);
  Box<BudgetModel> get budBox => Hive.box<BudgetModel>(_bud);
  Box get setBox => Hive.box(_set);
  Box<UserModel> get userBox => Hive.box<UserModel>(_users);

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(BudgetModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SubcategoryModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(UserModelAdapter());
    await Hive.openBox<TransactionModel>(_tx);
    await Hive.openBox<CategoryModel>(_cat);
    await Hive.openBox<SubcategoryModel>(_sub);
    await Hive.openBox<BudgetModel>(_bud);
    await Hive.openBox(_set);
    await Hive.openBox<UserModel>(_users);
    await _seedCategoriesIfNeeded();
  }

  Future<void> _seedCategoriesIfNeeded() async {
    if (catBox.isNotEmpty) return;
    final uuid = const Uuid();

    Future<void> addParent({
      required String id,
      required String name,
      required String icon,
      required int color,
      required List<String> subs,
      bool income = false,
    }) async {
      final subIds = <String>[];
      for (final s in subs) {
        final sid = uuid.v4();
        subIds.add(sid);
        await subBox.put(sid, SubcategoryModel(id: sid, name: s, parentId: id, isIncome: income));
      }
      await catBox.put(
        id,
        CategoryModel(
          id: id,
          name: name,
          iconName: icon,
          colorValue: color,
          isIncomeCategory: income,
          subcategoryIds: subIds,
        ),
      );
    }

    await addParent(
      id: 'cat_essentiels',
      name: 'Besoins essentiels',
      icon: 'home',
      color: 0xFF2563EB,
      subs: ['Alimentation', 'Logement', 'Transport', 'Santé', 'Éducation', 'Factures'],
    );
    await addParent(
      id: 'cat_loisirs',
      name: 'Loisirs et confort personnel',
      icon: 'spa',
      color: 0xFF7C3AED,
      subs: ['Sorties', 'Streaming', 'Sport', 'Shopping', 'Voyages'],
    );
    await addParent(
      id: 'cat_epargne',
      name: 'Épargne et dettes',
      icon: 'savings',
      color: 0xFF059669,
      subs: ['Épargne', 'Remboursement prêt', 'Crédit', 'Investissement'],
    );
    await addParent(
      id: 'cat_dons',
      name: 'Dons',
      icon: 'volunteer_activism',
      color: 0xFFDC2626,
      subs: ['Charité', 'Famille', 'Église / association'],
    );
    await addParent(
      id: 'cat_revenus',
      name: 'Sources de revenus',
      icon: 'account_balance_wallet',
      color: 0xFF059669,
      income: true,
      subs: ['Salaire', 'Prime', 'Freelance', 'Autre revenu'],
    );
  }

  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  UserModel? get currentUser {
    final id = setBox.get('currentUserId') as String?;
    if (id == null) return null;
    return userBox.get(id);
  }

  bool get isLoggedIn => currentUser != null;

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
    String currency = 'FCFA',
  }) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || !e.contains('@')) throw AuthException('Email invalide');
    if (password.length < 6) throw AuthException('Mot de passe : 6 caractères minimum');
    if (userBox.values.any((u) => u.email == e)) throw AuthException('Cet email est déjà utilisé');
    final user = UserModel(
      email: e,
      passwordHash: _hash(password),
      displayName: displayName.trim().isEmpty ? e.split('@').first : displayName.trim(),
      currency: currency,
    );
    await userBox.put(user.id, user);
    await setBox.put('currentUserId', user.id);
    await setBox.put('currency', currency);
    return user;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final e = email.trim().toLowerCase();
    UserModel? user;
    for (final u in userBox.values) {
      if (u.email == e) {
        user = u;
        break;
      }
    }
    if (user == null) throw AuthException('Compte introuvable');
    if (user.passwordHash != _hash(password)) throw AuthException('Mot de passe incorrect');
    await setBox.put('currentUserId', user.id);
    await setBox.put('currency', user.currency);
    return user;
  }

  Future<void> logout() async {
    await setBox.delete('currentUserId');
  }

  Future<void> updateProfile({String? displayName, String? phone, String? currency}) async {
    final u = currentUser;
    if (u == null) throw AuthException('Non connecté');
    if (displayName != null) u.displayName = displayName;
    if (phone != null) u.phone = phone;
    if (currency != null) {
      u.currency = currency;
      await setBox.put('currency', currency);
    }
    await u.save();
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    final u = currentUser;
    if (u == null) throw AuthException('Non connecté');
    if (u.passwordHash != _hash(oldPassword)) throw AuthException('Ancien mot de passe incorrect');
    if (newPassword.length < 6) throw AuthException('Nouveau mot de passe trop court');
    u.passwordHash = _hash(newPassword);
    await u.save();
  }

  bool get allowOverdraft => setBox.get('allowOverdraft', defaultValue: false) as bool;
  Future<void> setAllowOverdraft(bool v) => setBox.put('allowOverdraft', v);
  String get currency => currentUser?.currency ?? setBox.get('currency', defaultValue: 'FCFA') as String;
  Future<void> setCurrency(String v) async {
    await setBox.put('currency', v);
    final u = currentUser;
    if (u != null) {
      u.currency = v;
      await u.save();
    }
  }

  bool get notif75 => setBox.get('notif75', defaultValue: true) as bool;
  Future<void> setNotif75(bool v) => setBox.put('notif75', v);

  double getTotalIncome(int year, int month) => txBox.values
      .where((t) => t.isIncome && t.date.year == year && t.date.month == month)
      .fold(0.0, (s, t) => s + t.amount);

  double getTotalExpense(int year, int month) => txBox.values
      .where((t) => t.isExpense && t.date.year == year && t.date.month == month)
      .fold(0.0, (s, t) => s + t.amount);


  // ——— Clôture manuelle de mois ———
  String _monthKey(int y, int m) => 'closed_$y-$m';

  /// Un mois n'est clôturé que si l'utilisateur a appuyé sur « Clôturer ».
  bool isMonthClosed(int year, int month) =>
      setBox.get(_monthKey(year, month), defaultValue: false) as bool;

  bool isCurrentMonthClosed() {
    final n = DateTime.now();
    return isMonthClosed(n.year, n.month);
  }

  Future<void> closeMonth(int year, int month) async {
    await setBox.put(_monthKey(year, month), true);
  }

  Future<void> reopenMonth(int year, int month) async {
    await setBox.put(_monthKey(year, month), false);
  }

  void _ensureMonthOpen(int year, int month, {String action = 'modifier'}) {
    if (isMonthClosed(year, month)) {
      throw BudgetRuleException(
        'Le mois $month/$year est clôturé.\n'
        'Impossible de $action les revenus ou dépenses de ce mois.',
      );
    }
  }

  /// Solde du mois = revenus du mois − dépenses du mois (repart de 0 chaque mois)
  double getMonthBalance(int year, int month) =>
      getTotalIncome(year, month) - getTotalExpense(year, month);

  /// Solde affiché : toujours celui du mois en cours (auto à 0 en début de mois)
  double getBalance() {
    final n = DateTime.now();
    return getMonthBalance(n.year, n.month);
  }


  List<TransactionModel> getAllTransactions() {
    final l = txBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  List<TransactionModel> getTransactionsByMonth(int y, int m) {
    final l = txBox.values.where((t) => t.date.year == y && t.date.month == m).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  Map<String, double> getExpensesByCategory(int y, int m) {
    final map = <String, double>{};
    for (final t in txBox.values) {
      if (t.isExpense && t.date.year == y && t.date.month == m) {
        final key = t.subcategoryName ?? t.categoryName;
        map[key] = (map[key] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// null = OK, sinon message d'erreur (dépassement budget mensuel)
  String? wouldExceedBudget(double expenseAmount, {int? year, int? month, String? excludeTxId}) {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final b = budgetFor(y, m);
    if (b == null || b.totalAmount <= 0) return null;
    double current = 0;
    for (final t in txBox.values) {
      if (t.isExpense && t.date.year == y && t.date.month == m) {
        if (excludeTxId != null && t.id == excludeTxId) continue;
        current += t.amount;
      }
    }
    if (current + expenseAmount > b.totalAmount) {
      final remaining = (b.totalAmount - current).clamp(0.0, b.totalAmount);
      return 'Dépense refusée : elle dépasserait le budget du mois.\n'
          'Budget : ${b.totalAmount.toStringAsFixed(0)}\n'
          'Déjà dépensé : ${current.toStringAsFixed(0)}\n'
          'Reste autorisé : ${remaining.toStringAsFixed(0)}';
    }
    return null;
  }

  Future<void> addTransaction(TransactionModel tx) async {
    _ensureMonthOpen(tx.date.year, tx.date.month, action: 'enregistrer');
    if (tx.isExpense) {
      final msg = wouldExceedBudget(tx.amount, year: tx.date.year, month: tx.date.month);
      if (msg != null) throw BudgetRuleException(msg);
      if (!allowOverdraft) {
        final bal = getMonthBalance(tx.date.year, tx.date.month);
        if (tx.amount > bal) {
          throw InsufficientBalanceException(available: bal, requested: tx.amount);
        }
      }
    }
    await txBox.put(tx.id, tx);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    _ensureMonthOpen(tx.date.year, tx.date.month, action: 'modifier');
    if (tx.isExpense) {
      final msg = wouldExceedBudget(
        tx.amount,
        year: tx.date.year,
        month: tx.date.month,
        excludeTxId: tx.id,
      );
      if (msg != null) throw BudgetRuleException(msg);
    }
    await txBox.put(tx.id, tx);
  }

  Future<void> deleteTransaction(String id) async {
    final tx = txBox.get(id);
    if (tx != null) {
      _ensureMonthOpen(tx.date.year, tx.date.month, action: 'supprimer');
    }
    await txBox.delete(id);
  }

  List<CategoryModel> getCategories({bool incomeOnly = false}) =>
      catBox.values.where((c) => c.isIncomeCategory == incomeOnly).toList();
  List<CategoryModel> getAllCategories() => catBox.values.toList();
  List<SubcategoryModel> getSubcategories(String parentId) =>
      subBox.values.where((s) => s.parentId == parentId).toList();
  List<SubcategoryModel> getAllSubcategories({bool? income}) {
    if (income == null) return subBox.values.toList();
    return subBox.values.where((s) => s.isIncome == income).toList();
  }

  Future<void> addCategory(CategoryModel c) async => catBox.put(c.id, c);
  Future<void> updateCategory(CategoryModel c) async => catBox.put(c.id, c);
  Future<void> deleteCategory(String id) async {
    if (txBox.values.any((t) => t.categoryId == id)) {
      throw Exception('Impossible : des transactions utilisent cette catégorie.');
    }
    final cat = catBox.get(id);
    if (cat != null) {
      for (final sid in List<String>.from(cat.subcategoryIds)) {
        await subBox.delete(sid);
      }
    }
    await catBox.delete(id);
  }

  Future<void> addSubcategory(SubcategoryModel s) async {
    await subBox.put(s.id, s);
    final parent = catBox.get(s.parentId);
    if (parent != null && !parent.subcategoryIds.contains(s.id)) {
      parent.subcategoryIds = [...parent.subcategoryIds, s.id];
      await parent.save();
    }
  }

  Future<void> updateSubcategory(SubcategoryModel s) async => subBox.put(s.id, s);

  Future<void> deleteSubcategory(String id) async {
    if (txBox.values.any((t) => t.subcategoryId == id)) {
      throw Exception('Impossible : des transactions utilisent cette sous-catégorie.');
    }
    final s = subBox.get(id);
    if (s != null) {
      final parent = catBox.get(s.parentId);
      if (parent != null) {
        parent.subcategoryIds = parent.subcategoryIds.where((x) => x != id).toList();
        await parent.save();
      }
      await subBox.delete(id);
    }
  }

  BudgetModel? budgetFor(int year, int month) => budBox.get('$year-$month');
  BudgetModel? getCurrentBudget() {
    final n = DateTime.now();
    return budgetFor(n.year, n.month);
  }

  /// Prévisions indépendantes du solde et des revenus.
  /// allocations = montants par sous-catégorie (pas de total forcé par catégorie).
  Future<void> saveMonthlyBudget({
    required int year,
    required int month,
    required double totalAmount,
    required Map<String, double> allocations,
  }) async {
    if (totalAmount < 0) throw BudgetRuleException('Le budget ne peut pas être négatif.');
    await budBox.put(
      '$year-$month',
      BudgetModel(
        id: '$year-$month',
        year: year,
        month: month,
        totalAmount: totalAmount,
        allocations: allocations,
      ),
    );
  }

  Future<void> resetMonthlyBudget(int year, int month) async {
    final key = '$year-$month';
    await budBox.put(
      key,
      BudgetModel(id: key, year: year, month: month, totalAmount: 0, allocations: {}),
    );
  }

  Future<void> resetYearBudgets(int year) async {
    for (var m = 1; m <= 12; m++) {
      await resetMonthlyBudget(year, m);
    }
  }

  List<String> alerts75(int year, int month) {
    if (!notif75) return [];
    final alerts = <String>[];
    final b = budgetFor(year, month);
    if (b == null || b.totalAmount <= 0) return alerts;
    final expense = getTotalExpense(year, month);
    if (expense > b.totalAmount) {
      alerts.add('ALERTE : les dépenses dépassent le budget du mois !');
    } else if (expense / b.totalAmount >= 0.75) {
      alerts.add('Les dépenses atteignent 75 % du budget du mois.');
    }
    return alerts;
  }
}
