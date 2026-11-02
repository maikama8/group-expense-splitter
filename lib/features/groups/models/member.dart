class Member {
  const Member({required this.id, required this.name});

  final String id;
  final String name;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    String letter(String word) => word[0].toUpperCase();
    if (parts.length == 1) return letter(parts.first);
    return '${letter(parts.first)}${letter(parts.last)}';
  }
}
