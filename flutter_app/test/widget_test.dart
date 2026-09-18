import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawasul/app/app.dart';

void main() {
  testWidgets('Tawasul app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TawasulApp()));
    expect(find.byType(TawasulApp), findsOneWidget);
  });
}
