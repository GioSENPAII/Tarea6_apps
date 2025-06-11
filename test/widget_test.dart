import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ar_flutter_app/main.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the home screen loads
    expect(find.text('AR Flutter App'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);

    // Wait for permission simulation
    await tester.pump(Duration(seconds: 2));

    // Verify button becomes enabled
    expect(find.text('Abrir AR'), findsOneWidget);
  });

  testWidgets('Permission info dialog works', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Wait for permission simulation
    await tester.pump(Duration(seconds: 2));

    // Tap on permission info button
    await tester.tap(find.text('Información sobre permisos'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Información de Permisos'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
  });
}