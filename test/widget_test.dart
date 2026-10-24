import 'package:flutter_test/flutter_test.dart';
import 'package:gomaa_management/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final app = MyApp();
    expect(app, isNotNull);
  });
}
