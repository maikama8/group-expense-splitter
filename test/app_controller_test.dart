import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_splitter/data/group_book_repository.dart';
import 'package:group_expense_splitter/data/seed_data.dart';
import 'package:group_expense_splitter/features/ajo/logic/ajo_rotation.dart';
import 'package:group_expense_splitter/features/ajo/models/ajo_models.dart';
import 'package:group_expense_splitter/features/expenses/logic/group_ledger.dart';
import 'package:group_expense_splitter/features/expenses/models/split_mode.dart';
import 'package:group_expense_splitter/state/app_controller.dart';
import 'package:group_expense_splitter/state/providers.dart';

void main() {
  test('adding an expense changes only the payer net by their extra share', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = _ledger(container, 'lagos').balances['ada'];
    container.read(appControllerProvider.notifier).addExpense(
      groupId: 'lagos',
      title: 'Suya',
      amountMinor: 400000,
      currencyCode: 'NGN',
      paidByMemberId: 'ada',
      mode: SplitMode.equal,
      participantIds: const ['ada', 'chi'],
      customSharesMinor: const {},
    );

    final after = _ledger(container, 'lagos');
    expect(after.expenses.first.title, 'Suya');
    expect(after.balances['ada'], before! + 200000);
  });

  test('recording every suggested payment settles the Lagos book', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appControllerProvider.notifier);
    final suggested = _ledger(container, 'lagos').transfers;

    for (final transfer in suggested) {
      notifier.recordSettlement(
        groupId: 'lagos',
        fromMemberId: transfer.fromMemberId,
        toMemberId: transfer.toMemberId,
        amountMinor: transfer.amountMinor,
      );
    }

    final settled = _ledger(container, 'lagos');
    expect(settled.isSettled, isTrue);
    expect(settled.balances.values, everyElement(0));
    expect(settled.transfers, isEmpty);
  });

  test('marking the open Esusu cycle paid moves the pot to the next collector',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appControllerProvider.notifier);

    for (final memberId in ['fat', 'tun']) {
      notifier.setContributionStatus(
        circleId: 'esusu-lagos',
        cycleIndex: 2,
        memberId: memberId,
        status: ContributionStatus.paid,
      );
    }

    final circle = container.read(appControllerProvider).ajoForGroup('lagos')!;
    expect(circle.currentCycle!.collectorMemberId, 'tun');
    expect(AjoRotation.nextOpenCycleIndex(circle.cycles), 3);
  });

  test(
      'the in-memory repository keeps the book after the controller is rebuilt',
      () {
    final repository = InMemoryGroupBookRepository(initial: SeedData.build());
    final first = ProviderContainer(
      overrides: [
        groupBookRepositoryProvider.overrideWithValue(repository),
      ],
    );
    first.read(appControllerProvider.notifier).addExpense(
      groupId: 'london',
      title: 'Oyster card',
      amountMinor: 2000,
      currencyCode: 'GBP',
      paidByMemberId: 'ife',
      mode: SplitMode.equal,
      participantIds: const ['ife', 'sar', 'jam', 'ngo'],
      customSharesMinor: const {},
    );
    first.dispose();

    final second = ProviderContainer(
      overrides: [
        groupBookRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(second.dispose);
    expect(
      second.read(appControllerProvider).expenses.first.title,
      'Oyster card',
    );
  });

  test('an unknown group cannot take an expense', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      () => container.read(appControllerProvider.notifier).addExpense(
        groupId: 'missing',
        title: 'Coffee',
        amountMinor: 100,
        currencyCode: 'NGN',
        paidByMemberId: 'ada',
        mode: SplitMode.equal,
        participantIds: const ['ada'],
        customSharesMinor: const {},
      ),
      throwsStateError,
    );
  });
}

GroupLedger _ledger(ProviderContainer container, String groupId) {
  final state = container.read(appControllerProvider);
  return GroupLedger.from(
    group: state.groupById(groupId)!,
    expenses: state.expenses,
    settlements: state.settlements,
  );
}
