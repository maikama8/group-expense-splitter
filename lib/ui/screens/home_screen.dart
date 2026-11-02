import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/money_format.dart';
import '../../features/expenses/logic/group_ledger.dart';
import '../../features/groups/models/expense_group.dart';
import '../../state/app_controller.dart';
import '../../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';
import 'group_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _Hero(),
            const SizedBox(height: 22),
            Text('Groups', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final group in state.groups) ...[
              _GroupCard(group: group, state: state),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            const Text(
              'A portfolio project by Abdulrasheed Oseni. '
              'Books stay in memory on this device.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MULTI-CURRENCY · AJO',
            style: TextStyle(
              color: AppColors.goldOnForest,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Split fairly.\nSave together.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Shared expenses in naira, dollars, pounds, euros, and cedis, '
            'plus a rotating savings circle.',
            style: TextStyle(color: Color(0xFFD5E4DC), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.state});

  final ExpenseGroup group;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final ledger = GroupLedger.from(
      group: group,
      expenses: state.expenses,
      settlements: state.settlements,
    );
    final settleLabel = ledger.isSettled
        ? 'Settled'
        : '${ledger.transfers.length} '
            '${ledger.transfers.length == 1 ? 'payment' : 'payments'} to settle';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GroupScreen(groupId: group.id),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      group.baseCurrency,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  group.description,
                  style: const TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    AvatarStack(members: group.members),
                    const SizedBox(width: 10),
                    Text(
                      '${group.members.length} members',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Flexible(
                      child: _Pill(
                        label: settleLabel,
                        color: ledger.isSettled
                            ? AppColors.receive
                            : AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ledger.isSettled
                          ? formatMinor(0, group.baseCurrency)
                          : formatMinor(
                              ledger.unsettledMinor,
                              group.baseCurrency,
                            ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
