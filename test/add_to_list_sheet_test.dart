import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:popmatch/l10n/app_localizations.dart';
import 'package:popmatch/services/watchlist_service.dart';
import 'package:popmatch/widgets/add_to_list_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('creating a list and tagging persists via WatchlistService',
      (tester) async {
    await tester.pumpWidget(
      wrap(const AddToListSheet(movieId: '603', title: 'The Matrix')),
    );
    await tester.pumpAndSettle();

    // Title renders + the default list is shown as a checkbox option.
    expect(find.text('Add to List'), findsOneWidget);
    expect(find.text('All Movies'), findsOneWidget);

    // Create a list → it should contain the movie.
    await tester.enterText(find.byType(TextField).first, 'Weekend');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final lists = await WatchlistService.instance.getLists();
    expect(lists.any((l) => l.name == 'Weekend'), isTrue);
    final containing =
        await WatchlistService.instance.getListsContainingMovie('603');
    expect(containing.any((l) => l.name == 'Weekend'), isTrue);

    // Add a tag.
    await tester.enterText(find.byType(TextField).last, 'rewatch');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final tags = await WatchlistService.instance.getMovieTags();
    expect(tags['603'], contains('rewatch'));
    expect(tester.takeException(), isNull);
  });
}
