import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

/// Driver for integration tests when running on a device/emulator.
///
/// Run screenshot capture:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshot_test.dart \
///     -d <device-id>
///
/// Run other integration tests:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_test.dart \
///     -d <device-id>
Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data == null) return;
        final dynamic rawScreenshots = data['screenshots'];
        if (rawScreenshots is! List) return;

        final dir = Directory('screenshots/app-screens');
        if (!dir.existsSync()) dir.createSync(recursive: true);

        for (final dynamic entry in rawScreenshots) {
          if (entry is! Map) continue;
          final String name = entry['screenshotName'] as String;
          final List<int> bytes =
              (entry['bytes'] as List<dynamic>).cast<int>();
          final file = File('screenshots/app-screens/$name.png');
          await file.writeAsBytes(bytes);
          stdout.writeln('Saved: ${file.path}');
        }
      },
    );
