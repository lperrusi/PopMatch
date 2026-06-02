import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:popmatch/widgets/poster_list_skeleton.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  group('PosterListSkeleton', () {
    testWidgets('renders a shimmer over a list with the default row/line count',
        (tester) async {
      await tester.pumpWidget(wrap(const PosterListSkeleton()));
      // One synchronized shimmer sweep over a non-scrollable list. (The list is
      // lazy, so only the rows in the viewport are built — assert presence, and
      // the exact bar math is covered by the custom-count case below.)
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsWidgets);
    });

    testWidgets('honors custom itemCount and lineCount', (tester) async {
      await tester.pumpWidget(
        wrap(const PosterListSkeleton(itemCount: 3, lineCount: 2)),
      );
      expect(find.byType(FractionallySizedBox), findsNWidgets(6));
    });
  });

  group('PosterListTileSkeleton', () {
    testWidgets('renders a shimmer card with the default two text bars',
        (tester) async {
      await tester.pumpWidget(wrap(const PosterListTileSkeleton()));
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsNWidgets(2));
    });
  });
}
