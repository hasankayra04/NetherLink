class UserModel {
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? createdAt;
  final String? lastSeenAt;

  const UserModel({
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.lastSeenAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        createdAt: json['createdAt'] as String?,
        lastSeenAt: json['lastSeenAt'] as String?,
      );

  String get displayLabel =>
      displayName?.isNotEmpty == true ? displayName! : username;

  String get initials {
    final label = displayLabel;
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return label.substring(0, label.length.clamp(0, 2)).toUpperCase();
  }
}

class FriendSession {
  final String serverIp;
  final int serverPort;
  final String? startedAt;

  const FriendSession({
    required this.serverIp,
    required this.serverPort,
    this.startedAt,
  });

  factory FriendSession.fromJson(Map<String, dynamic> json) => FriendSession(
        serverIp: json['serverIp'] as String,
        serverPort: json['serverPort'] as int,
        startedAt: json['startedAt'] as String?,
      );
}

class FriendModel {
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool online;
  final FriendSession? session;
  final String? lastSeenAt;

  const FriendModel({
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.online,
    this.session,
    this.lastSeenAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        online: json['online'] as bool? ?? false,
        session: json['session'] != null
            ? FriendSession.fromJson(json['session'] as Map<String, dynamic>)
            : null,
        lastSeenAt: json['lastSeenAt'] as String?,
      );

  String get displayLabel =>
      displayName?.isNotEmpty == true ? displayName! : username;

  String get initials {
    final label = displayLabel;
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return label.substring(0, label.length.clamp(0, 2)).toUpperCase();
  }
}

class FriendRequest {
  final int id;
  final String requesterUsername;
  final String? requesterDisplayName;
  final String? requesterAvatarUrl;
  final String? createdAt;

  const FriendRequest({
    required this.id,
    required this.requesterUsername,
    this.requesterDisplayName,
    this.requesterAvatarUrl,
    this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'] as Map<String, dynamic>;
    return FriendRequest(
      id: json['id'] as int,
      requesterUsername: requester['username'] as String,
      requesterDisplayName: requester['displayName'] as String?,
      requesterAvatarUrl: requester['avatarUrl'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  String get displayLabel => requesterDisplayName?.isNotEmpty == true
      ? requesterDisplayName!
      : requesterUsername;

  String get initials {
    final label = displayLabel;
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return label.substring(0, label.length.clamp(0, 2)).toUpperCase();
  }
}