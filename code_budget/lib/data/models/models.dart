import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late double amount;
  @HiveField(2)
  late String type;
  @HiveField(3)
  late String categoryId;
  @HiveField(4)
  late String categoryName;
  @HiveField(5)
  late DateTime date;
  @HiveField(6)
  String? note;
  @HiveField(7)
  String? paymentMethod;
  @HiveField(8)
  late DateTime createdAt;
  @HiveField(9)
  String? subcategoryId;
  @HiveField(10)
  String? subcategoryName;

  TransactionModel({
    String? id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.note,
    this.paymentMethod,
    DateTime? createdAt,
    this.subcategoryId,
    this.subcategoryName,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
}

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late String iconName;
  @HiveField(3)
  late int colorValue;
  @HiveField(4)
  late bool isIncomeCategory;
  @HiveField(5)
  late List<String> subcategoryIds;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.isIncomeCategory = false,
    List<String>? subcategoryIds,
  }) {
    this.subcategoryIds = subcategoryIds ?? [];
  }

  IconData get icon {
    const map = {
      'restaurant': Icons.restaurant_rounded,
      'home': Icons.home_rounded,
      'savings': Icons.savings_rounded,
      'category': Icons.category_rounded,
      'favorite': Icons.favorite_rounded,
      'volunteer_activism': Icons.volunteer_activism_rounded,
      'spa': Icons.spa_rounded,
      'account_balance': Icons.account_balance_rounded,
      'account_balance_wallet': Icons.account_balance_wallet_rounded,
      'attach_money': Icons.attach_money_rounded,
      'card_giftcard': Icons.card_giftcard_rounded,
      'sports_esports': Icons.sports_esports_rounded,
    };
    return map[iconName] ?? Icons.category_rounded;
  }

  Color get color => Color(colorValue);
}

@HiveType(typeId: 3)
class SubcategoryModel extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late String parentId;
  @HiveField(3)
  late bool isIncome;

  SubcategoryModel({
    required this.id,
    required this.name,
    required this.parentId,
    this.isIncome = false,
  });
}

@HiveType(typeId: 2)
class BudgetModel extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late int year;
  @HiveField(2)
  late int month;
  @HiveField(3)
  late double totalAmount;
  @HiveField(4)
  late Map<dynamic, dynamic> allocations;
  @HiveField(5)
  late DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.year,
    required this.month,
    required this.totalAmount,
    Map<dynamic, dynamic>? allocations,
    DateTime? updatedAt,
  }) {
    this.allocations = allocations ?? {};
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  Map<String, double> get allocMap =>
      allocations.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
}

@HiveType(typeId: 4)
class UserModel extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String email;
  @HiveField(2)
  late String passwordHash;
  @HiveField(3)
  late String displayName;
  @HiveField(4)
  String? phone;
  @HiveField(5)
  late String currency;
  @HiveField(6)
  late DateTime createdAt;

  UserModel({
    String? id,
    required this.email,
    required this.passwordHash,
    required this.displayName,
    this.phone,
    this.currency = 'FCFA',
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }
}
