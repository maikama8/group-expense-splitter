import 'split_mode.dart';

/// One shared cost, stored in its original currency and in the group base.
///
/// [sharesOriginalMinor] is what each participant owes in [currencyCode].
/// [sharesBaseMinor] is that same split after conversion, adjusted so the
/// shares still add up to [baseAmountMinor]. Positive ledger entries always
/// balance because of that adjustment.
class Expense {
  Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.paidByMemberId,
    required this.amountMinor,
    required this.currencyCode,
    required this.baseAmountMinor,
    required this.baseCurrency,
    required this.splitMode,
    required Map<String, int> sharesOriginalMinor,
    required Map<String, int> sharesBaseMinor,
    required this.createdAt,
    this.note,
  })  : sharesOriginalMinor = Map.unmodifiable(sharesOriginalMinor),
        sharesBaseMinor = Map.unmodifiable(sharesBaseMinor) {
    if (id.isEmpty || groupId.isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Expense id, group, and title are required.');
    }
    if (paidByMemberId.isEmpty) {
      throw ArgumentError('Expense needs a payer.');
    }
    if (amountMinor <= 0 || baseAmountMinor <= 0) {
      throw ArgumentError('Expense amounts must be greater than zero.');
    }
    _requireSum(sharesOriginalMinor, amountMinor, 'original');
    _requireSum(sharesBaseMinor, baseAmountMinor, 'base');
  }

  final String id;
  final String groupId;
  final String title;
  final String paidByMemberId;
  final int amountMinor;
  final String currencyCode;
  final int baseAmountMinor;
  final String baseCurrency;
  final SplitMode splitMode;
  final Map<String, int> sharesOriginalMinor;
  final Map<String, int> sharesBaseMinor;
  final DateTime createdAt;
  final String? note;

  static void _requireSum(Map<String, int> shares, int total, String label) {
    if (shares.isEmpty) {
      throw ArgumentError('Expense needs at least one $label share.');
    }
    final sum = shares.values.fold<int>(0, (running, share) => running + share);
    if (sum != total) {
      throw ArgumentError(
        '$label shares ($sum) must add up to the expense total ($total).',
      );
    }
  }
}
