import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import './providers/loan_provider.dart';
import './models/use_of_funds.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LoanProvider()..fetchConfig(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ned',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoanApplicationPage(),
    );
  }
}

class LoanApplicationPage extends StatefulWidget {
  const LoanApplicationPage({super.key});

  @override
  State<LoanApplicationPage> createState() => _LoanApplicationPageState();
}

class _LoanApplicationPageState extends State<LoanApplicationPage> {
  late TextEditingController _revenueController;
  late TextEditingController _loanAmountController;
  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  bool _isRevenueEditing = false;
  bool _isLoanAmountEditing = false;

  @override
  void initState() {
    super.initState();
    _revenueController = TextEditingController();
    _loanAmountController = TextEditingController();
    _updateRevenueText(context.read<LoanProvider>());
    _updateLoanAmountText(context.read<LoanProvider>());
  }

  @override
  void dispose() {
    _revenueController.dispose();
    _loanAmountController.dispose();
    super.dispose();
  }

  void _updateRevenueText(LoanProvider provider) {
    if (!_isRevenueEditing) {
      final formatter = NumberFormat('#,##0.00', 'en_US');
      _revenueController.text = provider.annualRevenue > 0
          ? formatter.format(provider.annualRevenue)
          : '';
    }
  }

  void _updateLoanAmountText(LoanProvider provider) {
    if (!_isLoanAmountEditing) {
      final formatter = NumberFormat('#,##0.00', 'en_US');
      _loanAmountController.text =
          provider.loanAmount > 0 ? formatter.format(provider.loanAmount) : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Application'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Consumer<LoanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          _updateRevenueText(provider);
          _updateLoanAmountText(provider);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;

              return SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 48.0 : 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(isWide ? 32.0 : 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Loan Details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Annual Revenue
                                  Text(
                                    provider.config?.revenueLabel ??
                                        'What is your annual business revenue?',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Focus(
                                    onFocusChange: (hasFocus) {
                                      _isRevenueEditing = hasFocus;
                                      if (!hasFocus) {
                                        _updateRevenueText(provider);
                                      }
                                    },
                                    child: TextFormField(
                                      controller: _revenueController,
                                      onChanged: (value) {
                                        final cleanValue = value.replaceAll(
                                            RegExp(r'[^\d.]'), '');
                                        final newValue =
                                            double.tryParse(cleanValue) ??
                                                provider.annualRevenue;
                                        provider.updateAnnualRevenue(newValue);
                                      },
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[\d.]')),
                                        TextInputFormatter.withFunction(
                                            (oldValue, newValue) {
                                          try {
                                            final text = newValue.text;
                                            if (text.isEmpty) return newValue;

                                            // Only allow one decimal point
                                            if (text.contains('.') &&
                                                text.indexOf('.') !=
                                                    text.lastIndexOf('.')) {
                                              return oldValue;
                                            }

                                            // Don't allow more than 2 decimal places
                                            if (text.contains('.')) {
                                              final decimalPlaces =
                                                  text.split('.')[1];
                                              if (decimalPlaces.length > 2)
                                                return oldValue;
                                            }

                                            return newValue;
                                          } catch (e) {
                                            return oldValue;
                                          }
                                        }),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Annual Revenue',
                                        border: const OutlineInputBorder(),
                                        prefixText: '',
                                        hintText: provider
                                                .config?.revenuePlaceholder ??
                                            '0.00',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Loan Amount
                                  const SizedBox(height: 32),
                                  Text(
                                    provider.config?.fundingLabel ??
                                        'What is your desired loan amount?',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              children: [
                                                Slider(
                                                  value: provider.loanAmount,
                                                  min: provider.minLoanAmount,
                                                  max: provider.maxLoanAmount,
                                                  onChanged:
                                                      provider.updateLoanAmount,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        _currencyFormat.format(
                                                            provider
                                                                .minLoanAmount),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                      Text(
                                                        _currencyFormat.format(
                                                            provider
                                                                .maxLoanAmount),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Focus(
                                              onFocusChange: (hasFocus) {
                                                _isLoanAmountEditing = hasFocus;
                                                if (!hasFocus) {
                                                  _updateLoanAmountText(
                                                      provider);
                                                }
                                              },
                                              child: TextField(
                                                controller:
                                                    _loanAmountController,
                                                onChanged: (value) {
                                                  final newValue =
                                                      double.tryParse(
                                                            value.replaceAll(
                                                                RegExp(
                                                                    r'[^\d.]'),
                                                                ''),
                                                          ) ??
                                                          provider.loanAmount;
                                                  provider.updateLoanAmount(
                                                      newValue);
                                                },
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  hintText: provider.config
                                                      ?.fundingPlaceholder,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Revenue Percentage
                                      const SizedBox(height: 32),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Revenue percentage: ${provider.revenuePercentage.toStringAsFixed(2)}%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // Payment Frequency
                                      Text('Revenue Shared Frequency'),
                                      Row(
                                        children: [
                                          ...(provider.config
                                                      ?.revenueFrequencies ??
                                                  ['Monthly', 'Weekly'])
                                              .map((frequency) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 16.0),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Radio<bool>(
                                                          value: frequency
                                                                  .toLowerCase() ==
                                                              'monthly',
                                                          groupValue: provider
                                                              .isMonthly,
                                                          onChanged: (value) =>
                                                              provider
                                                                  .updatePaymentFrequency(
                                                                      value!),
                                                        ),
                                                        Text(frequency),
                                                      ],
                                                    ),
                                                  )),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Repayment Delay
                                      Text('Desired Repayment Delay'),
                                      DropdownButton<int>(
                                        value: provider.repaymentDelay,
                                        isExpanded: true,
                                        items: provider.config?.repaymentDelays
                                                .map((delay) {
                                              final days = int.tryParse(
                                                    delay.replaceAll(
                                                        ' days', ''),
                                                  ) ??
                                                  30;
                                              return DropdownMenuItem(
                                                value: days,
                                                child: Text(delay),
                                              );
                                            }).toList() ??
                                            [
                                              const DropdownMenuItem(
                                                value: 30,
                                                child: Text('30 days'),
                                              ),
                                            ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            provider
                                                .updateRepaymentDelay(value);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      // Use of Funds List
                                      Text('Use of Funds'),
                                      if (provider.useOfFundsEntries.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16.0),
                                          child: Text(
                                            'No use of funds entries added yet',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            provider.useOfFundsEntries.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: _UseOfFundsEntryItem(
                                              entry: provider
                                                  .useOfFundsEntries[index],
                                              onDelete: () => provider
                                                  .removeUseOfFundsEntry(index),
                                              onUpdate: (entry) => provider
                                                  .updateUseOfFundsEntry(
                                                      index, entry),
                                              useOfFundsTypes: provider.config
                                                      ?.useOfFundsTypes ??
                                                  [],
                                              currencyFormat: _currencyFormat,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            provider.addUseOfFundsEntry(),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Use of Funds'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isWide) const SizedBox(width: 32),
                        if (!isWide) const SizedBox(height: 24),
                        Expanded(
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(isWide ? 32.0 : 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Results',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  const SizedBox(height: 32),
                                  _buildResultRow(
                                    'Annual Business Revenue',
                                    _currencyFormat
                                        .format(provider.annualRevenue),
                                  ),
                                  const Divider(height: 32),
                                  _buildResultRow(
                                    'Funding Amount',
                                    _currencyFormat.format(provider.loanAmount),
                                  ),
                                  const Divider(height: 32),
                                  _buildResultRow(
                                    'Fees',
                                    '(50%) ${_currencyFormat.format(provider.fees)}',
                                  ),
                                  const Divider(height: 32),
                                  _buildResultRow(
                                    'Total Revenue Share',
                                    _currencyFormat
                                        .format(provider.totalRevenueShare),
                                  ),
                                  const Divider(height: 32),
                                  _buildResultRow(
                                    'Expected transfers',
                                    provider.expectedTransfers.toString(),
                                  ),
                                  const Divider(height: 32),
                                  _buildResultRow(
                                    'Expected completion date',
                                    DateFormat('MMMM d, y').format(
                                        provider.expectedCompletionDate),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _UseOfFundsEntryForm extends StatefulWidget {
  final List<String> categories;
  final Function(UseOfFundsEntry) onAdd;

  const _UseOfFundsEntryForm({
    required this.categories,
    required this.onAdd,
  });

  @override
  State<_UseOfFundsEntryForm> createState() => _UseOfFundsEntryFormState();
}

class _UseOfFundsEntryFormState extends State<_UseOfFundsEntryForm> {
  late String selectedType;
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedType = widget.categories.first;
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final amount = double.tryParse(
          amountController.text.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ??
        0;

    if (amount > 0 && descriptionController.text.isNotEmpty) {
      widget.onAdd(
        UseOfFundsEntry(
          type: selectedType,
          description: descriptionController.text,
          amount: amount,
        ),
      );

      // Clear form
      descriptionController.clear();
      amountController.clear();
      setState(() {
        selectedType = widget.categories.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          items: widget.categories
              .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedType = value;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            hintText: 'Description',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  prefixText: '\$',
                  hintText: 'Amount',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}

class _UseOfFundsEntryItem extends StatelessWidget {
  final UseOfFundsEntry entry;
  final VoidCallback onDelete;
  final Function(UseOfFundsEntry) onUpdate;
  final List<String> useOfFundsTypes;
  final NumberFormat currencyFormat;

  const _UseOfFundsEntryItem({
    required this.entry,
    required this.onDelete,
    required this.onUpdate,
    required this.useOfFundsTypes,
    required this.currencyFormat,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return amount > 0 ? formatter.format(amount) : '';
  }

  @override
  Widget build(BuildContext context) {
    final types = useOfFundsTypes.isEmpty ? ['Other'] : useOfFundsTypes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value:
                        types.contains(entry.type) ? entry.type : types.first,
                    items: types
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onUpdate(entry.copyWith(type: value));
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                  tooltip: 'Remove entry',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: entry.description,
              onChanged: (value) =>
                  onUpdate(entry.copyWith(description: value)),
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _formatAmount(entry.amount),
              onChanged: (value) {
                final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
                final newAmount = double.tryParse(cleanValue) ?? 0;
                onUpdate(entry.copyWith(amount: newAmount));
              },
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  try {
                    final text = newValue.text;
                    if (text.isEmpty) return newValue;

                    // Only allow one decimal point
                    if (text.contains('.') &&
                        text.indexOf('.') != text.lastIndexOf('.')) {
                      return oldValue;
                    }

                    // Don't allow more than 2 decimal places
                    if (text.contains('.')) {
                      final decimalPlaces = text.split('.')[1];
                      if (decimalPlaces.length > 2) return oldValue;
                    }

                    return newValue;
                  } catch (e) {
                    return oldValue;
                  }
                }),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '\$',
                hintText: '0.00',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
