import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currency/currency.dart';
import '../../core/formatting/money_format.dart';
import '../../features/expenses/logic/split_calculator.dart';
import '../../features/expenses/models/split_mode.dart';
import '../../features/groups/models/member.dart';
import '../../state/app_controller.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _custom = <String, TextEditingController>{};
  final _selected = <String>{};

  late String _currency;
  late String _payerId;
  late List<Member> _members;
  SplitMode _mode = SplitMode.equal;
  String? _error;

  @override
  void initState() {
    super.initState();
    final group = ref.read(appControllerProvider).groupById(widget.groupId);
    _members = group?.members ?? const [];
    _currency = group?.baseCurrency ?? 'NGN';
    _payerId = _members.isEmpty ? '' : _members.first.id;
    for (final member in _members) {
      _custom[member.id] = TextEditingController();
      _selected.add(member.id);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    for (final controller in _custom.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _participants => [
        for (final member in _members)
          if (_selected.contains(member.id)) member.id,
      ];

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(appControllerProvider).groupById(widget.groupId);
    if (group == null || _members.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add expense')),
        body: const Center(child: Text('This group is no longer available.')),
      );
    }

    final rates = ref.watch(exchangeRateServiceProvider);
    final amount = parseMoneyInput(_amount.text);
    final symbol = Currencies.symbolFor(_currency);

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'What was it?'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '$symbol ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: [
              for (final currency in Currencies.supported)
                DropdownMenuItem(
                  value: currency.code,
                  child: Text('${currency.code} · ${currency.name}'),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _currency = value);
            },
          ),
          if (_currency != group.baseCurrency) ...[
            const SizedBox(height: 8),
            Text(
              'Offline demo rate: 1 $_currency = '
              '${_formatRate(rates.rate(base: _currency, quote: group.baseCurrency))} '
              '${group.baseCurrency}',
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            if (amount != null)
              Text(
                'About ${formatMinor(rates.convertMinor(amountMinor: amount, from: _currency, to: group.baseCurrency), group.baseCurrency)} '
                'in ${group.baseCurrency}.',
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _payerId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Paid by'),
            items: [
              for (final member in _members)
                DropdownMenuItem(value: member.id, child: Text(member.name)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _payerId = value);
            },
          ),
          const SizedBox(height: 16),
          SegmentedButton<SplitMode>(
            segments: const [
              ButtonSegment(value: SplitMode.equal, label: Text('Equal')),
              ButtonSegment(value: SplitMode.custom, label: Text('Custom')),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() {
                _mode = selection.first;
                if (_mode == SplitMode.custom) _seedCustomShares();
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('Include', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final member in _members)
                FilterChip(
                  label: Text(member.name),
                  selected: _selected.contains(member.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selected.add(member.id);
                      } else {
                        _selected.remove(member.id);
                      }
                    });
                  },
                ),
            ],
          ),
          if (_mode == SplitMode.custom) ...[
            const SizedBox(height: 16),
            const Text(
              'Custom shares use the expense currency and must add up to the total.',
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 8),
            for (final member in _members)
              if (_selected.contains(member.id)) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _custom[member.id],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: member.name,
                    prefixText: '$symbol ',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            const SizedBox(height: 8),
            Text(
              _shareSummary(),
              style: TextStyle(
                color: _sharesMatch() ? AppColors.receive : AppColors.owe,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.owe)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _save(group.baseCurrency),
            child: const Text('Save expense'),
          ),
        ],
      ),
    );
  }

  void _seedCustomShares() {
    final amount = parseMoneyInput(_amount.text);
    final participants = _participants;
    if (amount == null || participants.isEmpty) return;
    final base = amount ~/ participants.length;
    final remainder = amount % participants.length;
    for (var i = 0; i < participants.length; i++) {
      final share = base + (i < remainder ? 1 : 0);
      _custom[participants[i]]!.text = _editable(share);
    }
  }

  String _shareSummary() {
    final amount = parseMoneyInput(_amount.text);
    final sum = _customSum();
    if (amount == null || sum == null) {
      return 'Enter the total and a share for each selected person.';
    }
    return 'Shares ${formatMinor(sum, _currency)} of '
        '${formatMinor(amount, _currency)}';
  }

  bool _sharesMatch() {
    final amount = parseMoneyInput(_amount.text);
    final sum = _customSum();
    return amount != null && sum == amount;
  }

  int? _customSum() {
    var sum = 0;
    for (final id in _participants) {
      final parsed = parseMoneyInput(
        _custom[id]?.text ?? '',
        allowZero: true,
      );
      if (parsed == null) return null;
      sum += parsed;
    }
    return sum;
  }

  void _save(String baseCurrency) {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give the expense a name.');
      return;
    }
    final amount = parseMoneyInput(_amount.text);
    if (amount == null) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    final participants = _participants;
    final custom = <String, int>{};
    if (_mode == SplitMode.custom) {
      for (final id in participants) {
        final parsed = parseMoneyInput(
          _custom[id]?.text ?? '',
          allowZero: true,
        );
        if (parsed == null) {
          setState(
            () => _error = 'Enter a share for each selected person.',
          );
          return;
        }
        custom[id] = parsed;
      }
    }

    final rates = ref.read(exchangeRateServiceProvider);
    final validation = SplitCalculator(rates).validate(
      amountMinor: amount,
      mode: _mode,
      participantIds: participants,
      customSharesMinor: custom,
    );
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    try {
      ref.read(appControllerProvider.notifier).addExpense(
            groupId: widget.groupId,
            title: title,
            amountMinor: amount,
            currencyCode: _currency,
            paidByMemberId: _payerId,
            mode: _mode,
            participantIds: participants,
            customSharesMinor: custom,
            note: _note.text,
          );
    } on SplitException catch (error) {
      setState(() => _error = error.message);
      return;
    } on ArgumentError {
      setState(() => _error = 'Could not add that expense.');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Expense added')));
  }

  String _editable(int minor) {
    final major = minor ~/ 100;
    final fraction = minor % 100;
    if (fraction == 0) return '$major';
    return '$major.${fraction.toString().padLeft(2, '0')}';
  }

  String _formatRate(double value) {
    var text = value.toStringAsFixed(4);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}
