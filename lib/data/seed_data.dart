import '../core/currency/mock_exchange_rate_service.dart';
import '../features/ajo/logic/ajo_rotation.dart';
import '../features/ajo/models/ajo_models.dart';
import '../features/expenses/logic/split_calculator.dart';
import '../features/expenses/models/expense.dart';
import '../features/expenses/models/split_mode.dart';
import '../features/groups/models/expense_group.dart';
import '../features/groups/models/member.dart';
import '../state/app_state.dart';

/// Sample books so the app opens on a lived-in ledger instead of an empty screen.
class SeedData {
  const SeedData._();

  static AppState build() {
    const rates = MockExchangeRateService();
    const calculator = SplitCalculator(rates);

    const ada = Member(id: 'ada', name: 'Adaeze Okonkwo');
    const chi = Member(id: 'chi', name: 'Chinedu Eze');
    const fat = Member(id: 'fat', name: 'Fatima Bello');
    const tun = Member(id: 'tun', name: 'Tunde Adeyemi');

    final lagos = ExpenseGroup(
      id: 'lagos',
      name: 'December in Lagos',
      description:
          'Friends sharing a long weekend — dinners, rides, and a short stay.',
      baseCurrency: 'NGN',
      members: const [ada, chi, fat, tun],
      createdAt: DateTime(2026, 10, 1),
    );

    const ife = Member(id: 'ife', name: 'Ifeanyi Nwosu');
    const sar = Member(id: 'sar', name: 'Sarah Mensah');
    const jam = Member(id: 'jam', name: 'James Okeke');
    const ngo = Member(id: 'ngo', name: 'Ngozi Adewale');

    final london = ExpenseGroup(
      id: 'london',
      name: 'London client trip',
      description:
          'Four colleagues splitting travel money across pounds, dollars, and euros.',
      baseCurrency: 'GBP',
      members: const [ife, sar, jam, ngo],
      createdAt: DateTime(2026, 10, 8),
    );

    final lagosMembers = ['ada', 'chi', 'fat', 'tun'];
    final londonMembers = ['ife', 'sar', 'jam', 'ngo'];

    final expenses = [
      _expense(
        calculator,
        id: 'exp-groceries',
        group: lagos,
        title: 'Grocery run, Shoprite',
        paidBy: 'fat',
        amountMinor: 2745000,
        currencyCode: 'NGN',
        mode: SplitMode.equal,
        participants: lagosMembers,
        createdAt: DateTime(2026, 10, 21),
      ),
      _expense(
        calculator,
        id: 'exp-airbnb',
        group: lagos,
        title: 'Weekend Airbnb',
        paidBy: 'chi',
        amountMinor: 18000,
        currencyCode: 'USD',
        mode: SplitMode.custom,
        participants: lagosMembers,
        customSharesMinor: const {
          'chi': 6000,
          'ada': 5000,
          'fat': 4000,
          'tun': 3000,
        },
        note: 'Custom shares in dollars: 60 / 50 / 40 / 30.',
        createdAt: DateTime(2026, 10, 20),
      ),
      _expense(
        calculator,
        id: 'exp-bolt',
        group: lagos,
        title: 'Bolt rides, Ikeja to VI',
        paidBy: 'tun',
        amountMinor: 1250000,
        currencyCode: 'NGN',
        mode: SplitMode.equal,
        participants: lagosMembers,
        createdAt: DateTime(2026, 10, 19),
      ),
      _expense(
        calculator,
        id: 'exp-dinner',
        group: lagos,
        title: 'Dinner at Terra Kulture',
        paidBy: 'ada',
        amountMinor: 4860000,
        currencyCode: 'NGN',
        mode: SplitMode.equal,
        participants: lagosMembers,
        createdAt: DateTime(2026, 10, 18),
      ),
      _expense(
        calculator,
        id: 'exp-museum',
        group: london,
        title: 'Museum tickets',
        paidBy: 'ngo',
        amountMinor: 2400,
        currencyCode: 'EUR',
        mode: SplitMode.equal,
        participants: londonMembers,
        createdAt: DateTime(2026, 10, 15),
      ),
      _expense(
        calculator,
        id: 'exp-lunch',
        group: london,
        title: 'Team lunch',
        paidBy: 'jam',
        amountMinor: 6400,
        currencyCode: 'USD',
        mode: SplitMode.equal,
        participants: londonMembers,
        createdAt: DateTime(2026, 10, 14),
      ),
      _expense(
        calculator,
        id: 'exp-shoreditch',
        group: london,
        title: 'Dinner in Shoreditch',
        paidBy: 'sar',
        amountMinor: 8600,
        currencyCode: 'GBP',
        mode: SplitMode.custom,
        participants: londonMembers,
        customSharesMinor: const {
          'sar': 2600,
          'ife': 2000,
          'jam': 2000,
          'ngo': 2000,
        },
        createdAt: DateTime(2026, 10, 13),
      ),
      _expense(
        calculator,
        id: 'exp-rail',
        group: london,
        title: 'Elizabeth line tickets',
        paidBy: 'ife',
        amountMinor: 4860,
        currencyCode: 'GBP',
        mode: SplitMode.equal,
        participants: londonMembers,
        createdAt: DateTime(2026, 10, 12),
      ),
    ];

    return AppState(
      groups: [lagos, london],
      expenses: expenses,
      settlements: const [],
      ajoCircles: [_familyEsusu()],
    );
  }

  static Expense _expense(
    SplitCalculator calculator, {
    required String id,
    required ExpenseGroup group,
    required String title,
    required String paidBy,
    required int amountMinor,
    required String currencyCode,
    required SplitMode mode,
    required List<String> participants,
    required DateTime createdAt,
    Map<String, int> customSharesMinor = const {},
    String? note,
  }) {
    final split = calculator.compute(
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      baseCurrency: group.baseCurrency,
      mode: mode,
      participantIds: participants,
      customSharesMinor: customSharesMinor,
    );
    return Expense(
      id: id,
      groupId: group.id,
      title: title,
      paidByMemberId: paidBy,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      baseAmountMinor: split.baseAmountMinor,
      baseCurrency: group.baseCurrency,
      splitMode: mode,
      sharesOriginalMinor: split.sharesOriginalMinor,
      sharesBaseMinor: split.sharesBaseMinor,
      createdAt: createdAt,
      note: note,
    );
  }

  static AjoCircle _familyEsusu() {
    const order = ['ada', 'chi', 'fat', 'tun'];
    const contribution = 2000000;
    final start = DateTime(2026, 8, 1);
    final plans = AjoRotation.buildSchedule(
      rotationOrder: order,
      startDate: start,
      frequency: AjoFrequency.monthly,
      cycleCount: 4,
    );

    Map<String, ContributionStatus> statusFor(int index) {
      return {
        for (final memberId in order)
          memberId: switch (index) {
            0 || 1 => ContributionStatus.paid,
            2 => memberId == 'ada' || memberId == 'chi'
                ? ContributionStatus.paid
                : ContributionStatus.pending,
            _ => ContributionStatus.pending,
          },
      };
    }

    return AjoCircle(
      id: 'esusu-lagos',
      groupId: 'lagos',
      name: 'Family Esusu',
      currencyCode: 'NGN',
      contributionMinor: contribution,
      frequency: AjoFrequency.monthly,
      rotationOrder: order,
      cycles: [
        for (final plan in plans)
          AjoCycle(
            index: plan.index,
            collectorMemberId: plan.collectorMemberId,
            dueDate: plan.dueDate,
            contributions: statusFor(plan.index),
          ),
      ],
    );
  }
}
