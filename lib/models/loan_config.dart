class ConfigItem {
  final String name;
  final String value;
  final String label;
  final String placeholder;
  final String tooltip;

  ConfigItem({
    required this.name,
    required this.value,
    required this.label,
    required this.placeholder,
    required this.tooltip,
  });

  factory ConfigItem.fromJson(Map<String, dynamic> json) {
    return ConfigItem(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      placeholder: json['placeholder'] ?? '',
      tooltip: json['tooltip'] ?? '',
    );
  }
}

class LoanConfig {
  final double minAmount;
  final double maxAmount;
  final double minRevenuePercentage;
  final double maxRevenuePercentage;
  final List<String> repaymentDelays;
  final List<String> useOfFundsTypes;
  final List<String> revenueFrequencies;
  final double feePercentage;
  final String revenueLabel;
  final String revenuePlaceholder;
  final String fundingLabel;
  final String fundingPlaceholder;

  LoanConfig({
    required this.minAmount,
    required this.maxAmount,
    required this.minRevenuePercentage,
    required this.maxRevenuePercentage,
    required this.repaymentDelays,
    required this.useOfFundsTypes,
    required this.revenueFrequencies,
    required this.feePercentage,
    required this.revenueLabel,
    required this.revenuePlaceholder,
    required this.fundingLabel,
    required this.fundingPlaceholder,
  });

  factory LoanConfig.fromConfigItems(List<dynamic> items) {
    final configMap = {
      for (var item in items.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>)))
        item.name: item
    };

    return LoanConfig(
      minAmount: double.tryParse(configMap['funding_amount_min']?.value ?? '') ?? 25000,
      maxAmount: double.tryParse(configMap['funding_amount_max']?.value ?? '') ?? 750000,
      minRevenuePercentage: double.tryParse(configMap['revenue_percentage_min']?.value ?? '') ?? 4,
      maxRevenuePercentage: double.tryParse(configMap['revenue_percentage_max']?.value ?? '') ?? 8,
      repaymentDelays: (configMap['desired_repayment_delay']?.value ?? '30 days*60 days*90 days')
          .split('*')
          .where((e) => e.isNotEmpty)
          .toList(),
      useOfFundsTypes: (configMap['use_of_funds']?.value ?? '')
          .split('*')
          .where((e) => e.isNotEmpty)
          .toList(),
      revenueFrequencies: (configMap['revenue_shared_frequency']?.value ?? 'monthly*weekly')
          .split('*')
          .where((e) => e.isNotEmpty)
          .map((e) => e[0].toUpperCase() + e.substring(1))
          .toList(),
      feePercentage: double.tryParse(configMap['desired_fee_percentage']?.value ?? '') ?? 0.6,
      revenueLabel: configMap['revenue_amount']?.label ?? 'What is your annual business revenue?',
      revenuePlaceholder: configMap['revenue_amount']?.placeholder ?? '\$250,000',
      fundingLabel: configMap['funding_amount']?.label ?? 'What is your desired loan amount?',
      fundingPlaceholder: configMap['funding_amount']?.placeholder ?? '\$60,000',
    );
  }
}
