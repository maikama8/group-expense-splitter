import '../../../core/currency/exchange_rate_service.dart';
import '../models/split_mode.dart';

class SplitException implements Exception {
  SplitException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Shares owed for one expense, in the original currency and the group base.
class ComputedSplit {
  const ComputedSplit({
    required this.baseAmountMinor,
    required this.sharesOriginalMinor,
    required this.sharesBaseMinor,
  });

  final int baseAmountMinor;
  final Map<String, int> sharesOriginalMinor;
  final Map<String, int> sharesBaseMinor;
}

/// Splits an expense equally or by exact custom amounts, then converts.
///
/// Equal splits divide the original currency first (extra minor units go to
/// the earliest participants). Each share is converted, then the largest share
/// absorbs any rounding drift so the base shares still sum to the converted
/// total. That keeps the group ledger at zero.
class SplitCalculator {
  const SplitCalculator(this.rates);

  final ExchangeRateService rates;

  String? validate({
    required int amountMinor,
    required SplitMode mode,
    required List<String> participantIds,
    required Map<String, int> customSharesMinor,
  }) {
    if (amountMinor <= 0) {
      return 'Enter an amount greater than zero.';
    }
    if (mode == SplitMode.equal) {
      if (participantIds.isEmpty) {
        return 'Choose at least one person to include.';
      }
      if (participantIds.toSet().length != participantIds.length) {
        return 'Each person can only be included once.';
      }
      return null;
    }
    if (customSharesMinor.isEmpty) {
      return 'Enter a custom share for each person.';
    }
    if (customSharesMinor.length != participantIds.toSet().length ||
        !participantIds.toSet().containsAll(customSharesMinor.keys)) {
      return 'Custom shares must include each selected person once.';
    }
    for (final share in customSharesMinor.values) {
      if (share < 0) return 'Shares cannot be negative.';
    }
    final sum = customSharesMinor.values.fold<int>(
      0,
      (total, share) => total + share,
    );
    if (sum != amountMinor) {
      return 'Custom shares must add up to the total.';
    }
    return null;
  }

  ComputedSplit compute({
    required int amountMinor,
    required String currencyCode,
    required String baseCurrency,
    required SplitMode mode,
    required List<String> participantIds,
    required Map<String, int> customSharesMinor,
  }) {
    final error = validate(
      amountMinor: amountMinor,
      mode: mode,
      participantIds: participantIds,
      customSharesMinor: customSharesMinor,
    );
    if (error != null) throw SplitException(error);

    final original = switch (mode) {
      SplitMode.equal => _equalShares(amountMinor, participantIds),
      SplitMode.custom => Map<String, int>.from(customSharesMinor),
    };
    final baseTotal = rates.convertMinor(
      amountMinor: amountMinor,
      from: currencyCode,
      to: baseCurrency,
    );
    final baseShares = _convertShares(
      original: original,
      order: mode == SplitMode.equal
          ? participantIds
          : participantIds.where(original.containsKey).toList(),
      currencyCode: currencyCode,
      baseCurrency: baseCurrency,
      baseTotal: baseTotal,
    );
    return ComputedSplit(
      baseAmountMinor: baseTotal,
      sharesOriginalMinor: original,
      sharesBaseMinor: baseShares,
    );
  }

  Map<String, int> _equalShares(int totalMinor, List<String> participantIds) {
    final count = participantIds.length;
    final base = totalMinor ~/ count;
    final remainder = totalMinor % count;
    return {
      for (var i = 0; i < count; i++)
        participantIds[i]: base + (i < remainder ? 1 : 0),
    };
  }

  Map<String, int> _convertShares({
    required Map<String, int> original,
    required List<String> order,
    required String currencyCode,
    required String baseCurrency,
    required int baseTotal,
  }) {
    final converted = <String, int>{
      for (final id in order)
        id: rates.convertMinor(
          amountMinor: original[id]!,
          from: currencyCode,
          to: baseCurrency,
        ),
    };
    final sum = converted.values.fold<int>(0, (total, share) => total + share);
    final drift = baseTotal - sum;
    if (drift != 0 && converted.isNotEmpty) {
      var largestId = order.first;
      for (final id in order.skip(1)) {
        if (converted[id]! > converted[largestId]!) largestId = id;
      }
      final adjusted = converted[largestId]! + drift;
      if (adjusted < 0) {
        throw SplitException(
          'Currency conversion could not keep every share non-negative.',
        );
      }
      converted[largestId] = adjusted;
    }
    return converted;
  }
}
