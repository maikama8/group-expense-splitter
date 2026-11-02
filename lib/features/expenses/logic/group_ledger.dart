import '../../groups/models/expense_group.dart';
import '../models/expense.dart';
import '../models/settlement.dart';
import 'balance_calculator.dart';
import 'settlement_planner.dart';

/// Balances and suggested payments for one group.
class GroupLedger {
  const GroupLedger({
    required this.group,
    required this.expenses,
    required this.settlements,
    required this.balances,
    required this.transfers,
  });

  final ExpenseGroup group;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final Map<String, int> balances;
  final List<Transfer> transfers;

  /// Sum of what creditors are still owed. Zero when the group is settled.
  int get unsettledMinor => balances.values
      .where((value) => value > 0)
      .fold<int>(0, (total, value) => total + value);

  bool get isSettled => unsettledMinor == 0;

  static GroupLedger from({
    required ExpenseGroup group,
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) {
    final groupExpenses = expenses
        .where((expense) => expense.groupId == group.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final groupSettlements = settlements
        .where((settlement) => settlement.groupId == group.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final balances = const BalanceCalculator().netBalances(
      memberIds: [for (final member in group.members) member.id],
      expenses: groupExpenses,
      settlements: groupSettlements,
    );
    final transfers = const SettlementPlanner().plan(
      balances: balances,
      currencyCode: group.baseCurrency,
    );
    return GroupLedger(
      group: group,
      expenses: groupExpenses,
      settlements: groupSettlements,
      balances: balances,
      transfers: transfers,
    );
  }
}
