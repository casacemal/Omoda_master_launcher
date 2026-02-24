
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:chery_master_launcher/main.dart';

void main() {
  // Initialize date formatting for the Turkish locale
  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  testWidgets('Renders MainDashboard smoke test on a larger screen', (WidgetTester tester) async {
    // Set a more realistic, landscape screen size for the test
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const OmodaMasterLauncher());
    
    // Use pump instead of pumpAndSettle to avoid timeouts from animations
    // or long-running async tasks like fetching apps.
    await tester.pump();

    // Verify that the main dashboard is rendered.
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget);

    // Pump the clock forward to ensure the time string is updated.
    await tester.pump(const Duration(seconds: 1));

    // Verify that the time is displayed.
    expect(find.textContaining(':'), findsWidgets);

    // Clean up the screen size override after the test
    addTearDown(tester.view.resetPhysicalSize); 
  });
}
