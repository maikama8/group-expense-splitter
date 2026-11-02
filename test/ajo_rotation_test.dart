import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_splitter/features/ajo/logic/ajo_rotation.dart';
import 'package:group_expense_splitter/features/ajo/models/ajo_models.dart';

void main() {
  const order = ['ada', 'chi', 'fat', 'tun'];

  test('the collector walks the rotation and wraps', () {
    expect(AjoRotation.collectorForCycle(order, 0), 'ada');
    expect(AjoRotation.collectorForCycle(order, 1), 'chi');
    expect(AjoRotation.collectorForCycle(order, 3), 'tun');
    expect(AjoRotation.collectorForCycle(order, 4), 'ada');
    expect(AjoRotation.collectorForCycle(order, 5), 'chi');
  });

  test('an empty rotation or a negative cycle is rejected', () {
    expect(
        () => AjoRotation.collectorForCycle(const [], 0), throwsArgumentError);
    expect(() => AjoRotation.collectorForCycle(order, -1), throwsArgumentError);
  });

  test('monthly dues clamp to the end of a short month', () {
    final ordinary = AjoRotation.buildSchedule(
      rotationOrder: order,
      startDate: DateTime(2026, 8, 1),
      frequency: AjoFrequency.monthly,
      cycleCount: 4,
    );
    expect(
      [for (final cycle in ordinary) cycle.dueDate],
      [
        DateTime(2026, 8, 1),
        DateTime(2026, 9, 1),
        DateTime(2026, 10, 1),
        DateTime(2026, 11, 1),
      ],
    );
    expect(
      [for (final cycle in ordinary) cycle.collectorMemberId],
      order,
    );

    expect(
      AjoRotation.dueDate(
        startDate: DateTime(2026, 1, 31),
        frequency: AjoFrequency.monthly,
        cycleIndex: 1,
      ),
      DateTime(2026, 2, 28),
    );
    expect(
      AjoRotation.dueDate(
        startDate: DateTime(2024, 1, 31),
        frequency: AjoFrequency.monthly,
        cycleIndex: 1,
      ),
      DateTime(2024, 2, 29),
    );
  });

  test('weekly dues step forward seven days at a time', () {
    final schedule = AjoRotation.buildSchedule(
      rotationOrder: const ['ada', 'chi'],
      startDate: DateTime(2026, 3, 2),
      frequency: AjoFrequency.weekly,
      cycleCount: 3,
    );
    expect(
      [for (final cycle in schedule) cycle.dueDate],
      [
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 16),
      ],
    );
    expect(schedule[2].collectorMemberId, 'ada');
  });

  test('the pot is one contribution from every member, including the collector',
      () {
    expect(
      AjoRotation.potMinor(contributionMinor: 2000000, memberCount: 4),
      8000000,
    );
    expect(
      () => AjoRotation.potMinor(contributionMinor: -1, memberCount: 4),
      throwsArgumentError,
    );
  });

  test('a cycle is complete only when every contribution is paid', () {
    expect(
      AjoRotation.isFullyPaid(const {
        'ada': ContributionStatus.paid,
        'chi': ContributionStatus.paid,
      }),
      isTrue,
    );
    expect(
      AjoRotation.isFullyPaid(const {
        'ada': ContributionStatus.paid,
        'chi': ContributionStatus.pending,
      }),
      isFalse,
    );
    expect(AjoRotation.isFullyPaid(const {}), isFalse);
  });

  test('the next open cycle is the first one that is not fully paid', () {
    final cycles = [
      _cycle(0, 'ada', paid: true),
      _cycle(1, 'chi', paid: false),
      _cycle(2, 'fat', paid: false),
    ];
    expect(AjoRotation.nextOpenCycleIndex(cycles), 1);
    expect(
      AjoRotation.nextOpenCycleIndex([
        _cycle(0, 'ada', paid: true),
        _cycle(1, 'chi', paid: true),
      ]),
      isNull,
    );
  });

  test('a zero-length schedule is empty and a negative count is rejected', () {
    expect(
      AjoRotation.buildSchedule(
        rotationOrder: order,
        startDate: DateTime(2026, 1, 1),
        frequency: AjoFrequency.monthly,
        cycleCount: 0,
      ),
      isEmpty,
    );
    expect(
      () => AjoRotation.buildSchedule(
        rotationOrder: order,
        startDate: DateTime(2026, 1, 1),
        frequency: AjoFrequency.monthly,
        cycleCount: -1,
      ),
      throwsArgumentError,
    );
  });
}

AjoCycle _cycle(int index, String collector, {required bool paid}) {
  return AjoCycle(
    index: index,
    collectorMemberId: collector,
    dueDate: DateTime(2026, 1, 1),
    contributions: {
      'ada': paid ? ContributionStatus.paid : ContributionStatus.pending,
      'chi': ContributionStatus.paid,
    },
  );
}
