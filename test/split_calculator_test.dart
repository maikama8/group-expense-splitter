import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_splitter/core/currency/exchange_rate_service.dart';
import 'package:group_expense_splitter/core/currency/mock_exchange_rate_service.dart';
import 'package:group_expense_splitter/features/expenses/logic/split_calculator.dart';
import 'package:group_expense_splitter/features/expenses/models/split_mode.dart';

void main() {
  const calculator = SplitCalculator(MockExchangeRateService());

  ComputedSplit equal({
    required int amountMinor,
    required String currency,
    required String base,
    required List<String> people,
  }) {
    return calculator.compute(
      amountMinor: amountMinor,
      currencyCode: currency,
      baseCurrency: base,
      mode: SplitMode.equal,
      participantIds: people,
      customSharesMinor: const {},
    );
  }

  test('equal split gives leftover minor units to the earliest people', () {
    final split = equal(
      amountMinor: 100,
      currency: 'NGN',
      base: 'NGN',
      people: const ['a', 'b', 'c'],
    );
    expect(split.sharesOriginalMinor, {'a': 34, 'b': 33, 'c': 33});
    expect(split.sharesBaseMinor, split.sharesOriginalMinor);
    expect(split.baseAmountMinor, 100);
  });

  test('equal split is exact when the amount divides evenly', () {
    final split = equal(
      amountMinor: 400,
      currency: 'USD',
      base: 'USD',
      people: const ['a', 'b', 'c', 'd'],
    );
    expect(split.sharesOriginalMinor.values, everyElement(100));
    expect(
      split.sharesOriginalMinor.values
          .fold<int>(0, (sum, share) => sum + share),
      400,
    );
  });

  test('equal split of a foreign amount converts after dividing', () {
    final split = equal(
      amountMinor: 18000,
      currency: 'USD',
      base: 'NGN',
      people: const ['a', 'b', 'c', 'd'],
    );
    expect(split.baseAmountMinor, 28800000);
    expect(split.sharesOriginalMinor.values, everyElement(4500));
    expect(split.sharesBaseMinor.values, everyElement(7200000));
  });

  test('custom shares must add up to the original total', () {
    final split = calculator.compute(
      amountMinor: 18000,
      currencyCode: 'USD',
      baseCurrency: 'NGN',
      mode: SplitMode.custom,
      participantIds: const ['chi', 'ada', 'fat', 'tun'],
      customSharesMinor: const {
        'chi': 6000,
        'ada': 5000,
        'fat': 4000,
        'tun': 3000,
      },
    );
    expect(split.sharesBaseMinor, {
      'chi': 9600000,
      'ada': 8000000,
      'fat': 6400000,
      'tun': 4800000,
    });
  });

  test('custom split rejects a total that does not match', () {
    expect(
      () => calculator.compute(
        amountMinor: 100,
        currencyCode: 'NGN',
        baseCurrency: 'NGN',
        mode: SplitMode.custom,
        participantIds: const ['a', 'b'],
        customSharesMinor: const {'a': 40, 'b': 50},
      ),
      throwsA(
        isA<SplitException>().having(
          (error) => error.message,
          'message',
          'Custom shares must add up to the total.',
        ),
      ),
    );
  });

  test('custom split rejects a negative share', () {
    expect(
      calculator.validate(
        amountMinor: 100,
        mode: SplitMode.custom,
        participantIds: const ['a', 'b'],
        customSharesMinor: const {'a': 120, 'b': -20},
      ),
      'Shares cannot be negative.',
    );
  });

  test('equal split rejects an empty group of people', () {
    expect(
      () => equal(
        amountMinor: 100,
        currency: 'NGN',
        base: 'NGN',
        people: const [],
      ),
      throwsA(isA<SplitException>()),
    );
  });

  test('equal split rejects duplicate people', () {
    expect(
      calculator.validate(
        amountMinor: 100,
        mode: SplitMode.equal,
        participantIds: const ['a', 'a'],
        customSharesMinor: const {},
      ),
      'Each person can only be included once.',
    );
  });

  test('conversion drift is absorbed so base shares still sum to the total',
      () {
    const lossy = SplitCalculator(_LossyRates());
    final split = lossy.compute(
      amountMinor: 10,
      currencyCode: 'USD',
      baseCurrency: 'NGN',
      mode: SplitMode.custom,
      participantIds: const ['a', 'b'],
      customSharesMinor: const {'a': 5, 'b': 5},
    );
    expect(split.baseAmountMinor, 3);
    expect(split.sharesBaseMinor, {'a': 1, 'b': 2});
    expect(
      split.sharesBaseMinor.values.fold<int>(0, (sum, share) => sum + share),
      split.baseAmountMinor,
    );
  });
}

class _LossyRates extends ExchangeRateService {
  const _LossyRates();

  @override
  double rate({required String base, required String quote}) => 1;

  @override
  int convertMinor({
    required int amountMinor,
    required String from,
    required String to,
  }) {
    if (from == to) return amountMinor;
    return (amountMinor / 3).round();
  }
}
