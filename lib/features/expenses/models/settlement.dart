/// A recorded payment from one member to another, in the group base currency.
class Settlement {
  Settlement({
    required this.id,
    required this.groupId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountMinor,
    required this.currencyCode,
    required this.createdAt,
  }) {
    if (fromMemberId.isEmpty || toMemberId.isEmpty) {
      throw ArgumentError('Settlement needs both people.');
    }
    if (fromMemberId == toMemberId) {
      throw ArgumentError('A person cannot settle with themselves.');
    }
    if (amountMinor <= 0) {
      throw ArgumentError('Settlement amount must be greater than zero.');
    }
  }

  final String id;
  final String groupId;
  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
  final String currencyCode;
  final DateTime createdAt;
}

/// A suggested payment from the settle-up planner. Not persisted until recorded.
class Transfer {
  const Transfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountMinor,
    required this.currencyCode,
  });

  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
  final String currencyCode;
}
