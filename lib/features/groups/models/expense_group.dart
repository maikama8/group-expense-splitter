import 'member.dart';

class ExpenseGroup {
  ExpenseGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.baseCurrency,
    required this.members,
    required this.createdAt,
  }) {
    if (id.isEmpty || name.isEmpty) {
      throw ArgumentError('Group id and name are required.');
    }
    if (members.isEmpty) {
      throw ArgumentError('A group needs at least one member.');
    }
    final ids = members.map((member) => member.id).toSet();
    if (ids.length != members.length) {
      throw ArgumentError('Member ids must be unique.');
    }
  }

  final String id;
  final String name;
  final String description;
  final String baseCurrency;
  final List<Member> members;
  final DateTime createdAt;

  Member? findMember(String memberId) {
    for (final member in members) {
      if (member.id == memberId) return member;
    }
    return null;
  }

  String memberName(String memberId) => findMember(memberId)?.name ?? 'Unknown';
}
