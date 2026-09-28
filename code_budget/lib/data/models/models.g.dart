part of 'models.dart';

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return TransactionModel(
      id: f[0] as String?,
      amount: (f[1] as num).toDouble(),
      type: f[2] as String,
      categoryId: f[3] as String,
      categoryName: f[4] as String,
      date: f[5] as DateTime,
      note: f[6] as String?,
      paymentMethod: f[7] as String?,
      createdAt: f[8] as DateTime?,
      subcategoryId: f[9] as String?,
      subcategoryName: f[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.amount)
      ..writeByte(2)..write(obj.type)
      ..writeByte(3)..write(obj.categoryId)
      ..writeByte(4)..write(obj.categoryName)
      ..writeByte(5)..write(obj.date)
      ..writeByte(6)..write(obj.note)
      ..writeByte(7)..write(obj.paymentMethod)
      ..writeByte(8)..write(obj.createdAt)
      ..writeByte(9)..write(obj.subcategoryId)
      ..writeByte(10)..write(obj.subcategoryName);
  }
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 1;

  @override
  CategoryModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    final ids = f[5];
    List<String> subIds = [];
    if (ids is List) subIds = ids.map((e) => e.toString()).toList();
    return CategoryModel(
      id: f[0] as String,
      name: f[1] as String,
      iconName: f[2] as String,
      colorValue: f[3] as int,
      isIncomeCategory: f[4] as bool? ?? false,
      subcategoryIds: subIds,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.iconName)
      ..writeByte(3)..write(obj.colorValue)
      ..writeByte(4)..write(obj.isIncomeCategory)
      ..writeByte(5)..write(obj.subcategoryIds);
  }
}

class SubcategoryModelAdapter extends TypeAdapter<SubcategoryModel> {
  @override
  final int typeId = 3;

  @override
  SubcategoryModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return SubcategoryModel(
      id: f[0] as String,
      name: f[1] as String,
      parentId: f[2] as String,
      isIncome: f[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SubcategoryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.parentId)
      ..writeByte(3)..write(obj.isIncome);
  }
}

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 2;

  @override
  BudgetModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return BudgetModel(
      id: f[0] as String,
      year: f[1] as int,
      month: f[2] as int,
      totalAmount: (f[3] as num).toDouble(),
      allocations: (f[4] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      updatedAt: f[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.year)
      ..writeByte(2)..write(obj.month)
      ..writeByte(3)..write(obj.totalAmount)
      ..writeByte(4)..write(obj.allocations)
      ..writeByte(5)..write(obj.updatedAt);
  }
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 4;

  @override
  UserModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return UserModel(
      id: f[0] as String?,
      email: f[1] as String,
      passwordHash: f[2] as String,
      displayName: f[3] as String,
      phone: f[4] as String?,
      currency: f[5] as String? ?? 'FCFA',
      createdAt: f[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.email)
      ..writeByte(2)..write(obj.passwordHash)
      ..writeByte(3)..write(obj.displayName)
      ..writeByte(4)..write(obj.phone)
      ..writeByte(5)..write(obj.currency)
      ..writeByte(6)..write(obj.createdAt);
  }
}
