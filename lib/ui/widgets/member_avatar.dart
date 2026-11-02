import 'package:flutter/material.dart';

import '../../features/groups/models/member.dart';
import '../theme/app_theme.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({required this.member, this.radius = 18, super.key});

  final Member member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _colorFor(member.id),
      foregroundColor: Colors.white,
      child: Text(
        member.initials,
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Color _colorFor(String id) {
    const colors = [
      AppColors.forest,
      Color(0xFF1F6F8B),
      Color(0xFF8C4A2F),
      Color(0xFF3E4C8A),
      Color(0xFF6B3F69),
    ];
    final hash = id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return colors[hash % colors.length];
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({required this.members, super.key});

  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(4).toList();
    return SizedBox(
      height: 32,
      width: 32.0 + (shown.length - 1) * 22,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 22,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
                child: MemberAvatar(member: shown[i], radius: 14),
              ),
            ),
        ],
      ),
    );
  }
}
