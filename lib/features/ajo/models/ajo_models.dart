enum AjoFrequency { weekly, monthly }

enum ContributionStatus { pending, paid }

extension AjoFrequencyLabel on AjoFrequency {
  String get label => switch (this) {
        AjoFrequency.weekly => 'Weekly',
        AjoFrequency.monthly => 'Monthly',
      };
}

/// One rotation cycle: a due date, the member who collects, and who has paid.
class AjoCycle {
  const AjoCycle({
    required this.index,
    required this.collectorMemberId,
    required this.dueDate,
    required this.contributions,
  });

  final int index;
  final String collectorMemberId;
  final DateTime dueDate;
  final Map<String, ContributionStatus> contributions;

  bool get isComplete =>
      contributions.isNotEmpty &&
      contributions.values.every(
        (status) => status == ContributionStatus.paid,
      );

  int get paidCount => contributions.values
      .where((status) => status == ContributionStatus.paid)
      .length;

  AjoCycle copyWith({Map<String, ContributionStatus>? contributions}) {
    return AjoCycle(
      index: index,
      collectorMemberId: collectorMemberId,
      dueDate: dueDate,
      contributions: contributions ?? this.contributions,
    );
  }
}

/// A rotating savings circle (Ajo / Esusu) attached to a group.
///
/// Every member, including the collector, contributes [contributionMinor] each
/// cycle. The collector receives the full pot for that cycle.
class AjoCircle {
  AjoCircle({
    required this.id,
    required this.groupId,
    required this.name,
    required this.currencyCode,
    required this.contributionMinor,
    required this.frequency,
    required this.rotationOrder,
    required this.cycles,
  }) {
    if (rotationOrder.isEmpty) {
      throw ArgumentError('An Ajo circle needs a rotation order.');
    }
    if (rotationOrder.toSet().length != rotationOrder.length) {
      throw ArgumentError('Rotation order cannot repeat a member.');
    }
    if (contributionMinor < 0) {
      throw ArgumentError('Contribution cannot be negative.');
    }
  }

  final String id;
  final String groupId;
  final String name;
  final String currencyCode;
  final int contributionMinor;
  final AjoFrequency frequency;
  final List<String> rotationOrder;
  final List<AjoCycle> cycles;

  int get potMinor => contributionMinor * rotationOrder.length;

  /// First cycle that is not fully paid, or the last cycle when all are done.
  AjoCycle? get currentCycle {
    if (cycles.isEmpty) return null;
    for (final cycle in cycles) {
      if (!cycle.isComplete) return cycle;
    }
    return cycles.last;
  }

  AjoCircle copyWith({List<AjoCycle>? cycles}) {
    return AjoCircle(
      id: id,
      groupId: groupId,
      name: name,
      currencyCode: currencyCode,
      contributionMinor: contributionMinor,
      frequency: frequency,
      rotationOrder: rotationOrder,
      cycles: cycles ?? this.cycles,
    );
  }
}
