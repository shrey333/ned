import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/loan_config.dart';
import '../models/use_of_funds.dart';

class LoanProvider with ChangeNotifier {
  LoanConfig? config;
  bool isLoading = true;
  String? error;

  // Form values
  double annualRevenue = 250000;
  double _loanAmount = 60000;
  bool isMonthly = true;
  int _repaymentDelay = 30;
  List<UseOfFundsEntry> useOfFundsEntries = [];

  // Computed values
  double get maxLoanAmount {
    final configMax = config?.maxAmount ?? 750000;
    final revenueMax = annualRevenue / 3;
    return revenueMax > 0 ? math.min(revenueMax, configMax) : configMax;
  }

  double get minLoanAmount {
    final configMin = config?.minAmount ?? 25000;
    return configMin > maxLoanAmount ? maxLoanAmount : configMin;
  }

  double get loanAmount => _loanAmount.clamp(minLoanAmount, maxLoanAmount);
  set loanAmount(double value) {
    _loanAmount = value.clamp(minLoanAmount, maxLoanAmount);
    notifyListeners();
  }

  double get fees => loanAmount * feePercentage / 100;
  double get totalRevenueShare => loanAmount + fees;

  int get expectedTransfers {
    final multiplier = isMonthly ? 12 : 52;
    final transfers = (totalRevenueShare * multiplier) /
        (annualRevenue * revenuePercentage / 100);
    return transfers.ceil();
  }

  DateTime get expectedCompletionDate {
    final now = DateTime.now();

    if (isMonthly) {
      final totalMonths = now.month + expectedTransfers - 1;

      var completionDate = DateTime(
        now.year,
        now.month + totalMonths,
        now.day,
      );

      // Add repayment delay
      return completionDate.add(Duration(days: repaymentDelay));
    } else {
      // For weekly payments, add weeks
      return now.add(Duration(days: expectedTransfers * 7 + repaymentDelay));
    }
  }

  double get revenuePercentage {
    if (annualRevenue <= 0) return 0;
    const factor1 = 0.156;
    const factor2 = 6.2055;
    return (factor1 / factor2 / annualRevenue) * (loanAmount * 10) * 100;
  }

  int get repaymentDelay => _repaymentDelay;
  set repaymentDelay(int value) {
    if (config?.repaymentDelays.contains('$value days') ?? false) {
      _repaymentDelay = value;
      notifyListeners();
    }
  }

  double get feePercentage => (config?.feePercentage ?? 0) * 100;

  Future<void> fetchConfig() async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(Uri.parse(
          'https://gist.githubusercontent.com/motgi/8fc373cbfccee534c820875ba20ae7b5/raw/7143758ff2caa773e651dc3576de57cc829339c0/config.json'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;
        config = LoanConfig.fromConfigItems(jsonData);
        error = null;
      } else {
        error = 'Failed to load configuration';
      }
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateAnnualRevenue(double value) {
    annualRevenue = value;
    // Adjust loan amount if it exceeds the new maximum
    if (_loanAmount > maxLoanAmount) {
      _loanAmount = maxLoanAmount;
    }
    notifyListeners();
  }

  void updateLoanAmount(double value) {
    if (value >= minLoanAmount && value <= maxLoanAmount) {
      _loanAmount = value;
      notifyListeners();
    }
  }

  void updatePaymentFrequency(bool monthly) {
    isMonthly = monthly;
    notifyListeners();
  }

  void updateRepaymentDelay(int days) {
    repaymentDelay = days;
    notifyListeners();
  }

  // Use of Funds management
  void addUseOfFundsEntry() {
    useOfFundsEntries.add(UseOfFundsEntry(
      type: config?.useOfFundsTypes.firstOrNull ?? '',
      description: '',
      amount: 0,
    ));
    notifyListeners();
  }

  void removeUseOfFundsEntry(int index) {
    if (index >= 0 && index < useOfFundsEntries.length) {
      useOfFundsEntries.removeAt(index);
      notifyListeners();
    }
  }

  void updateUseOfFundsEntry(int index, UseOfFundsEntry entry) {
    if (index >= 0 && index < useOfFundsEntries.length) {
      useOfFundsEntries[index] = entry;
      notifyListeners();
    }
  }
}
