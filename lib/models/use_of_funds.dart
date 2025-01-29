class UseOfFundsEntry {
  final String type;
  final String description;
  final double amount;

  UseOfFundsEntry({
    required this.type,
    required this.description,
    required this.amount,
  });

  UseOfFundsEntry copyWith({
    String? type,
    String? description,
    double? amount,
  }) {
    return UseOfFundsEntry(
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
    );
  }
}
