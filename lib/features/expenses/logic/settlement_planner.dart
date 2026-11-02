import '../models/settlement.dart';

class _Party {
  _Party(this.id, this.remaining);

  final String id;
  int remaining;
}

/// Greedy settle-up.
///
/// Debtors (negative balances) pay creditors (positive balances). The largest
/// remaining amounts are matched first, which clears a balanced book in at
/// most one payment per person after the first. Equal amounts break ties by
/// member id so the result is stable.
///
/// Finding the absolute minimum number of payments is a harder problem; this
/// is the usual practical settle-up used by expense splitters.
class SettlementPlanner {
  const SettlementPlanner();

  List<Transfer> plan({
    required Map<String, int> balances,
    required String currencyCode,
  }) {
    final debtors = <_Party>[];
    final creditors = <_Party>[];
    for (final entry in balances.entries) {
      if (entry.value < 0) {
        debtors.add(_Party(entry.key, -entry.value));
      } else if (entry.value > 0) {
        creditors.add(_Party(entry.key, entry.value));
      }
    }
    int byAmountThenId(_Party a, _Party b) {
      final byAmount = b.remaining.compareTo(a.remaining);
      if (byAmount != 0) return byAmount;
      return a.id.compareTo(b.id);
    }

    debtors.sort(byAmountThenId);
    creditors.sort(byAmountThenId);

    final transfers = <Transfer>[];
    var debtorIndex = 0;
    var creditorIndex = 0;
    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final pay = debtor.remaining < creditor.remaining
          ? debtor.remaining
          : creditor.remaining;
      if (pay == 0) break;
      if (pay > 0) {
        transfers.add(
          Transfer(
            fromMemberId: debtor.id,
            toMemberId: creditor.id,
            amountMinor: pay,
            currencyCode: currencyCode,
          ),
        );
        debtor.remaining -= pay;
        creditor.remaining -= pay;
      }
      if (debtor.remaining == 0) debtorIndex += 1;
      if (creditor.remaining == 0) creditorIndex += 1;
    }
    return transfers;
  }
}
