import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kametibook/app/app.dart';

void main() {
  testWidgets('KametiBook app launches to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KametiBookApp()));

    expect(find.text('KametiBook'), findsOneWidget);
    expect(find.text('Har kameti ka complete hisaab.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Manage Your Kameti Easily'), findsOneWidget);
  });
}
