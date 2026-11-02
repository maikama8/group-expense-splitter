import '../models/ajo_models.dart';

/// Who collects, when the cycle is due, and whether the pot is complete.
class CyclePlan {
  const CyclePlan({
    required this.index,
    required this.collectorMemberId,
    required this.dueDate,
  });

  final int index;
  final String collectorMemberId;
  final DateTime dueDate;
}

class AjoRotation {
  const AjoRotation._();

  /// Member who collects [cycleIndex], wrapping around [rotationOrder].
  static String collectorForCycle(List<String> rotationOrder, int cycleIndex) {
    if (rotationOrder.isEmpty) {
      throw ArgumentError('Rotation order must not be empty.');
    }
    if (cycleIndex < 0) {
      throw ArgumentError.value(cycleIndex, 'cycleIndex', 'Must be >= 0.');
    }
    return rotationOrder[cycleIndex % rotationOrder.length];
  }

  static DateTime dueDate({
    required DateTime startDate,
    required AjoFrequency frequency,
    required int cycleIndex,
  }) {
    if (cycleIndex < 0) {
      throw ArgumentError.value(cycleIndex, 'cycleIndex', 'Must be >= 0.');
    }
    return switch (frequency) {
      AjoFrequency.weekly => startDate.add(Duration(days: 7 * cycleIndex)),
      AjoFrequency.monthly => _addMonths(startDate, cycleIndex),
    };
  }

  static List<CyclePlan> buildSchedule({
    required List<String> rotationOrder,
    required DateTime startDate,
    required AjoFrequency frequency,
    required int cycleCount,
  }) {
    if (cycleCount < 0) {
      throw ArgumentError.value(cycleCount, 'cycleCount', 'Must be >= 0.');
    }
    return [
      for (var index = 0; index < cycleCount; index++)
        CyclePlan(
          index: index,
          collectorMemberId: collectorForCycle(rotationOrder, index),
          dueDate: dueDate(
            startDate: startDate,
            frequency: frequency,
            cycleIndex: index,
          ),
        ),
    ];
  }

  /// Full pot for one cycle. Everyone contributes, including the collector.
  static int potMinor({
    required int contributionMinor,
    required int memberCount,
  }) {
    if (contributionMinor < 0 || memberCount < 0) {
      throw ArgumentError('Contribution and member count must be >= 0.');
    }
    return contributionMinor * memberCount;
  }

  static bool isFullyPaid(Map<String, ContributionStatus> contributions) {
    if (contributions.isEmpty) return false;
    return contributions.values.every(
      (status) => status == ContributionStatus.paid,
    );
  }

  /// Index of the first cycle that still has an unpaid contribution.
  static int? nextOpenCycleIndex(List<AjoCycle> cycles) {
    final index =
        cycles.indexWhere((cycle) => !isFullyPaid(cycle.contributions));
    return index == -1 ? null : index;
  }

  static DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }
}
