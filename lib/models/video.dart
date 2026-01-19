/// Video/Trailer model
class Video {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;
  final String? official;
  final String? publishedAt;
  final int? size;

  Video({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    this.official,
    this.publishedAt,
    this.size,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    // Handle the official field which can be bool or string
    String? officialValue;
    if (json['official'] != null) {
      if (json['official'] is bool) {
        officialValue = json['official'] ? 'true' : 'false';
      } else {
        officialValue = json['official'].toString();
      }
    }
    
    return Video(
      id: json['id']?.toString() ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      type: json['type'] ?? '',
      official: officialValue,
      publishedAt: json['published_at'],
      size: json['size'],
    );
  }

  String? get youtubeUrl {
    if (site.toLowerCase() == 'youtube') {
      return 'https://www.youtube.com/watch?v=$key';
    }
    return null;
  }

  String? get thumbnailUrl {
    if (site.toLowerCase() == 'youtube') {
      return 'https://img.youtube.com/vi/$key/maxresdefault.jpg';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'site': site,
      'type': type,
      'official': official,
      'published_at': publishedAt,
      'size': size,
    };
  }
} 