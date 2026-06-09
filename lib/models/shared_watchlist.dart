/// A point-in-time copy of a custom watchlist that one user shared with another.
/// Written server-side by the `shareWatchlist` Cloud Function and read by the
/// recipient (and owner) via Firestore security rules. No live sync.
class SharedWatchlist {
  final String id;
  final String ownerUid;
  final String? ownerName;
  final String recipientUid;
  final String name;
  final String? description;
  final String? color;
  final List<String> movieIds;
  final List<String> showIds;
  final DateTime createdAt;

  const SharedWatchlist({
    required this.id,
    required this.ownerUid,
    this.ownerName,
    required this.recipientUid,
    required this.name,
    this.description,
    this.color,
    required this.movieIds,
    required this.showIds,
    required this.createdAt,
  });

  int get itemCount => movieIds.length + showIds.length;

  factory SharedWatchlist.fromJson(Map<String, dynamic> json, {String? id}) {
    List<String> ids(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];
    return SharedWatchlist(
      id: id ?? json['id']?.toString() ?? '',
      ownerUid: json['ownerUid']?.toString() ?? '',
      ownerName: (json['ownerName'] as String?)?.trim().isNotEmpty == true
          ? (json['ownerName'] as String).trim()
          : null,
      recipientUid: json['recipientUid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      color: json['color'] as String?,
      movieIds: ids(json['movieIds']),
      showIds: ids(json['showIds']),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'recipientUid': recipientUid,
      'name': name,
      'description': description,
      'color': color,
      'movieIds': movieIds,
      'showIds': showIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
