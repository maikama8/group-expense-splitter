import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/currency/currency.dart';
import '../features/ajo/models/ajo_models.dart';
import '../features/expenses/logic/split_calculator.dart';
import '../features/expenses/models/expense.dart';
import '../features/expenses/models/settlement.dart';
import '../features/expenses/models/split_mode.dart';
import 'app_state.dart';
import 'providers.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  int _sequence = 0;

  @override
  AppState build() => ref.read(groupBookRepositoryProvider).load();

  void addExpense({
    required String groupId,
    required String title,
    required int amountMinor,
    required String currencyCode,
    required String paidByMemberId,
    required SplitMode mode,
    required List<String> participantIds,
    required Map<String, int> customSharesMinor,
    String? note,
  }) {
    final group = state.groupById(groupId);
    if (group == null) {
      throw StateError('Unknown group $groupId');
    }
    if (!Currencies.isSupported(currencyCode) ||
        !Currencies.isSupported(group.baseCurrency)) {
      throw ArgumentError('Unsupported currency.');
    }
    if (group.findMember(paidByMemberId) == null) {
      throw ArgumentError('Payer is not in this group.');
    }
    for (final id in participantIds) {
      if (group.findMember(id) == null) {
        throw ArgumentError('A selected person is not in this group.');
      }
    }

    final trimmed = title.trim();
    final rates = ref.read(exchangeRateServiceProvider);
    final split = SplitCalculator(rates).compute(
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      baseCurrency: group.baseCurrency,
      mode: mode,
      participantIds: participantIds,
      customSharesMinor: customSharesMinor,
    );
    final expense = Expense(
      id: _id('exp'),
      groupId: groupId,
      title: trimmed,
      paidByMemberId: paidByMemberId,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      baseAmountMinor: split.baseAmountMinor,
      baseCurrency: group.baseCurrency,
      splitMode: mode,
      sharesOriginalMinor: split.sharesOriginalMinor,
      sharesBaseMinor: split.sharesBaseMinor,
      createdAt: DateTime.now(),
      note: _blankToNull(note),
    );
    _commit(
      AppState(
        groups: state.groups,
        expenses: [expense, ...state.expenses],
        settlements: state.settlements,
        ajoCircles: state.ajoCircles,
      ),
    );
  }

  void recordSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
  }) {
    final group = state.groupById(groupId);
    if (group == null) {
      throw StateError('Unknown group $groupId');
    }
    if (group.findMember(fromMemberId) == null ||
        group.findMember(toMemberId) == null) {
      throw ArgumentError('Both people must belong to the group.');
    }
    final settlement = Settlement(
      id: _id('set'),
      groupId: groupId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amountMinor: amountMinor,
      currencyCode: group.baseCurrency,
      createdAt: DateTime.now(),
    );
    _commit(
      AppState(
        groups: state.groups,
        expenses: state.expenses,
        settlements: [settlement, ...state.settlements],
        ajoCircles: state.ajoCircles,
      ),
    );
  }

  void setContributionStatus({
    required String circleId,
    required int cycleIndex,
    required String memberId,
    required ContributionStatus status,
  }) {
    final circles = [
      for (final circle in state.ajoCircles)
        if (circle.id != circleId)
          circle
        else
          _updateCycle(circle, cycleIndex, memberId, status),
    ];
    _commit(
      AppState(
        groups: state.groups,
        expenses: state.expenses,
        settlements: state.settlements,
        ajoCircles: circles,
      ),
    );
  }

  AjoCircle _updateCycle(
    AjoCircle circle,
    int cycleIndex,
    String memberId,
    ContributionStatus status,
  ) {
    var found = false;
    final cycles = <AjoCycle>[];
    for (final cycle in circle.cycles) {
      if (cycle.index != cycleIndex) {
        cycles.add(cycle);
        continue;
      }
      if (!cycle.contributions.containsKey(memberId)) {
        throw ArgumentError('That person is not in this cycle.');
      }
      found = true;
      cycles.add(
        cycle.copyWith(
          contributions: {...cycle.contributions, memberId: status},
        ),
      );
    }
    if (!found) {
      throw ArgumentError('Unknown cycle $cycleIndex.');
    }
    return circle.copyWith(cycles: cycles);
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  void _commit(AppState next) {
    state = next;
    ref.read(groupBookRepositoryProvider).save(next);
  }

  String _id(String prefix) {
    _sequence += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_sequence';
  }
}
