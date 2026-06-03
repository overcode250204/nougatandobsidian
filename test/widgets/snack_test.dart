import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/widgets/snack.dart';

void main() {
  testWidgets('snack shows snackbar with text', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => snack(context, 'Test Message'),
              child: const Text('Show Snack'),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('Show Snack'));
    await tester.pump(); // Start animation

    expect(find.text('Test Message'), findsOneWidget);
  });
}
