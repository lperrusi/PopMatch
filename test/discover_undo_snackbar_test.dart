import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/l10n/app_localizations.dart';

import 'package:popmatch/utils/theme.dart';
import 'package:popmatch/widgets/discover_undo_snackbar.dart';

void main() {
  group('DiscoverSwipeFeedback', () {
    Widget buildWidget({
      required bool visible,
      CardSwiperDirection? direction,
      VoidCallback? onUndo,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.retroCinemaTheme,
        home: Scaffold(
          body: Center(
            child: DiscoverSwipeFeedback(
              visible: visible,
              direction: direction,
              onUndo: onUndo ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('shows UNDO text when visible', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(
        visible: true,
        direction: CardSwiperDirection.right,
      ));
      await tester.pumpAndSettle();

      expect(find.text('UNDO'), findsOneWidget);
      expect(find.text('Liked'), findsOneWidget);
    });

    testWidgets('shows Passed label for left swipe', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(
        visible: true,
        direction: CardSwiperDirection.left,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Passed'), findsOneWidget);
    });

    testWidgets('shows Watchlisted label for top swipe',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(
        visible: true,
        direction: CardSwiperDirection.top,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Watchlisted'), findsOneWidget);
    });

    testWidgets('UNDO tap fires onUndo callback', (WidgetTester tester) async {
      var called = false;
      await tester.pumpWidget(buildWidget(
        visible: true,
        direction: CardSwiperDirection.right,
        onUndo: () => called = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('UNDO'));
      expect(called, isTrue);
    });

    testWidgets('is invisible (ignores pointer) when visible=false',
        (WidgetTester tester) async {
      var called = false;
      await tester.pumpWidget(buildWidget(
        visible: false,
        direction: CardSwiperDirection.right,
        onUndo: () => called = true,
      ));
      await tester.pumpAndSettle();

      // Opacity 0 — widget still in tree but IgnorePointer blocks taps
      await tester.tap(find.text('UNDO'), warnIfMissed: false);
      expect(called, isFalse);
    });
  });
}
