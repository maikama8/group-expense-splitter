import 'package:flutter/material.dart';

void main() {
  runApp(const GroupExpenseApp());
}

class GroupExpenseApp extends StatelessWidget {
  const GroupExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Group Expense Splitter',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Expenses')),
      body: const Center(
        child: Text('Group Expense Splitter Scaffold\nReady for Flutter development'),
      ),
    );
  }
}
