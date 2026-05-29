---
name: run-tests
description: Use when the user asks to run tests, check test results, or wants to know how to execute unit, widget, or integration tests. Trigger phrases: "run tests", "run the test suite", "run a single test", "integration tests".
argument-hint: "[unit|integration|all|<test-file-path>]"
allowed-tools: [Bash]
---

## Unit + widget tests (no device needed)
```bash
flutter test test/
```

## Single test file
```bash
flutter test test/some_test.dart
```

## Full suite including integration (device required)
```bash
INTEGRATION_DEVICE=<id from `flutter devices`> ./scripts/ci_test.sh
```

## Single integration test on a device
```bash
flutter test integration_test/swipe_deck_test.dart -d <deviceId>
```
