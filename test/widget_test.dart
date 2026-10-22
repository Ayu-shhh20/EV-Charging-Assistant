import 'package:flutter_test/flutter_test.dart';

import 'package:ai_ev_charging_asistant/main.dart';

void main() {
  testWidgets('AI EV Charging Assistant loads', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(
      const EVChargingAssistant(),
    );

    expect(
      find.text('AI EV Charging Assistant'),
      findsOneWidget,
    );

    expect(
      find.text('Home'),
      findsOneWidget,
    );

    expect(
      find.text('Charging'),
      findsOneWidget,
    );

    expect(
      find.text('Map'),
      findsOneWidget,
    );

    expect(
      find.text('Profile'),
      findsOneWidget,
    );
  });
}