import 'package:intl/intl.dart';

enum TransactionType { credit, debit }

enum TransactionCategory {
  food,
  travel,
  shopping,
  bills,
  medical,
  others;

  String get label {
    switch (this) {
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.travel:
        return 'Travel';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.bills:
        return 'Bills';
      case TransactionCategory.medical:
        return 'Medical';
      case TransactionCategory.others:
        return 'Others';
    }
  }

  String get iconName {
    switch (this) {
      case TransactionCategory.food:
        return 'restaurant';
      case TransactionCategory.travel:
        return 'directions_car';
      case TransactionCategory.shopping:
        return 'shopping_cart';
      case TransactionCategory.bills:
        return 'receipt_long';
      case TransactionCategory.medical:
        return 'local_hospital';
      case TransactionCategory.others:
        return 'more_horiz';
    }
  }
}

class Transaction {
  final int? id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? note;
  final String? smsSource;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.smsSource,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'note': note,
      'smsSource': smsSource,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.byName(map['type'] as String),
      category: TransactionCategory.values.byName(map['category'] as String),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      smsSource: map['smsSource'] as String?,
      userId: map['userId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? note,
    String? smsSource,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      smsSource: smsSource ?? this.smsSource,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 0);
    return formatter.format(amount);
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(date);
  }
}


