import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ajo_panel.dart';
import '../widgets/balances_panel.dart';
import '../widgets/expenses_panel.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(appControllerProvider).groupById(groupId);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This group is no longer available.')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.name),
              Text(
                '${group.members.length} members · base ${group.baseCurrency}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
              Tab(text: 'Ajo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ExpensesPanel(groupId: groupId),
            BalancesPanel(groupId: groupId),
            AjoPanel(groupId: groupId),
          ],
        ),
      ),
    );
  }
}
