/// Streaming platform model
class StreamingPlatform {
  final String id;
  final String name;
  final String logoPath;
  final String? websiteUrl;
  final String? subscriptionInfo;
  final bool isAvailable;

  const StreamingPlatform({
    required this.id,
    required this.name,
    required this.logoPath,
    this.websiteUrl,
    this.subscriptionInfo,
    this.isAvailable = true,
  });

  /// Available streaming platforms
  static const List<StreamingPlatform> availablePlatforms = [
    StreamingPlatform(
      id: 'netflix',
      name: 'Netflix',
      logoPath: 'assets/images/netflix_logo.png',
      websiteUrl: 'https://www.netflix.com',
      subscriptionInfo: 'Subscription required',
    ),
    StreamingPlatform(
      id: 'disney_plus',
      name: 'Disney+',
      logoPath: 'assets/images/disney_plus_logo.png',
      websiteUrl: 'https://www.disneyplus.com',
      subscriptionInfo: 'Subscription required',
    ),
    StreamingPlatform(
      id: 'amazon_prime',
      name: 'Amazon Prime',
      logoPath: 'assets/images/amazon_prime_logo.png',
      websiteUrl: 'https://www.amazon.com/prime',
      subscriptionInfo: 'Prime membership required',
    ),
    StreamingPlatform(
      id: 'hulu',
      name: 'Hulu',
      logoPath: 'assets/images/hulu_logo.png',
      websiteUrl: 'https://www.hulu.com',
      subscriptionInfo: 'Subscription required',
    ),
    StreamingPlatform(
      id: 'hbo_max',
      name: 'HBO Max',
      logoPath: 'assets/images/hbo_max_logo.png',
      websiteUrl: 'https://www.hbomax.com',
      subscriptionInfo: 'Subscription required',
    ),
    StreamingPlatform(
      id: 'apple_tv',
      name: 'Apple TV+',
      logoPath: 'assets/images/apple_tv_logo.png',
      websiteUrl: 'https://tv.apple.com',
      subscriptionInfo: 'Subscription required',
    ),
    StreamingPlatform(
      id: 'paramount_plus',
      name: 'Paramount+',
      logoPath: 'assets/images/paramount_plus_logo.png',
      websiteUrl: 'https://www.paramountplus.com',
      subscriptionInfo: 'Subscription required',
    ),
    StreamingPlatform(
      id: 'peacock',
      name: 'Peacock',
      logoPath: 'assets/images/peacock_logo.png',
      websiteUrl: 'https://www.peacocktv.com',
      subscriptionInfo: 'Free with ads, Premium subscription available',
    ),
    StreamingPlatform(
      id: 'youtube_tv',
      name: 'YouTube TV',
      logoPath: 'assets/images/youtube_tv_logo.png',
      websiteUrl: 'https://tv.youtube.com',
      subscriptionInfo: 'Subscription required',
    ),
    StreamingPlatform(
      id: 'tubi',
      name: 'Tubi',
      logoPath: 'assets/images/tubi_logo.png',
      websiteUrl: 'https://www.tubi.tv',
      subscriptionInfo: 'Free with ads',
    ),
    StreamingPlatform(
      id: 'pluto_tv',
      name: 'Pluto TV',
      logoPath: 'assets/images/pluto_tv_logo.png',
      websiteUrl: 'https://pluto.tv',
      subscriptionInfo: 'Free with ads',
    ),
  ];

  /// Gets platform by ID
  static StreamingPlatform? getById(String id) {
    try {
      return availablePlatforms.firstWhere((platform) => platform.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Gets all available platforms
  static List<StreamingPlatform> getAvailablePlatforms() {
    return availablePlatforms.where((platform) => platform.isAvailable).toList();
  }

  @override
  String toString() {
    return 'StreamingPlatform(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamingPlatform && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Movie streaming availability model
class MovieStreamingAvailability {
  final int movieId;
  final List<String> availablePlatforms;
  final String? streamingUrl;
  final String? rentalPrice;
  final String? purchasePrice;
  final bool isFree;
  final DateTime? lastUpdated;

  const MovieStreamingAvailability({
    required this.movieId,
    required this.availablePlatforms,
    this.streamingUrl,
    this.rentalPrice,
    this.purchasePrice,
    this.isFree = false,
    this.lastUpdated,
  });

  /// Creates MovieStreamingAvailability from JSON
  factory MovieStreamingAvailability.fromJson(Map<String, dynamic> json) {
    return MovieStreamingAvailability(
      movieId: json['movieId'] ?? 0,
      availablePlatforms: json['availablePlatforms'] != null 
          ? List<String>.from(json['availablePlatforms'])
          : [],
      streamingUrl: json['streamingUrl'],
      rentalPrice: json['rentalPrice'],
      purchasePrice: json['purchasePrice'],
      isFree: json['isFree'] ?? false,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'availablePlatforms': availablePlatforms,
      'streamingUrl': streamingUrl,
      'rentalPrice': rentalPrice,
      'purchasePrice': purchasePrice,
      'isFree': isFree,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Gets the platforms as StreamingPlatform objects
  List<StreamingPlatform> get platforms {
    return availablePlatforms
        .map((id) => StreamingPlatform.getById(id))
        .whereType<StreamingPlatform>()
        .toList();
  }

  /// Checks if movie is available on a specific platform
  bool isAvailableOn(String platformId) {
    return availablePlatforms.contains(platformId);
  }

  /// Gets the cheapest option (free, rental, or purchase)
  String? get cheapestOption {
    if (isFree) return 'Free';
    if (rentalPrice != null) return 'Rent: $rentalPrice';
    if (purchasePrice != null) return 'Buy: $purchasePrice';
    return null;
  }
} 