#!/usr/bin/env bash
# Run VM tests, then optionally integration tests on a single device.
# Usage:
#   ./scripts/ci_test.sh
#   INTEGRATION_DEVICE=<id from `flutter devices`> ./scripts/ci_test.sh
#
# Flutter does not allow mixing integration_test and test/ in one invocation.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Unit and widget tests (test/) =="
flutter test test/

echo ""
if [[ -z "${INTEGRATION_DEVICE:-}" ]]; then
  echo "INTEGRATION_DEVICE not set; skipping integration_test."
  echo "To run: INTEGRATION_DEVICE=<deviceId> ./scripts/ci_test.sh"
  exit 0
fi

echo "== Integration tests on device: ${INTEGRATION_DEVICE} =="
flutter test integration_test/app_test.dart -d "${INTEGRATION_DEVICE}"
flutter test integration_test/swipe_deck_test.dart -d "${INTEGRATION_DEVICE}"
flutter test integration_test/swipe_like_integration_test.dart -d "${INTEGRATION_DEVICE}"
