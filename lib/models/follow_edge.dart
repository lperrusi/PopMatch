enum FollowStatus { pending, accepted, declined, blocked }

class FollowEdge {
  final String followerUid;
  final String followeeUid;
  final FollowStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FollowEdge({
    required this.followerUid,
    required this.followeeUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FollowEdge.fromJson(Map<String, dynamic> json) {
    return FollowEdge(
      followerUid: json['followerUid'] as String? ?? '',
      followeeUid: json['followeeUid'] as String? ?? '',
      status: _statusFromString(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followerUid': followerUid,
      'followeeUid': followeeUid,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static FollowStatus _statusFromString(String? value) {
    switch (value) {
      case 'accepted':
        return FollowStatus.accepted;
      case 'declined':
        return FollowStatus.declined;
      case 'blocked':
        return FollowStatus.blocked;
      case 'pending':
      default:
        return FollowStatus.pending;
    }
  }
}
