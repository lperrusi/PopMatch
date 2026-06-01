import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popmatch/widgets/detail/watchlist_icon.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('WatchlistIcon', () {
    testWidgets('renders the not-added (bookmark + plus) state', (tester) async {
      await tester.pumpWidget(wrap(
        const WatchlistIcon(size: 28, added: false, inactiveColor: Colors.white),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the added (filled bookmark + star) state',
        (tester) async {
      await tester.pumpWidget(wrap(
        const WatchlistIcon(size: 28, added: true, inactiveColor: Colors.white),
      ));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
