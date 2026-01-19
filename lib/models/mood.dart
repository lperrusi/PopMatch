/// Mood model for mood-based movie recommendations
class Mood {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<int> preferredGenres;
  final List<String> keywords;

  const Mood({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.preferredGenres,
    required this.keywords,
  });

  /// Available moods for movie recommendations
  static const List<Mood> availableMoods = [
    Mood(
      id: 'happy',
      name: 'Happy',
      emoji: '😊',
      description: 'Feeling joyful and upbeat',
      preferredGenres: [35, 10751, 16, 12], // Comedy, Family, Animation, Adventure
      keywords: ['funny', 'uplifting', 'feel-good', 'cheerful'],
    ),
    Mood(
      id: 'sad',
      name: 'Sad',
      emoji: '😢',
      description: 'Need something to lift your spirits',
      preferredGenres: [35, 10751, 16, 14], // Comedy, Family, Animation, Fantasy
      keywords: ['heartwarming', 'inspiring', 'uplifting', 'emotional'],
    ),
    Mood(
      id: 'excited',
      name: 'Excited',
      emoji: '🤩',
      description: 'Ready for action and adventure',
      preferredGenres: [28, 12, 878, 53], // Action, Adventure, Sci-Fi, Thriller
      keywords: ['thrilling', 'action-packed', 'adventure', 'exciting'],
    ),
    Mood(
      id: 'romantic',
      name: 'Romantic',
      emoji: '💕',
      description: 'In the mood for love stories',
      preferredGenres: [10749, 35, 18, 14], // Romance, Comedy, Drama, Fantasy
      keywords: ['romantic', 'love', 'sweet', 'charming'],
    ),
    Mood(
      id: 'relaxed',
      name: 'Relaxed',
      emoji: '😌',
      description: 'Want something calm and peaceful',
      preferredGenres: [18, 14, 36, 10402], // Drama, Fantasy, History, Music
      keywords: ['calm', 'peaceful', 'thoughtful', 'beautiful'],
    ),
    Mood(
      id: 'mysterious',
      name: 'Mysterious',
      emoji: '🕵️',
      description: 'Craving suspense and intrigue',
      preferredGenres: [9648, 53, 80, 27], // Mystery, Thriller, Crime, Horror
      keywords: ['mysterious', 'suspenseful', 'thrilling', 'dark'],
    ),
    Mood(
      id: 'nostalgic',
      name: 'Nostalgic',
      emoji: '🕰️',
      description: 'Feeling nostalgic for the past',
      preferredGenres: [36, 18, 10402, 10752], // History, Drama, Music, War
      keywords: ['classic', 'nostalgic', 'retro', 'timeless'],
    ),
    Mood(
      id: 'inspired',
      name: 'Inspired',
      emoji: '💡',
      description: 'Looking for motivation and inspiration',
      preferredGenres: [18, 36, 99, 10402], // Drama, History, Documentary, Music
      keywords: ['inspiring', 'motivational', 'educational', 'thought-provoking'],
    ),
  ];

  /// Gets mood by ID
  static Mood? getById(String id) {
    try {
      return availableMoods.firstWhere((mood) => mood.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Gets random mood
  static Mood getRandom() {
    return availableMoods[DateTime.now().millisecondsSinceEpoch % availableMoods.length];
  }

  @override
  String toString() {
    return 'Mood(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mood && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 