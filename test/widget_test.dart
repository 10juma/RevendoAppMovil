// Smoke test: sin sesión guardada, la app debe arrancar en Login.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:revendo/main.dart';

void main() {
  testWidgets('Arranca en Login cuando no hay sesión guardada', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RevendoApp());
    await tester.pumpAndSettle();

    expect(find.text('Revendo'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
  });
}
