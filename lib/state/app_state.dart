import '../features/ajo/models/ajo_models.dart';
import '../features/expenses/models/expense.dart';
import '../features/expenses/models/settlement.dart';
import '../features/groups/models/expense_group.dart';

class AppState {
  const AppState({
    required this.groups,
    required this.expenses,
    required this.settlements,
    required this.ajoCircles,
  });

  final List<ExpenseGroup> groups;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final List<AjoCircle> ajoCircles;

  ExpenseGroup? groupById(String id) {
    for (final group in groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  AjoCircle? ajoForGroup(String groupId) {
    for (final circle in ajoCircles) {
      if (circle.groupId == groupId) return circle;
    }
    return null;
  }
}
