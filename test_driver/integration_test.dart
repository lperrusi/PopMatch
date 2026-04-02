import 'package:integration_test/integration_test_driver.dart';

/// Driver for integration tests when running on a device/emulator.
/// Run: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
Future<void> main() => integrationDriver();
