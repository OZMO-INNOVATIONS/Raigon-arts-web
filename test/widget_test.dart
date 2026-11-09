import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raigon_art/core/widgets/app_primary_button.dart';

void main() {
  testWidgets('App widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'Test Button',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('Test Button'), findsOneWidget);
  });
}
