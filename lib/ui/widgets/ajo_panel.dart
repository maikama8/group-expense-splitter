import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/money_format.dart';
import '../../features/ajo/logic/ajo_rotation.dart';
import '../../features/ajo/models/ajo_models.dart';
import '../../state/app_controller.dart';
import '../theme/app_theme.dart';

class AjoPanel extends ConsumerWidget {
  const AjoPanel({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final group = state.groupById(groupId);
    final circle = state.ajoForGroup(groupId);
    if (group == null) return const SizedBox.shrink();
    if (circle == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No Ajo circle yet.\n\n'
          'Ajo and Esusu are rotating savings: everyone contributes a fixed '
          'amount each cycle, and one member collects the pot. The order '
          'repeats until each person has collected.',
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
      );
    }

    final current = circle.currentCycle;
    final openIndex = AjoRotation.nextOpenCycleIndex(circle.cycles);
    final collector =
        current == null ? null : group.memberName(current.collectorMemberId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          circle.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '${circle.frequency.label} · ${circle.rotationOrder.length} people',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                openIndex == null ? 'ALL CYCLES PAID' : 'OPEN CYCLE',
                style: const TextStyle(
                  color: AppColors.goldOnForest,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                collector == null
                    ? 'No cycles scheduled'
                    : '$collector collects',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Each person puts in ${formatMinor(circle.contributionMinor, circle.currencyCode)}. '
                'The pot is ${formatMinor(circle.potMinor, circle.currencyCode)}.',
                style: const TextStyle(color: Color(0xFFD5E4DC), height: 1.4),
              ),
              if (current != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Due ${formatShortDate(current.dueDate)} · '
                  '${current.paidCount}/${current.contributions.length} paid',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Everyone contributes, including the person who collects. '
          'The collector receives the full pot for that cycle. '
          'Tap a name to mark their contribution paid or still due.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 8),
        for (final cycle in circle.cycles)
          _CycleTile(
            key: ValueKey('${circle.id}-${cycle.index}'),
            circle: circle,
            cycle: cycle,
            groupNames: {
              for (final member in group.members) member.id: member.name,
            },
            initiallyExpanded: cycle.index == current?.index,
          ),
      ],
    );
  }
}

class _CycleTile extends ConsumerWidget {
  const _CycleTile({
    required this.circle,
    required this.cycle,
    required this.groupNames,
    required this.initiallyExpanded,
    super.key,
  });

  final AjoCircle circle;
  final AjoCycle cycle;
  final Map<String, String> groupNames;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collector = groupNames[cycle.collectorMemberId] ?? 'Member';
    return Card(
      margin: const EdgeInsets.only(top: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text('Cycle ${cycle.index + 1} · $collector'),
        subtitle: Text(
          '${formatShortDate(cycle.dueDate)} · '
          '${cycle.paidCount}/${cycle.contributions.length} paid',
        ),
        children: [
          for (final memberId in circle.rotationOrder)
            CheckboxListTile(
              value: cycle.contributions[memberId] == ContributionStatus.paid,
              title: Text(groupNames[memberId] ?? memberId),
              subtitle: Text(
                memberId == cycle.collectorMemberId
                    ? 'Collects the pot'
                    : 'Contributes',
              ),
              activeColor: AppColors.forest,
              onChanged: (checked) {
                ref.read(appControllerProvider.notifier).setContributionStatus(
                      circleId: circle.id,
                      cycleIndex: cycle.index,
                      memberId: memberId,
                      status: checked ?? false
                          ? ContributionStatus.paid
                          : ContributionStatus.pending,
                    );
              },
            ),
        ],
      ),
    );
  }
}
