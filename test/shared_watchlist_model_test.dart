import 'package:flutter_test/flutter_test.dart';
import 'package:popmatch/models/shared_watchlist.dart';

void main() {
  group('SharedWatchlist', () {
    test('round-trips through JSON', () {
      final original = SharedWatchlist(
        id: 'abc',
        ownerUid: 'owner1',
        ownerName: 'Alice',
        recipientUid: 'me',
        name: 'Date Night',
        description: 'Cozy picks',
        color: '#FF0000',
        movieIds: const ['603', '604'],
        showIds: const ['1399'],
        createdAt: DateTime.parse('2026-06-01T10:00:00.000Z'),
      );

      final restored =
          SharedWatchlist.fromJson(original.toJson(), id: original.id);

      expect(restored.id, 'abc');
      expect(restored.ownerUid, 'owner1');
      expect(restored.ownerName, 'Alice');
      expect(restored.recipientUid, 'me');
      expect(restored.name, 'Date Night');
      expect(restored.description, 'Cozy picks');
      expect(restored.movieIds, ['603', '604']);
      expect(restored.showIds, ['1399']);
      expect(restored.itemCount, 3);
      expect(restored.createdAt, original.createdAt);
    });

    test('tolerates missing/odd fields', () {
      final s = SharedWatchlist.fromJson(<String, dynamic>{
        'ownerUid': 'o',
        'recipientUid': 'r',
        'name': 'List',
        // no movieIds/showIds, blank ownerName, bad createdAt
        'ownerName': '   ',
        'createdAt': 'not-a-date',
      }, id: 'x');

      expect(s.id, 'x');
      expect(s.ownerName, isNull); // blank → null
      expect(s.movieIds, isEmpty);
      expect(s.showIds, isEmpty);
      expect(s.itemCount, 0);
      // Bad date falls back to epoch (never throws).
      expect(s.createdAt.millisecondsSinceEpoch, 0);
    });

    test('coerces numeric ids to strings', () {
      final s = SharedWatchlist.fromJson(<String, dynamic>{
        'ownerUid': 'o',
        'recipientUid': 'r',
        'name': 'List',
        'movieIds': [603, 604],
        'showIds': [1399],
      });
      expect(s.movieIds, ['603', '604']);
      expect(s.showIds, ['1399']);
    });
  });
}
