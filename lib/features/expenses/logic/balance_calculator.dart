import '../models/expense.dart';
import '../models/settlement.dart';

/// Net position of each member in the group base currency.
///
/// A positive balance means the group owes that member (they should receive
/// money). A negative balance means that member owes the group. Expenses and
/// recorded settlements are both applied, and a consistent book sums to zero.
class BalanceCalculator {
  const BalanceCalculator();

  Map<String, int> netBalances({
    required List<String> memberIds,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) {
    final balances = <String, int>{for (final id in memberIds) id: 0};

    for (final expense in expenses) {
      balances.update(
        expense.paidByMemberId,
        (value) => value + expense.baseAmountMinor,
        ifAbsent: () => expense.baseAmountMinor,
      );
      for (final entry in expense.sharesBaseMinor.entries) {
        balances.update(
          entry.key,
          (value) => value - entry.value,
          ifAbsent: () => -entry.value,
        );
      }
    }

    for (final settlement in settlements) {
      balances.update(
        settlement.fromMemberId,
        (value) => value + settlement.amountMinor,
        ifAbsent: () => settlement.amountMinor,
      );
      balances.update(
        settlement.toMemberId,
        (value) => value - settlement.amountMinor,
        ifAbsent: () => -settlement.amountMinor,
      );
    }

    return balances;
  }
}
