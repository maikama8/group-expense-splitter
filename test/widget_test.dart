import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_splitter/app.dart';

void main() {
  testWidgets('seeded groups open into expenses, settle-up, and Ajo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: GroupExpenseApp()));
    expect(find.text('December in Lagos'), findsOneWidget);
    expect(find.text('London client trip'), findsOneWidget);

    await tester.tap(find.text('December in Lagos'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dinner at Terra Kulture'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('expenses-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Dinner at Terra Kulture'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Balances'));
    await tester.pumpAndSettle();
    expect(find.text('Settle up'), findsOneWidget);
    expect(find.text('Fatima Bello pays Chinedu Eze'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Ajo'));
    await tester.pumpAndSettle();
    expect(find.text('Family Esusu'), findsOneWidget);
    expect(find.text('Fatima Bello collects'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('London client trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Ajo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No Ajo circle yet'), findsOneWidget);
  });

  testWidgets('a new equal expense shows up on the group', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: GroupExpenseApp()));
    await tester.tap(find.text('December in Lagos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-expense')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Suya night');
    await tester.enterText(find.byType(TextField).at(1), '4000');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Suya night'), findsOneWidget);
    expect(find.text('Expense added'), findsOneWidget);
  });
}
