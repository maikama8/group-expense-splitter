import 'package:flutter/material.dart';

import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

class GroupExpenseApp extends StatelessWidget {
  const GroupExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Group Expense Splitter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
