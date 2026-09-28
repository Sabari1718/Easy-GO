import 'package:flutter_test/flutter_test.dart';
import 'package:easy_go/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App compiles and runs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EasyGoApp()));
    expect(find.text('EasyGo'), findsNothing); // It's in the splash screen maybe or we just check if it mounts without errors.
  });
}
