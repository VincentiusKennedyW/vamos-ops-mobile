class AuthUser {
  const AuthUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.roleName,
    required this.roleCode,
    required this.venueName,
    required this.permissions,
    required this.expiresAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    userId: json['userId']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    roleName: json['roleName']?.toString() ?? '',
    roleCode: json['roleCode']?.toString() ?? '',
    venueName: json['venueName']?.toString() ?? '',
    permissions: (json['permissions'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    expiresAt:
        DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final String userId;
  final String fullName;
  final String email;
  final String roleName;
  final String roleCode;
  final String venueName;
  final List<String> permissions;
  final DateTime expiresAt;
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}
