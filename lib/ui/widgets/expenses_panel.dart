import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/money_format.dart';
import '../../features/expenses/logic/group_ledger.dart';
import '../../features/expenses/models/expense.dart';
import '../../features/expenses/models/split_mode.dart';
import '../../features/groups/models/expense_group.dart';
import '../../state/app_controller.dart';
import '../screens/add_expense_screen.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';

class ExpensesPanel extends ConsumerWidget {
  const ExpensesPanel({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final group = state.groupById(groupId);
    if (group == null) return const SizedBox.shrink();
    final ledger = GroupLedger.from(
      group: group,
      expenses: state.expenses,
      settlements: state.settlements,
    );

    return ListView(
      key: const Key('expenses-list'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          '${ledger.expenses.length} '
          '${ledger.expenses.length == 1 ? 'expense' : 'expenses'}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('add-expense'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddExpenseScreen(groupId: groupId),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        ),
        const SizedBox(height: 8),
        if (ledger.expenses.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 28),
            child: Text(
              'No expenses yet. Add the first one and the split is saved with the group.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          )
        else
          for (final expense in ledger.expenses) ...[
            _ExpenseTile(group: group, expense: expense),
            const Divider(),
          ],
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.group, required this.expense});

  final ExpenseGroup group;
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final payer = group.findMember(expense.paidByMemberId);
    final foreign = expense.currencyCode != expense.baseCurrency;
    final meta = StringBuffer(group.memberName(expense.paidByMemberId))
      ..write(' paid · ')
      ..write(expense.splitMode.label)
      ..write(' · ')
      ..write(formatShortDate(expense.createdAt));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (payer != null) MemberAvatar(member: payer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMinor(expense.amountMinor, expense.currencyCode),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (foreign)
                    Text(
                      '≈ ${formatMinor(expense.baseAmountMinor, expense.baseCurrency)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: payer == null ? 0 : 48, top: 4),
            child: Text(
              meta.toString(),
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
          if (expense.note != null)
            Padding(
              padding: EdgeInsets.only(left: payer == null ? 0 : 48, top: 4),
              child: Text(
                expense.note!,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
