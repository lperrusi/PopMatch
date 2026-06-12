import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/detail/detail_header_hero.dart';

void main() {
  Widget wrap(Widget sliver) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: CustomScrollView(slivers: [sliver]),
      ),
    );
  }

  testWidgets('renders title, slot children, and the back button', (tester) async {
    var popped = false;
    await tester.pumpWidget(wrap(
      DetailHeaderHero(
        imageUrl: null, // null → fallback icon, no network
        title: 'The Matrix',
        textColor: AppTheme.creamyWhite,
        overlayColor: AppTheme.filmStripBlack,
        onBack: () => popped = true,
        children: const [Text('META ROW'), Text('WHY LINE')],
      ),
    ));
    await tester.pump();

    expect(find.text('The Matrix'), findsOneWidget);
    expect(find.text('META ROW'), findsOneWidget);
    expect(find.text('WHY LINE'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Back button is wired to onBack.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(popped, isTrue);
  });

  testWidgets('renders a bottom (TabBar slot) when provided', (tester) async {
    await tester.pumpWidget(wrap(
      DetailHeaderHero(
        imageUrl: null,
        title: 'Breaking Bad',
        textColor: AppTheme.creamyWhite,
        overlayColor: AppTheme.filmStripBlack,
        fallbackIcon: Icons.tv_outlined,
        onBack: () {},
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Text('TABS SLOT'),
        ),
        children: const [Text('Year 2008')],
      ),
    ));
    await tester.pump();

    expect(find.text('TABS SLOT'), findsOneWidget);
    expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
