// test/app/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:custodiam/app/app.dart';

void main() {
  testWidgets('App se renderiza correctamente', (tester) async {
    await tester.pumpWidget(const CustodiamApp());
    await tester.pumpAndSettle();

    expect(find.text('Custodiam'), findsWidgets);
  });
}
