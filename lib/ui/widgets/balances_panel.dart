import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/money_format.dart';
import '../../features/expenses/logic/group_ledger.dart';
import '../../features/expenses/models/settlement.dart';
import '../../features/groups/models/member.dart';
import '../../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'member_avatar.dart';

class BalancesPanel extends ConsumerWidget {
  const BalancesPanel({required this.groupId, super.key});

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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _SummaryCard(ledger: ledger),
        const SizedBox(height: 18),
        const Text(
          'Net balances',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Positive means the group owes them. Negative means they owe the group. '
          'Figures are in the group currency.',
          style: TextStyle(color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 8),
        for (final member in group.members)
          _BalanceRow(
            name: member.name,
            member: member,
            minor: ledger.balances[member.id] ?? 0,
            currencyCode: group.baseCurrency,
          ),
        const SizedBox(height: 18),
        const Text('Settle up', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
          'Suggested payments clear the book by matching the largest remaining amounts first.',
          style: TextStyle(color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 10),
        if (ledger.transfers.isEmpty)
          const Text(
            'Nothing to settle. Everyone is square.',
            style: TextStyle(
                color: AppColors.receive, fontWeight: FontWeight.w600),
          )
        else
          for (final transfer in ledger.transfers) ...[
            _TransferCard(
              groupId: groupId,
              transfer: transfer,
              fromName: group.memberName(transfer.fromMemberId),
              toName: group.memberName(transfer.toMemberId),
            ),
            const SizedBox(height: 8),
          ],
        if (ledger.settlements.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Recorded payments',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final settlement in ledger.settlements)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${group.memberName(settlement.fromMemberId)} paid '
                '${group.memberName(settlement.toMemberId)} '
                '${formatMinor(settlement.amountMinor, settlement.currencyCode)}'
                ' · ${formatShortDate(settlement.createdAt)}',
                style: const TextStyle(height: 1.35),
              ),
            ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.ledger});

  final GroupLedger ledger;

  @override
  Widget build(BuildContext context) {
    final currency = ledger.group.baseCurrency;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STILL MOVING',
            style: TextStyle(
              color: AppColors.goldOnForest,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatMinor(ledger.unsettledMinor, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ledger.isSettled
                ? 'This group is settled.'
                : 'Total that still needs to change hands.',
            style: const TextStyle(color: Color(0xFFD5E4DC)),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.name,
    required this.member,
    required this.minor,
    required this.currencyCode,
  });

  final String name;
  final Member member;
  final int minor;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final color = minor > 0
        ? AppColors.receive
        : minor < 0
            ? AppColors.owe
            : AppColors.muted;
    final word = minor > 0
        ? 'gets back'
        : minor < 0
            ? 'owes'
            : 'settled';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          MemberAvatar(member: member, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  word,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatMinor(minor, currencyCode),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TransferCard extends ConsumerWidget {
  const _TransferCard({
    required this.groupId,
    required this.transfer,
    required this.fromName,
    required this.toName,
  });

  final String groupId;
  final Transfer transfer;
  final String fromName;
  final String toName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fromName pays $toName',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMinor(transfer.amountMinor, transfer.currencyCode),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              ref.read(appControllerProvider.notifier).recordSettlement(
                    groupId: groupId,
                    fromMemberId: transfer.fromMemberId,
                    toMemberId: transfer.toMemberId,
                    amountMinor: transfer.amountMinor,
                  );
              messenger.showSnackBar(
                SnackBar(content: Text('$fromName paid $toName')),
              );
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }
}
