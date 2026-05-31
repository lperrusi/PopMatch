import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:popmatch/models/mood.dart';
import 'package:popmatch/providers/movie_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('Discover filters persist across MovieProvider instances', () async {
    final mood = Mood.availableMoods.first;

    final p1 = MovieProvider();
    p1.setSwipeGenres([28, 35]);
    p1.setSwipePlatforms(['netflix', 'hulu']);
    p1.setSwipeMoods([mood]);
    await p1.persistSwipeFiltersForTest();

    final p2 = MovieProvider();
    await p2.loadPersistedSwipeFilters();

    expect(p2.swipeSelectedGenres, [28, 35]);
    expect(p2.swipeSelectedPlatforms, ['netflix', 'hulu']);
    expect(p2.swipeMoods.map((m) => m.id).toList(), [mood.id]);
  });

  test('no persisted filters → fresh provider has none', () async {
    final p = MovieProvider();
    await p.loadPersistedSwipeFilters();
    expect(p.swipeSelectedGenres, isEmpty);
    expect(p.swipeSelectedPlatforms, isEmpty);
    expect(p.swipeMoods, isEmpty);
  });
}
