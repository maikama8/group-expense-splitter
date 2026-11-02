import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_splitter/core/currency/mock_exchange_rate_service.dart';
import 'package:group_expense_splitter/features/expenses/logic/balance_calculator.dart';
import 'package:group_expense_splitter/features/expenses/logic/settlement_planner.dart';
import 'package:group_expense_splitter/features/expenses/logic/split_calculator.dart';
import 'package:group_expense_splitter/features/expenses/models/expense.dart';
import 'package:group_expense_splitter/features/expenses/models/settlement.dart';
import 'package:group_expense_splitter/features/expenses/models/split_mode.dart';

void main() {
  const calculator = SplitCalculator(MockExchangeRateService());
  const balances = BalanceCalculator();
  const planner = SettlementPlanner();

  Expense expense({
    required String id,
    required String payer,
    required int amountMinor,
    required String currency,
    required List<String> participants,
    SplitMode mode = SplitMode.equal,
    Map<String, int> custom = const {},
  }) {
    final split = calculator.compute(
      amountMinor: amountMinor,
      currencyCode: currency,
      baseCurrency: 'NGN',
      mode: mode,
      participantIds: participants,
      customSharesMinor: custom,
    );
    return Expense(
      id: id,
      groupId: 'g',
      title: id,
      paidByMemberId: payer,
      amountMinor: amountMinor,
      currencyCode: currency,
      baseAmountMinor: split.baseAmountMinor,
      baseCurrency: 'NGN',
      splitMode: mode,
      sharesOriginalMinor: split.sharesOriginalMinor,
      sharesBaseMinor: split.sharesBaseMinor,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Map<String, int> net(List<Expense> expenses,
      [List<Settlement> payments = const []]) {
    return balances.netBalances(
      memberIds: const ['ada', 'bola', 'chi'],
      expenses: expenses,
      settlements: payments,
    );
  }

  test('the payer is credited and everyone in the split is debited', () {
    final result = net([
      expense(
        id: 'dinner',
        payer: 'ada',
        amountMinor: 300,
        currency: 'NGN',
        participants: const ['ada', 'bola', 'chi'],
      ),
    ]);
    expect(result, {'ada': 200, 'bola': -100, 'chi': -100});
    expect(result.values.fold<int>(0, (sum, value) => sum + value), 0);
  });

  test('someone can pay without being part of the split', () {
    final result = net([
      expense(
        id: 'gift',
        payer: 'ada',
        amountMinor: 200,
        currency: 'NGN',
        participants: const ['bola', 'chi'],
      ),
    ]);
    expect(result, {'ada': 200, 'bola': -100, 'chi': -100});
  });

  test('a dollar expense is converted into the naira book', () {
    final result = balances.netBalances(
      memberIds: const ['ada', 'bola'],
      expenses: [
        expense(
          id: 'usd',
          payer: 'bola',
          amountMinor: 100,
          currency: 'USD',
          participants: const ['ada', 'bola'],
        ),
      ],
      settlements: const [],
    );
    // $1.00 == ₦1,600.00, split in half.
    expect(result, {'ada': -80000, 'bola': 80000});
  });

  test('a recorded settlement moves the balance toward zero', () {
    final open = net([
      expense(
        id: 'dinner',
        payer: 'ada',
        amountMinor: 300,
        currency: 'NGN',
        participants: const ['ada', 'bola', 'chi'],
      ),
    ]);
    final closed = net(
      [
        expense(
          id: 'dinner',
          payer: 'ada',
          amountMinor: 300,
          currency: 'NGN',
          participants: const ['ada', 'bola', 'chi'],
        ),
      ],
      [
        Settlement(
          id: 's1',
          groupId: 'g',
          fromMemberId: 'bola',
          toMemberId: 'ada',
          amountMinor: 100,
          currencyCode: 'NGN',
          createdAt: DateTime(2026, 1, 2),
        ),
      ],
    );
    expect(open['bola'], -100);
    expect(closed, {'ada': 100, 'bola': 0, 'chi': -100});
  });

  test('settle-up clears a simple three person book in two payments', () {
    final result = net([
      expense(
        id: 'dinner',
        payer: 'ada',
        amountMinor: 300,
        currency: 'NGN',
        participants: const ['ada', 'bola', 'chi'],
      ),
    ]);
    final transfers = planner.plan(balances: result, currencyCode: 'NGN');
    expect(transfers, hasLength(2));
    expect(
      [for (final transfer in transfers) transfer.fromMemberId],
      ['bola', 'chi'],
    );
    expect(
      [for (final transfer in transfers) transfer.toMemberId],
      ['ada', 'ada'],
    );
    expect(
      [for (final transfer in transfers) transfer.amountMinor],
      [100, 100],
    );
    expect(_apply(result, transfers).values, everyElement(0));
  });

  test('settle-up matches largest debts first and breaks ties by id', () {
    final transfers = planner.plan(
      balances: const {'a': 50, 'b': 50, 'c': -30, 'd': -70},
      currencyCode: 'NGN',
    );
    expect(
      [
        for (final transfer in transfers)
          '${transfer.fromMemberId}->${transfer.toMemberId}:${transfer.amountMinor}',
      ],
      ['d->a:50', 'd->b:20', 'c->b:30'],
    );
    expect(
      _apply(const {'a': 50, 'b': 50, 'c': -30, 'd': -70}, transfers).values,
      everyElement(0),
    );
  });

  test('an already settled book suggests no payments', () {
    expect(
      planner.plan(
        balances: const {'a': 0, 'b': 0},
        currencyCode: 'NGN',
      ),
      isEmpty,
    );
  });

  test('settlement rejects a payment to yourself', () {
    expect(
      () => Settlement(
        id: 's',
        groupId: 'g',
        fromMemberId: 'ada',
        toMemberId: 'ada',
        amountMinor: 10,
        currencyCode: 'NGN',
        createdAt: DateTime(2026, 1, 1),
      ),
      throwsArgumentError,
    );
  });
}

Map<String, int> _apply(Map<String, int> balances, List<Transfer> transfers) {
  final next = Map<String, int>.from(balances);
  for (final transfer in transfers) {
    next[transfer.fromMemberId] =
        (next[transfer.fromMemberId] ?? 0) + transfer.amountMinor;
    next[transfer.toMemberId] =
        (next[transfer.toMemberId] ?? 0) - transfer.amountMinor;
  }
  return next;
}
