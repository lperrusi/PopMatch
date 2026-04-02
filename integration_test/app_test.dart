import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/main.dart';

/// Full app integration test (requires a connected device – iOS/Android).
/// Run: flutter test integration_test/app_test.dart -d <deviceId>
/// Get deviceId from: flutter devices
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PopMatch full app', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({'tutorial_completed': false});
    });

    testWidgets('App launches and shows splash (PopMatch, Loading)',
        (WidgetTester tester) async {
      runApp(const PopMatchApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PopMatch'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('App remains stable through initial boot frames',
        (WidgetTester tester) async {
      runApp(const PopMatchApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
