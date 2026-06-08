class Budget {
  final int? id;
  final double monthlyLimit;
  final double currentSpending;
  final int month;
  final int year;
  final String userId;
  final bool notifyOnLimit;

  Budget({
    this.id,
    required this.monthlyLimit,
    this.currentSpending = 0.0,
    required this.month,
    required this.year,
    required this.userId,
    this.notifyOnLimit = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'monthlyLimit': monthlyLimit,
      'currentSpending': currentSpending,
      'month': month,
      'year': year,
      'userId': userId,
      'notifyOnLimit': notifyOnLimit ? 1 : 0,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      currentSpending: (map['currentSpending'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      userId: map['userId'] as String,
      notifyOnLimit: (map['notifyOnLimit'] as int) == 1,
    );
  }

  Budget copyWith({
    int? id,
    double? monthlyLimit,
    double? currentSpending,
    int? month,
    int? year,
    String? userId,
    bool? notifyOnLimit,
  }) {
    return Budget(
      id: id ?? this.id,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentSpending: currentSpending ?? this.currentSpending,
      month: month ?? this.month,
      year: year ?? this.year,
      userId: userId ?? this.userId,
      notifyOnLimit: notifyOnLimit ?? this.notifyOnLimit,
    );
  }

  double get remaining => monthlyLimit - currentSpending;
  double get percentageUsed => (currentSpending / monthlyLimit) * 100;
  bool get isLimitReached => currentSpending >= monthlyLimit;
  bool get isWarningZone => percentageUsed >= 80 && !isLimitReached;
}
