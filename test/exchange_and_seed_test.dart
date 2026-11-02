import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_splitter/core/currency/mock_exchange_rate_service.dart';
import 'package:group_expense_splitter/core/formatting/money_format.dart';
import 'package:group_expense_splitter/data/seed_data.dart';
import 'package:group_expense_splitter/features/ajo/logic/ajo_rotation.dart';
import 'package:group_expense_splitter/features/expenses/logic/group_ledger.dart';

void main() {
  const rates = MockExchangeRateService();

  test('demo rates convert through naira without rounding on these fixtures',
      () {
    expect(
      rates.convertMinor(amountMinor: 100, from: 'USD', to: 'NGN'),
      160000,
    );
    expect(
      rates.convertMinor(amountMinor: 100, from: 'USD', to: 'GBP'),
      80,
    );
    expect(
      rates.convertMinor(amountMinor: 2400, from: 'EUR', to: 'GBP'),
      2100,
    );
    expect(
      rates.convertMinor(amountMinor: 100, from: 'GHS', to: 'NGN'),
      10000,
    );
    expect(
      rates.convertMinor(amountMinor: 2500, from: 'NGN', to: 'NGN'),
      2500,
    );
    expect(rates.rate(base: 'USD', quote: 'GBP'), 0.8);
  });

  test('unsupported currencies are rejected', () {
    expect(
      () => rates.convertMinor(amountMinor: 100, from: 'USD', to: 'JPY'),
      throwsArgumentError,
    );
  });

  test('money formatting and parsing keep two decimal places', () {
    expect(formatMinor(4860000, 'NGN'), '₦48,600.00');
    expect(formatMinor(-160, 'GBP'), '-£1.60');
    expect(formatMinor(100, 'USD'), r'$1.00');
    expect(formatMinor(0, 'NGN'), '₦0.00');
    expect(parseMoneyInput('48,600.50'), 4860050);
    expect(parseMoneyInput('12.5'), 1250);
    expect(parseMoneyInput('0'), isNull);
    expect(parseMoneyInput('0', allowZero: true), 0);
    expect(parseMoneyInput('1.234'), isNull);
    expect(parseMoneyInput(''), isNull);
    expect(formatShortDate(DateTime(2026, 10, 21)), '21 Oct 2026');
  });

  test('seeded books balance and match the hand-worked nets', () {
    final state = SeedData.build();
    final lagos = state.groupById('lagos')!;
    final london = state.groupById('london')!;
    final lagosLedger = GroupLedger.from(
      group: lagos,
      expenses: state.expenses,
      settlements: state.settlements,
    );
    final londonLedger = GroupLedger.from(
      group: london,
      expenses: state.expenses,
      settlements: state.settlements,
    );

    expect(lagosLedger.balances, {
      'ada': -5353750,
      'chi': 16986250,
      'fat': -5868750,
      'tun': -5763750,
    });
    expect(londonLedger.balances, {
      'ife': -160,
      'sar': 2980,
      'jam': 100,
      'ngo': -2920,
    });
    expect(
      [
        for (final transfer in lagosLedger.transfers)
          '${transfer.fromMemberId}->${transfer.toMemberId}:${transfer.amountMinor}',
      ],
      ['fat->chi:5868750', 'tun->chi:5763750', 'ada->chi:5353750'],
    );
    expect(
      [
        for (final transfer in londonLedger.transfers)
          '${transfer.fromMemberId}->${transfer.toMemberId}:${transfer.amountMinor}',
      ],
      ['ngo->sar:2920', 'ife->sar:60', 'ife->jam:100'],
    );

    for (final expense in state.expenses) {
      final shareSum = expense.sharesBaseMinor.values.fold<int>(
        0,
        (sum, share) => sum + share,
      );
      expect(shareSum, expense.baseAmountMinor);
    }

    final circle = state.ajoForGroup('lagos')!;
    expect(circle.potMinor, 8000000);
    expect(circle.currentCycle!.collectorMemberId, 'fat');
    expect(AjoRotation.nextOpenCycleIndex(circle.cycles), 2);
    expect(
      [for (final cycle in circle.cycles) cycle.collectorMemberId],
      ['ada', 'chi', 'fat', 'tun'],
    );
  });
}
